extends Node
## SceneLoader - Hub central de chargement et transition de scènes
## Gère le chargement asynchrone, les transitions et l'auto-connexion des signaux

class_name SceneLoader

# Signaux globaux
signal scene_loading_started(scene_path: String)
signal scene_loading_progress(progress: float)
signal scene_loaded(scene: Node)
signal scene_transition_finished()

# Configuration
@export var fade_duration: float = 0.3
@export var enable_auto_signal_connection: bool = true
@export var debug_mode: bool = true

# État interne
var current_scene: Node = null
var is_loading: bool = false
var loading_thread: Thread = null
var loading_progress: float = 0.0

# Overlay de transition
var transition_overlay: ColorRect = null

func _ready() -> void:
	_setup_transition_overlay()
	if debug_mode:
		print("[SceneLoader] Initialisé et prêt")

func _setup_transition_overlay() -> void:
	"""Crée un overlay pour les transitions visuelles"""
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color.BLACK
	transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_overlay.z_index = 1000
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.modulate.a = 0.0
	add_child(transition_overlay)

## Charge une scène de manière asynchrone
func load_scene(scene_path: String, transition: bool = true) -> void:
	if is_loading:
		push_warning("[SceneLoader] Chargement déjà en cours")
		return
	
	if not ResourceLoader.exists(scene_path):
		push_error("[SceneLoader] Scène introuvable : " + scene_path)
		return
	
	is_loading = true
	scene_loading_started.emit(scene_path)
	
	if transition:
		await _fade_out()
	
	# Nettoyer l'ancienne scène
	if current_scene != null:
		_disconnect_scene_signals(current_scene)
		current_scene.queue_free()
		await current_scene.tree_exited
		current_scene = null
	
	# Charger la nouvelle scène
	var new_scene = await _load_scene_async(scene_path)
	
	if new_scene == null:
		push_error("[SceneLoader] Échec du chargement : " + scene_path)
		is_loading = false
		return
	
	# Ajouter la scène
	get_tree().root.add_child(new_scene)
	current_scene = new_scene
	
	# Auto-connexion des signaux
	if enable_auto_signal_connection:
		_auto_connect_signals(new_scene)
	
	scene_loaded.emit(new_scene)
	
	if transition:
		await _fade_in()
	
	is_loading = false
	scene_transition_finished.emit()
	
	if debug_mode:
		print("[SceneLoader] Scène chargée : ", scene_path)

## Chargement asynchrone avec barre de progression
func _load_scene_async(scene_path: String) -> Node:
	var status = ResourceLoader.load_threaded_request(scene_path)
	
	if status != OK:
		push_error("[SceneLoader] Erreur lors de la requête de chargement")
		return null
	
	while true:
		var progress_array = []
		status = ResourceLoader.load_threaded_get_status(scene_path, progress_array)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var packed_scene = ResourceLoader.load_threaded_get(scene_path)
			return packed_scene.instantiate()
		
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("[SceneLoader] Échec du chargement threaded")
			return null
		
		elif status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("[SceneLoader] Ressource invalide")
			return null
		
		# Mettre à jour la progression
		if progress_array.size() > 0:
			loading_progress = progress_array[0]
			scene_loading_progress.emit(loading_progress)
		
		await get_tree().process_frame

## Auto-détection et connexion des signaux
func _auto_connect_signals(node: Node) -> void:
	"""Détecte et connecte automatiquement les signaux d'une scène"""
	if not node.has_method("_get_signal_connections"):
		return
	
	var connections = node.call("_get_signal_connections")
	
	if typeof(connections) != TYPE_ARRAY:
		return
	
	for connection in connections:
		if typeof(connection) != TYPE_DICTIONARY:
			continue
		
		if not connection.has_all(["source", "signal_name", "target", "method"]):
			push_warning("[SceneLoader] Connexion invalide : ", connection)
			continue
		
		var source = connection.source
		var signal_name = connection.signal_name
		var target = connection.target
		var method = connection.method
		
		# Vérifier que le signal existe
		if not source.has_signal(signal_name):
			push_warning("[SceneLoader] Signal introuvable : ", signal_name, " sur ", source.name)
			continue
		
		# Vérifier que la méthode existe
		if not target.has_method(method):
			push_warning("[SceneLoader] Méthode introuvable : ", method, " sur ", target.name)
			continue
		
		# Connecter
		if not source.is_connected(signal_name, Callable(target, method)):
			source.connect(signal_name, Callable(target, method))
			
			if debug_mode:
				print("[SceneLoader] Signal connecté : ", source.name, ".", signal_name, " -> ", target.name, ".", method)

## Déconnexion propre des signaux
func _disconnect_scene_signals(node: Node) -> void:
	"""Déconnecte tous les signaux d'une scène avant son retrait"""
	if not node.has_method("_get_signal_connections"):
		return
	
	var connections = node.call("_get_signal_connections")
	
	if typeof(connections) != TYPE_ARRAY:
		return
	
	for connection in connections:
		if typeof(connection) != TYPE_DICTIONARY:
			continue
		
		var source = connection.get("source")
		var signal_name = connection.get("signal_name")
		var target = connection.get("target")
		var method = connection.get("method")
		
		if source and signal_name and target and method:
			if source.is_connected(signal_name, Callable(target, method)):
				source.disconnect(signal_name, Callable(target, method))

## Transitions visuelles
func _fade_out() -> void:
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 1.0, fade_duration)
	await tween.finished

func _fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 0.0, fade_duration)
	await tween.finished
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

## Rechargement de la scène actuelle
func reload_current_scene(transition: bool = true) -> void:
	if current_scene:
		var scene_path = current_scene.scene_file_path
		load_scene(scene_path, transition)

## Nettoyage
func _exit_tree() -> void:
	if loading_thread and loading_thread.is_alive():
		loading_thread.wait_to_finish()
