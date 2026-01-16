extends Node2D
## BattleMapManager - Gestionnaire principal du système de combat
## Orchestre tous les modules de combat (terrain, unités, actions, déplacement, etc.)

class_name BattleMapManager

# ============================================================================
# SIGNAUX LOCAUX
# ============================================================================

signal battle_map_ready()
signal turn_phase_changed(phase: TurnPhase)
signal unit_selected(unit: BattleUnit)
signal unit_deselected()
signal action_completed()

# ============================================================================
# ENUMS
# ============================================================================

enum TurnPhase {
	PLAYER_TURN,
	ENEMY_TURN,
	CUTSCENE,
	VICTORY,
	DEFEAT
}

# ============================================================================
# MODULES (Injectés ou créés dynamiquement)
# ============================================================================

var terrain_module: TerrainModule
var unit_manager: UnitManager
var movement_module: MovementModule
var action_module: ActionModule
var objective_module: ObjectiveModule
var scenario_module: ScenarioModule
var stats_tracker: BattleStatsTracker
var ai_module: AIModule

# ============================================================================
# RÉFÉRENCES UI
# ============================================================================

@onready var grid_container: Node2D = $GridContainer
@onready var units_container: Node2D = $UnitsContainer
@onready var ui_layer: CanvasLayer = $UILayer
@onready var battle_ui: Control = $UILayer/BattleUI
@onready var camera: Camera2D = $Camera2D

# ============================================================================
# CONFIGURATION
# ============================================================================

const TILE_SIZE: int = 48
const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 15

# ============================================================================
# ÉTAT DU COMBAT
# ============================================================================

var battle_data: Dictionary = {}
var current_phase: TurnPhase = TurnPhase.PLAYER_TURN
var current_turn: int = 1
var selected_unit: BattleUnit = null
var is_battle_active: bool = false

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	# Connexion aux événements globaux
	_connect_to_event_bus()
	
	print("[BattleMapManager] Initialisé")

## Méthode appelée par EventBus pour démarrer un combat
func initialize_battle(data: Dictionary) -> void:
	"""
	Initialise un combat avec les données fournies
	
	Format de data:
	{
		"terrain": "forest" | "plains" | "castle" | { terrain_data },
		"player_units": [unit_data_1, unit_data_2, ...],
		"enemy_units": [unit_data_1, unit_data_2, ...],
		"objectives": { objective_data },
		"scenario": { scenario_data },
		"music": "res://audio/battle_theme.ogg",
		"difficulty": "normal" | "hard" | "extreme"
	}
	"""
	
	if is_battle_active:
		push_warning("[BattleMapManager] Combat déjà en cours")
		return
	
	battle_data = data
	is_battle_active = true
	
	print("[BattleMapManager] Initialisation du combat...")
	
	# 1. Initialiser les modules dans l'ordre
	await _initialize_modules()
	
	# 2. Charger le terrain
	await _load_terrain(data.get("terrain", "plains"))
	
	# 3. Charger les objectifs
	await _load_objectives(data.get("objectives", {}))
	
	# 4. Charger le scénario (dialogues, barks, etc.)
	await _load_scenario(data.get("scenario", {}))
	
	# 5. Spawner les unités
	await _spawn_units(data.get("player_units", []), data.get("enemy_units", []))
	
	# 6. Démarrer le combat
	await _start_battle()
	
	print("[BattleMapManager] Combat prêt !")
	battle_map_ready.emit()

# ============================================================================
# INITIALISATION DES MODULES
# ============================================================================

func _initialize_modules() -> void:
	"""Crée et initialise tous les modules de combat"""
	
	# Module Terrain
	terrain_module = TerrainModule.new()
	terrain_module.tile_size = TILE_SIZE
	terrain_module.grid_width = GRID_WIDTH
	terrain_module.grid_height = GRID_HEIGHT
	grid_container.add_child(terrain_module)
	
	# Module Unités
	unit_manager = UnitManager.new()
	unit_manager.tile_size = TILE_SIZE
	units_container.add_child(unit_manager)
	
	# Module Mouvement
	movement_module = MovementModule.new()
	movement_module.terrain = terrain_module
	movement_module.unit_manager = unit_manager
	add_child(movement_module)
	
	# Module Actions
	action_module = ActionModule.new()
	action_module.unit_manager = unit_manager
	action_module.terrain = terrain_module
	add_child(action_module)
	
	# Module Objectifs
	objective_module = ObjectiveModule.new()
	add_child(objective_module)
	
	# Module Scénario
	scenario_module = ScenarioModule.new()
	add_child(scenario_module)
	
	# Module Statistiques
	stats_tracker = BattleStatsTracker.new()
	add_child(stats_tracker)
	
	# Module IA
	ai_module = AIModule.new()
	ai_module.terrain = terrain_module
	ai_module.unit_manager = unit_manager
	ai_module.movement_module = movement_module
	ai_module.action_module = action_module
	add_child(ai_module)
	
	# Connexions inter-modules
	_connect_modules()
	
	await get_tree().process_frame
	print("[BattleMapManager] Modules initialisés")

