extends Node
## EventBus - Hub de communication global découplé
## Permet aux scènes de communiquer sans dépendances directes

class_name EventBus

# ============================================================================
# SIGNAUX GLOBAUX DU JEU
# ============================================================================

# --- Système ---
signal game_started()
signal game_paused(paused: bool)
signal game_saved(save_name: String)
signal game_loaded(save_name: String)
signal settings_changed(settings: Dictionary)

# --- Navigation ---
signal scene_change_requested(scene_id: int)  # SceneRegistry.SceneID
signal return_to_menu_requested()
signal quit_game_requested()

# --- Combat ---
signal battle_started(battle_data: Dictionary)
signal battle_ended(results: Dictionary)
signal duo_formed(unit_a: Node, unit_b: Node)
signal duo_broken(unit_a: Node, unit_b: Node)
signal unit_attacked(attacker: Node, target: Node, damage: int)
signal unit_died(unit: Node)
signal turn_started(unit: Node)
signal turn_ended(unit: Node)

# --- Statistiques & Progression ---
signal stats_updated(unit: Node, stat_name: String, new_value: float)
signal threat_level_changed(duo: Array, new_threat: float)
signal legend_gained(duo: Array, legend_type: String)
signal title_unlocked(unit: Node, title: String)
signal mvp_awarded(unit: Node, battle_id: String)

# --- Divinités (Système de Foi) ---
signal divine_points_gained(god_name: String, points: int)
signal divine_threshold_reached(god_name: String, threshold: int)
signal divine_event_triggered(god_name: String, event_data: Dictionary)

# --- Monde & Narration ---
signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal choice_made(choice_id: String, option: int)
signal cutscene_started(cutscene_id: String)
signal cutscene_ended(cutscene_id: String)
signal location_discovered(location_name: String)
signal quest_updated(quest_id: String, status: String)

# --- Ressources ---
signal gold_changed(new_amount: int)
signal item_gained(item_id: String, quantity: int)
signal item_lost(item_id: String, quantity: int)

# --- UI ---
signal notification_posted(message: String, type: String)
signal tooltip_requested(content: String, position: Vector2)
signal tooltip_hidden()

# ============================================================================
# MÉTHODES UTILITAIRES
# ============================================================================

## Émettre un événement avec log optionnel
func emit_event(event_name: String, args: Array = [], debug: bool = false) -> void:
	if not has_signal(event_name):
		push_warning("[EventBus] Signal introuvable : ", event_name)
		return
	
	if debug:
		print("[EventBus] Émission : ", event_name, " avec args : ", args)
	
	match args.size():
		0: emit_signal(event_name)
		1: emit_signal(event_name, args[0])
		2: emit_signal(event_name, args[0], args[1])
		3: emit_signal(event_name, args[0], args[1], args[2])
		4: emit_signal(event_name, args[0], args[1], args[2], args[3])
		_: push_error("[EventBus] Trop d'arguments pour : ", event_name)

## Connexion sécurisée avec vérification
func safe_connect(signal_name: String, callable: Callable, flags: int = 0) -> void:
	if not has_signal(signal_name):
		push_error("[EventBus] Impossible de connecter à un signal inexistant : ", signal_name)
		return
	
	if is_connected(signal_name, callable):
		push_warning("[EventBus] Déjà connecté : ", signal_name)
		return
	
	connect(signal_name, callable, flags)

## Déconnexion sécurisée
func safe_disconnect(signal_name: String, callable: Callable) -> void:
	if not has_signal(signal_name):
		return
	
	if is_connected(signal_name, callable):
		disconnect(signal_name, callable)

## Déconnexion de tous les signaux d'un objet
func disconnect_all(object: Object) -> void:
	for signal_dict in get_signal_list():
		var signal_name = signal_dict["name"]
		var connections = get_signal_connection_list(signal_name)
		
		for connection in connections:
			if connection["callable"].get_object() == object:
				disconnect(signal_name, connection["callable"])

# ============================================================================
# HELPERS SPÉCIFIQUES AU JEU
# ============================================================================

## Notification simple
func notify(message: String, type: String = "info") -> void:
	notification_posted.emit(message, type)

## Changement de scène via EventBus
func change_scene(scene_id: int) -> void:
	scene_change_requested.emit(scene_id)

## Mise à jour des statistiques divines
func add_divine_points(god: String, points: int) -> void:
	divine_points_gained.emit(god, points)

## Formation de duo
func form_duo(unit_a: Node, unit_b: Node) -> void:
	duo_formed.emit(unit_a, unit_b)

## Rupture de duo
func break_duo(unit_a: Node, unit_b: Node) -> void:
	duo_broken.emit(unit_a, unit_b)

## Attaque d'unité
func attack(attacker: Node, target: Node, damage: int) -> void:
	unit_attacked.emit(attacker, target, damage)

## Début de combat
func start_battle(data: Dictionary) -> void:
	battle_started.emit(data)

## Fin de combat
func end_battle(results: Dictionary) -> void:
	battle_ended.emit(results)

## Debug : lister tous les signaux actifs
func debug_list_connections() -> void:
	print("\n=== EventBus - Connexions actives ===")
	for signal_dict in get_signal_list():
		var signal_name = signal_dict["name"]
		var connections = get_signal_connection_list(signal_name)
		
		if connections.size() > 0:
			print("\n[", signal_name, "] : ", connections.size(), " connexions")
			for connection in connections:
				var target = connection["callable"].get_object()
				var method = connection["callable"].get_method()
				print("  -> ", target.name if target else "null", ".", method)
	print("\n=====================================\n")
