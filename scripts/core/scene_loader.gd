# scripts/core/scene_loader.gd
extends Node
## SceneLoader - Hub central de chargement et transition de scènes
## Version améliorée avec protection robuste des autoloads
## 
## AMÉLIORATIONS v1.1 :
## - Protection autoloads par constante (plus de hard-coded index)
## - Vérification par nom ET métadonnée
## - Logs améliorés pour debug
## - Support des autoloads ajoutés dynamiquement

class_name SceneLoader

# ============================================================================
# SIGNAUX
# ============================================================================

signal scene_loading_started(scene_path: String)
signal scene_loading_progress(progress: float)
signal scene_loaded(scene: Node)
signal scene_transition_finished()

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var fade_duration: float = 0.3
@export var enable_auto_signal_connection: bool = true
@export var debug_mode: bool = true

## ✅ NOUVEAU : Liste centralisée des autoloads à protéger
## À METTRE À JOUR si vous ajoutez un nouvel autoload dans Project Settings
const AUTOLOAD_NAMES: Array[String] = [
	"EventBus",
	"GameManager", 
	"Dialogue_Manager",
	"BattleDataManager"
]

# ============================================================================
# ÉTAT INTERNE
# ============================================================================

var current_scene: Node = null
var is_loading: bool = false
var loading_thread: Thread = null
var loading_progress: float = 0.0

# Overlay de transition
var transition_overlay: ColorRect = null

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	_setup_transition_overlay()
	_validate_autoloads()
	
	if debug_mode:
		print("[SceneLoader] ✅ Initialisé et prêt")
		print("[SceneLoader] Autoloads protégés : ", AUTOLOAD_NAMES)

func _setup_transition_overlay() -> void:
	"""Crée un overlay pour les transitions visuelles"""
	transition_overlay = ColorRect.new()
	transition_overlay.name = "TransitionOverlay"  # ✅ Nom explicite
	transition_overlay.color = Color.BLACK
	transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_overlay.z_index = 1000
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.modulate.a = 0.0
	
	# ✅ NOUVEAU : Marquer comme autoload interne
	transition_overlay.set_meta("autoload_internal", true)
	
	add_child(transition_overlay)

## ✅ NOUVEAU : Validation au démarrage
func _validate_autoloads() -> void:
	"""Vérifie que tous les autoloads déclarés existent réellement"""
	var root = get_tree().root
	var found_autoloads: Array[String] = []
	
	for child in root.get_children():
		if child.name in AUTOLOAD_NAMES:
			found_autoloads.append(child.name)
	
	# Vérifier les manquants
	for autoload_name in AUTOLOAD_NAMES:
		if autoload_name not in found_autoloads:
			push_warning("[SceneLoader] ⚠️ Autoload déclaré mais introuvable : ", autoload_name)
	
	if debug_mode:
		print("[SceneLoader] Autoloads détectés : ", found_autoloads)

# ============================================================================
# CHARGEMENT DE SCÈNE
# ============================================================================

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
	
	if debug_mode:
		print("[SceneLoader] 🎬 Début du chargement : ", scene_path)
	
	if transition:
		await _fade_out()
	
	# ✅ Nettoyage amélioré avec protection robuste
	_cleanup_current_scene()
	
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
		print("[SceneLoader] ✅ Scène chargée : ", scene_path)

# ============================================================================
# NETTOYAGE DE SCÈNE (AMÉLIORÉ)
# ============================================================================

## ✅ NOUVEAU : Nettoyage robuste avec protection des autoloads
func _cleanup_current_scene() -> void:
	"""Supprime toutes les scènes sauf les autoloads protégés"""
	var root = get_tree().root
	var removed_count = 0
	
	if debug_mode:
		print("[SceneLoader] 🧹 Nettoyage des scènes...")
	
	for child in root.get_children():
		# Protection du SceneLoader lui-même
		if child == self:
			continue
		
		# ✅ NOUVEAU : Vérification robuste des autoloads
		if _is_autoload(child):
			if debug_mode:
				print("[SceneLoader]   ⏭️ Autoload protégé : ", child.name)
			continue
		
		# Suppression de la scène
		if debug_mode:
			print("[SceneLoader]   🗑️ Suppression : ", child.name)
		
		child.queue_free()
		removed_count += 1
	
	if debug_mode:
		print("[SceneLoader] ✅ Nettoyage terminé : ", removed_count, " scène(s) supprimée(s)")
	
	# Attendre que tout soit bien supprimé
	await get_tree().process_frame
	current_scene = null

## ✅ NOUVEAU : Vérification robuste des autoloads
func _is_autoload(node: Node) -> bool:
	"""
	Vérifie si un nœud est un autoload à protéger
	
	Critères de protection :
	1. Nom dans AUTOLOAD_NAMES
	2. Métadonnée "autoload" = true
	3. Métadonnée "autoload_internal" = true (pour TransitionOverlay)
	"""
	# Vérification par nom
	if node.name in AUTOLOAD_NAMES:
		return true
	
	# Vérification par métadonnée (pour autoloads ajoutés dynamiquement)
	if node.has_meta("autoload") and node.get_meta("autoload"):
		return true
	
	# Vérification métadonnée interne (TransitionOverlay, etc.)
	if node.has_meta("autoload_internal") and node.get_meta("autoload_internal"):
		return true
	
	return false

# ============================================================================
# CHARGEMENT ASYNCHRONE
# ============================================================================

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
	
	return null

# ============================================================================
# AUTO-CONNEXION DES SIGNAUX
# ============================================================================

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
				print("[SceneLoader] 🔗 Signal connecté : ", source.name, ".", signal_name, " -> ", target.name, ".", method)

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

# ============================================================================
# TRANSITIONS VISUELLES
# ============================================================================

## Fondu au noir (fade out)
func _fade_out() -> void:
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 1.0, fade_duration)
	await tween.finished

## Retour depuis le noir (fade in)
func _fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 0.0, fade_duration)
	await tween.finished
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

# ============================================================================
# UTILITAIRES
# ============================================================================

## Rechargement de la scène actuelle
func reload_current_scene(transition: bool = true) -> void:
	if current_scene:
		var scene_path = current_scene.scene_file_path
		load_scene(scene_path, transition)

## ✅ NOUVEAU : Ajout dynamique d'autoload à protéger
func register_autoload(node: Node) -> void:
	"""
	Enregistre un nœud comme autoload à protéger
	Utile pour des autoloads créés dynamiquement
	"""
	node.set_meta("autoload", true)
	
	if debug_mode:
		print("[SceneLoader] 📌 Autoload enregistré : ", node.name)

## ✅ NOUVEAU : Retrait d'un autoload de la protection
func unregister_autoload(node: Node) -> void:
	"""Retire la protection autoload d'un nœud"""
	if node.has_meta("autoload"):
		node.remove_meta("autoload")
	
	if debug_mode:
		print("[SceneLoader] 📍 Autoload désenregistré : ", node.name)

# ============================================================================
# NETTOYAGE
# ============================================================================

func _exit_tree() -> void:
	if loading_thread and loading_thread.is_alive():
		loading_thread.wait_to_finish()