func _connect_modules() -> void:
	"""Connecte les signaux entre modules"""
	
	# Unit Manager -> BattleMapManager
	unit_manager.unit_died.connect(_on_unit_died)
	unit_manager.unit_moved.connect(_on_unit_moved)
	
	# Movement Module -> Stats
	movement_module.movement_completed.connect(stats_tracker.record_movement)
	
	# Action Module -> Stats
	action_module.action_executed.connect(stats_tracker.record_action)
	
	# Objective Module -> BattleMapManager
	objective_module.objective_completed.connect(_on_objective_completed)
	objective_module.all_objectives_completed.connect(_on_victory)

# ============================================================================
# CHARGEMENT DES DONNÉES
# ============================================================================

func _load_terrain(terrain_data: Variant) -> void:
	"""Charge et génère le terrain"""
	
	if typeof(terrain_data) == TYPE_STRING:
		# Terrain prédéfini
		terrain_module.load_preset(terrain_data)
	elif typeof(terrain_data) == TYPE_DICTIONARY:
		# Terrain personnalisé
		terrain_module.load_custom(terrain_data)
	
	await terrain_module.generation_complete
	print("[BattleMapManager] Terrain chargé")

func _load_objectives(objectives_data: Dictionary) -> void:
	"""Charge les objectifs de la mission"""
	
	objective_module.setup_objectives(objectives_data)
	await get_tree().process_frame
	print("[BattleMapManager] Objectifs chargés")

func _load_scenario(scenario_data: Dictionary) -> void:
	"""Charge le scénario (dialogues, événements, etc.)"""
	
	scenario_module.setup_scenario(scenario_data)
	await get_tree().process_frame
	print("[BattleMapManager] Scénario chargé")

func _spawn_units(player_units: Array, enemy_units: Array) -> void:
	"""Spawne toutes les unités sur le terrain"""
	
	# Spawner les unités joueur
	for unit_data in player_units:
		var unit = unit_manager.spawn_unit(unit_data, true)
		if unit:
			stats_tracker.register_unit(unit)
	
	# Spawner les unités ennemies
	for unit_data in enemy_units:
		var unit = unit_manager.spawn_unit(unit_data, false)
		if unit:
			stats_tracker.register_unit(unit)
	
	await get_tree().process_frame
	print("[BattleMapManager] Unités spawnées: ", player_units.size(), " alliées, ", enemy_units.size(), " ennemies")

# ============================================================================
# DÉMARRAGE DU COMBAT
# ============================================================================

func _start_battle() -> void:
	"""Démarre le combat"""
	
	# Cutscene d'intro si présente
	if scenario_module.has_intro():
		change_phase(TurnPhase.CUTSCENE)
		await scenario_module.play_intro()
	
	# Notifier l'EventBus
	EventBus.battle_started.emit(battle_data)
	
	# Démarrer le premier tour
	change_phase(TurnPhase.PLAYER_TURN)
	_start_player_turn()

# ============================================================================
# GESTION DES TOURS
# ============================================================================

func change_phase(new_phase: TurnPhase) -> void:
	"""Change la phase du combat"""
	
	current_phase = new_phase
	turn_phase_changed.emit(new_phase)
	
	print("[BattleMapManager] Phase changée: ", TurnPhase.keys()[new_phase])

func _start_player_turn() -> void:
	"""Démarre le tour du joueur"""
	
	print("[BattleMapManager] === Tour ", current_turn, " - JOUEUR ===")
	
	# Réinitialiser les unités joueur
	unit_manager.reset_player_units()
	
	# Trigger scénario si présent
	scenario_module.trigger_turn_event(current_turn, true)
	
	# Activer l'input joueur
	set_process_input(true)

