extends Node
## GameManager - Orchestre le cycle de vie du jeu
## Autoload global qui gère SceneLoader et EventBus

var scene_loader: SceneLoader
var current_scene_id: int = -1
var game_state: Dictionary = {}
var campaign_manager: CampaignManager


func _on_game_started() -> void:
	"""Callback quand une nouvelle partie démarre"""
	print("[GameManager] Nouvelle partie - Lancement de la séquence d'intro")
	
	# ✅ CHANGEMENT : Charger la scène d'intro dialogue au lieu de world_map
	load_scene_by_id(SceneRegistry.SceneID.INTRO_DIALOGUE, true)
	
	# Attendre que la scène soit chargée, puis lancer la campagne
	await get_tree().create_timer(1.0).timeout
	campaign_manager.start_new_campaign()

func _on_campaign_started() -> void:
	"""Callback quand la campagne démarre"""
	print("[GameManager] Campagne démarrée")


func _ready() -> void:
	# Initialiser le SceneLoader
	scene_loader = SceneLoader.new()
	add_child(scene_loader)
	
	# Valider le registre des scènes
	if not SceneRegistry.validate_registry():
		push_warning("[GameManager] Certaines scènes sont manquantes")
	
	# Connecter les événements
	_setup_event_connections()
	campaign_manager = CampaignManager.new()
	add_child(campaign_manager)
	# Charger la scène initiale
	call_deferred("_load_initial_scene")
	
	print("[GameManager] Initialisé")

func _setup_event_connections() -> void:
	"""Configure les connexions aux événements globaux"""
	EventBus.safe_connect("scene_change_requested", _on_scene_change_requested)
	EventBus.safe_connect("return_to_menu_requested", _on_return_to_menu_requested)
	EventBus.safe_connect("quit_game_requested", _on_quit_game_requested)
	EventBus.safe_connect("game_paused", _on_game_paused)
	EventBus.safe_connect("game_started", _on_game_started)
	EventBus.safe_connect("campaign_started", _on_campaign_started)

func _load_initial_scene() -> void:
	"""Charge la scène initiale (menu principal)"""
	load_scene_by_id(SceneRegistry.SceneID.MAIN_MENU, false)

func load_scene_by_id(scene_id: int, transition: bool = true) -> void:
	"""Charge une scène via son ID du registre"""
	if not SceneRegistry.scene_exists(scene_id):
		push_error("[GameManager] Impossible de charger la scène : ", scene_id)
		return
	
	var scene_path = SceneRegistry.get_scene_path(scene_id)
	current_scene_id = scene_id
	
	# Gérer la musique selon les métadonnées
	var metadata = SceneRegistry.get_scene_metadata(scene_id)
	if metadata.has("music"):
		_change_music(metadata.music)
	
	scene_loader.load_scene(scene_path, transition)

func load_scene_by_path(scene_path: String, transition: bool = true) -> void:
	"""Charge une scène directement par son chemin"""
	current_scene_id = -1
	scene_loader.load_scene(scene_path, transition)

func reload_current_scene(transition: bool = true) -> void:
	"""Recharge la scène actuelle"""
	if current_scene_id != -1:
		load_scene_by_id(current_scene_id, transition)
	else:
		scene_loader.reload_current_scene(transition)

# ============================================================================
# GESTION DE L'ÉTAT DU JEU
# ============================================================================

func pause_game(paused: bool) -> void:
	"""Met le jeu en pause"""
	get_tree().paused = paused
	EventBus.game_paused.emit(paused)

func save_game(save_name: String) -> void:
	"""Sauvegarde l'état du jeu"""
	# TODO: Implémenter la sauvegarde
	game_state["timestamp"] = Time.get_unix_time_from_system()
	game_state["scene_id"] = current_scene_id
	
	EventBus.game_saved.emit(save_name)
	EventBus.notify("Partie sauvegardée : " + save_name, "success")

func load_game(save_name: String) -> void:
	"""Charge une sauvegarde"""
	# TODO: Implémenter le chargement
	EventBus.game_loaded.emit(save_name)
	EventBus.notify("Partie chargée : " + save_name, "success")

# ============================================================================
# CALLBACKS EVENTBUS
# ============================================================================

func _on_scene_change_requested(scene_id: int) -> void:
	"""Réaction à une demande de changement de scène"""
	load_scene_by_id(scene_id)

func _on_return_to_menu_requested() -> void:
	"""Retour au menu principal"""
	load_scene_by_id(SceneRegistry.SceneID.MAIN_MENU)

func _on_quit_game_requested() -> void:
	"""Quitter le jeu"""
	print("[GameManager] Fermeture du jeu...")
	get_tree().quit()

func _on_game_paused(paused: bool) -> void:
	"""Réaction à la mise en pause"""
	print("[GameManager] Jeu ", "en pause" if paused else "repris")

# ============================================================================
# HELPERS
# ============================================================================

func _change_music(music_path: String) -> void:
	"""Change la musique de fond (à implémenter avec votre AudioManager)"""
	# TODO: Implémenter avec votre système audio
	print("[GameManager] Changement de musique : ", music_path)

func get_current_scene() -> Node:
	"""Retourne la scène actuellement chargée"""
	return scene_loader.current_scene

func is_loading() -> bool:
	"""Vérifie si un chargement est en cours"""
	return scene_loader.is_loading

func get_loading_progress() -> float:
	"""Retourne la progression du chargement"""
	return scene_loader.loading_progress

# ============================================================================
# DEBUG
# ============================================================================

func _input(event: InputEvent) -> void:
	# Raccourcis de debug (à désactiver en production)
	if OS.is_debug_build():
		if event.is_action_pressed("ui_home"):
			EventBus.debug_list_connections()
		
		if event.is_action_pressed("ui_end"):
			print("\n=== État GameManager ===")
			print("Scène actuelle : ", SceneRegistry.get_scene_name(current_scene_id))
			print("En chargement : ", is_loading())
			print("=======================\n")