func _end_player_turn() -> void:
	"""Termine le tour du joueur"""
	
	print("[BattleMapManager] Fin du tour joueur")
	
	# Désactiver l'input
	set_process_input(false)
	
	# Déselectionner l'unité
	if selected_unit:
		_deselect_unit()
	
	# Passer au tour ennemi
	change_phase(TurnPhase.ENEMY_TURN)
	await get_tree().create_timer(0.5).timeout
	_start_enemy_turn()

func _start_enemy_turn() -> void:
	"""Démarre le tour ennemi"""
	
	print("[BattleMapManager] === Tour ", current_turn, " - ENNEMI ===")
	
	# Réinitialiser les unités ennemies
	unit_manager.reset_enemy_units()
	
	# Trigger scénario
	scenario_module.trigger_turn_event(current_turn, false)
	
	# Exécuter l'IA
	await ai_module.execute_enemy_turn()
	
	# Fin du tour ennemi
	_end_enemy_turn()

func _end_enemy_turn() -> void:
	"""Termine le tour ennemi"""
	
	print("[BattleMapManager] Fin du tour ennemi")
	
	# Incrémenter le compteur de tours
	current_turn += 1
	
	# Vérifier les objectifs
	objective_module.check_objectives()
	
	# Retour au tour joueur
	change_phase(TurnPhase.PLAYER_TURN)
	await get_tree().create_timer(0.5).timeout
	_start_player_turn()

# ============================================================================
# INPUT & SÉLECTION
# ============================================================================

func _input(event: InputEvent) -> void:
	if not is_battle_active or current_phase != TurnPhase.PLAYER_TURN:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid_pos = screen_to_grid(event.position)
		_handle_grid_click(grid_pos)

func _handle_grid_click(grid_pos: Vector2i) -> void:
	"""Gère un clic sur la grille"""
	
	# Vérifier si une unité est présente
	var clicked_unit = unit_manager.get_unit_at(grid_pos)
	
	if clicked_unit:
		_handle_unit_click(clicked_unit)
	elif selected_unit:
		_handle_movement_click(grid_pos)

func _handle_unit_click(unit: BattleUnit) -> void:
	"""Gère le clic sur une unité"""
	
	if unit.is_player_unit:
		# Sélectionner l'unité alliée
		_select_unit(unit)
	elif selected_unit and selected_unit.can_act():
		# Attaquer l'unité ennemie
		_attack_unit(selected_unit, unit)

func _handle_movement_click(target_pos: Vector2i) -> void:
	"""Gère le clic pour un déplacement"""
	
	if not selected_unit or not selected_unit.can_move():
		return
	
	# Vérifier si le mouvement est valide
	if movement_module.can_move_to(selected_unit, target_pos):
		await movement_module.move_unit(selected_unit, target_pos)
		selected_unit.movement_used = true

func _select_unit(unit: BattleUnit) -> void:
	"""Sélectionne une unité"""
	
	if selected_unit == unit:
		return
	
	# Déselectionner l'ancienne unité
	if selected_unit:
		_deselect_unit()
	
	# Sélectionner la nouvelle unité
	selected_unit = unit
	selected_unit.set_selected(true)
	unit_selected.emit(unit)
	
	# Afficher la portée de mouvement
	if unit.can_move():
		movement_module.show_movement_range(unit)
	
	# Afficher la portée d'attaque
	if unit.can_act():
		action_module.show_action_range(unit)
	
	print("[BattleMapManager] Unité sélectionnée: ", unit.unit_name)

func _deselect_unit() -> void:
	"""Désélectionne l'unité actuelle"""
	
	if selected_unit:
		selected_unit.set_selected(false)
		selected_unit = null
		unit_deselected.emit()
		
		# Masquer les portées
		movement_module.hide_ranges()
		action_module.hide_ranges()

# ============================================================================
# ACTIONS
# ============================================================================

func _attack_unit(attacker: BattleUnit, target: BattleUnit) -> void:
	"""Exécute une attaque"""
	
	if not action_module.can_attack(attacker, target):
		return
	
	await action_module.execute_attack(attacker, target)
	attacker.action_used = true
	
	# Vérifier si l'unité peut encore agir
	if not attacker.can_act():
		_deselect_unit()

# ============================================================================
# CALLBACKS MODULES
# ============================================================================

func _on_unit_died(unit: BattleUnit) -> void:
	"""Callback quand une unité meurt"""
	
	print("[BattleMapManager] Unité morte: ", unit.unit_name)
	
	# Notifier l'EventBus
	EventBus.unit_died.emit(unit)
	
	# Enregistrer les stats
	stats_tracker.record_death(unit)
	
	# Vérifier la défaite/victoire
	_check_battle_end()

func _on_unit_moved(unit: BattleUnit, from: Vector2i, to: Vector2i) -> void:
	"""Callback quand une unité se déplace"""
	
	# Trigger événements de scénario
	scenario_module.trigger_position_event(unit, to)
	
	# Vérifier les objectifs
	objective_module.check_position_objectives(unit, to)

func _on_objective_completed(objective_id: String) -> void:
	"""Callback quand un objectif est complété"""
	
	print("[BattleMapManager] Objectif complété: ", objective_id)
	EventBus.notify("Objectif complété!", "success")

func _on_victory() -> void:
	"""Callback de victoire"""
	
	print("[BattleMapManager] === VICTOIRE ===")
	change_phase(TurnPhase.VICTORY)
	await _end_battle(true)

func _check_battle_end() -> void:
	"""Vérifie si le combat est terminé"""
	
	# Vérifier la défaite (toutes les unités joueur mortes)
	if unit_manager.get_alive_player_units().is_empty():
		print("[BattleMapManager] === DÉFAITE ===")
		change_phase(TurnPhase.DEFEAT)
		await _end_battle(false)
		return
	
	# Vérifier la victoire (tous les ennemis morts + objectifs)
	if unit_manager.get_alive_enemy_units().is_empty():
		if objective_module.are_all_completed():
			_on_victory()

# ============================================================================
# FIN DE COMBAT
# ============================================================================

func _end_battle(victory: bool) -> void:
	"""Termine le combat"""
	
	is_battle_active = false
	
	# Jouer la cutscene de fin si présente
	if scenario_module.has_outro():
		change_phase(TurnPhase.CUTSCENE)
		await scenario_module.play_outro(victory)
	
	# Récupérer les statistiques
	var battle_stats = stats_tracker.get_final_stats()
	
	# Construire les résultats
	var results = {
		"victory": victory,
		"turns": current_turn,
		"stats": battle_stats,
		"objectives": objective_module.get_completion_status(),
		"mvp": stats_tracker.get_mvp(),
		"rewards": _calculate_rewards(victory, battle_stats)
	}
	
	# Notifier l'EventBus
	EventBus.battle_ended.emit(results)
	
	print("[BattleMapManager] Combat terminé. Résultats: ", results)
	
	# Transition vers l'écran de résultats
	await get_tree().create_timer(2.0).timeout
	EventBus.change_scene(SceneRegistry.SceneID.BATTLE_RESULTS)

func _calculate_rewards(victory: bool, stats: Dictionary) -> Dictionary:
	"""Calcule les récompenses"""
	
	if not victory:
		return {"gold": 0, "exp": 0}
	
	var base_gold = 100
	var base_exp = 50
	
	# Bonus selon les stats
	var efficiency_bonus = 1.0 + (stats.get("efficiency", 0) * 0.1)
	
	return {
		"gold": int(base_gold * efficiency_bonus),
		"exp": int(base_exp * efficiency_bonus)
	}

# ============================================================================
# UTILITAIRES
# ============================================================================

func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	"""Convertit une position écran en position grille"""
	
	var world_pos = camera.get_global_mouse_position()
	var grid_x = int(world_pos.x / TILE_SIZE)
	var grid_y = int(world_pos.y / TILE_SIZE)
	
	return Vector2i(grid_x, grid_y)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	"""Convertit une position grille en position monde"""
	
	return Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)

# ============================================================================
# EVENTBUS
# ============================================================================

func _connect_to_event_bus() -> void:
	"""Connexion aux événements globaux"""
	
	EventBus.safe_connect("battle_started", _on_eventbus_battle_started)

func _on_eventbus_battle_started(data: Dictionary) -> void:
	"""Callback EventBus pour démarrer un combat"""
	
	# Si ce BattleMapManager n'est pas déjà en combat, initialiser
	if not is_battle_active and data.has("battle_id"):
		initialize_battle(data)

# ============================================================================
# NETTOYAGE
# ============================================================================

func _exit_tree() -> void:
	"""Nettoyage à la fermeture"""
	
	EventBus.disconnect_all(self)
	print("[BattleMapManager] Nettoyé")
