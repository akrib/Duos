extends Node3D
## BattleMapManager3D - Gestionnaire principal du combat en 3D
## Version 3D avec caméra rotative et raycasting pour interactions

class_name BattleMapManager3D

# ============================================================================
# SIGNAUX
# ============================================================================

signal battle_map_ready()
signal turn_phase_changed(phase: TurnPhase)
signal unit_selected(unit: BattleUnit3D)
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
# RÉFÉRENCES UI
# ============================================================================

@onready var grid_container: Node3D = $GridContainer
@onready var units_container: Node3D = $UnitsContainer
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var ui_layer: CanvasLayer = $UILayer
@onready var battle_ui: Control = $UILayer/BattleUI

# ============================================================================
# MODULES
# ============================================================================

var terrain_module: TerrainModule3D
var unit_manager: UnitManager3D
var movement_module: MovementModule3D
var action_module: ActionModule3D
var objective_module: ObjectiveModule
var scenario_module: ScenarioModule
var stats_tracker: BattleStatsTracker
var ai_module: AIModule3D

# ============================================================================
# CONFIGURATION
# ============================================================================

const TILE_SIZE: float = 1.0
const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 15

# Configuration caméra
const CAMERA_ROTATION_SPEED: float = 90.0  # Degrés par seconde
const CAMERA_DISTANCE: float = 15.0
const CAMERA_HEIGHT: float = 12.0
const CAMERA_ANGLE: float = 45.0  # Angle de la caméra (degrés)

# Couleurs de highlight
const MOVEMENT_COLOR: Color = Color(0.3, 0.6, 1.0, 0.5)
const ATTACK_COLOR: Color = Color(1.0, 0.3, 0.3, 0.5)

# ============================================================================
# ÉTAT
# ============================================================================

var battle_data: Dictionary = {}
var current_phase: TurnPhase = TurnPhase.PLAYER_TURN
var current_turn: int = 1
var selected_unit: BattleUnit3D = null
var is_battle_active: bool = false

# Caméra
var camera_rotation_target: float = 0.0
var camera_rotation_current: float = 0.0
var is_camera_rotating: bool = false

# Raycasting
var mouse_ray_length: float = 1000.0

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	_setup_camera()
	_connect_to_event_bus()
	print("[BattleMapManager3D] Initialisé")

func _setup_camera() -> void:
	"""Configure la caméra initiale"""
	camera_rig.position = Vector3.ZERO
	camera_rotation_current = 0.0
	camera_rotation_target = 0.0
	_update_camera_position()

func initialize_battle(data: Dictionary) -> void:
	"""Initialise un combat avec les données fournies"""
	if is_battle_active:
		push_warning("[BattleMapManager3D] Combat déjà en cours")
		return
	
	battle_data = data
	is_battle_active = true
	
	print("[BattleMapManager3D] Initialisation du combat 3D...")
	
	await _initialize_modules()
	await _load_terrain(data.get("terrain", "plains"))
	await _load_objectives(data.get("objectives", {}))
	await _load_scenario(data.get("scenario", {}))
	await _spawn_units(data.get("player_units", []), data.get("enemy_units", []))
	await _start_battle()
	
		# ✅ NOUVEAU : Nettoyer maintenant que tout est chargé
	EventBus.clear_battle_data()
	
	print("[BattleMapManager3D] Combat prêt !")
	battle_map_ready.emit()

# ============================================================================
# INITIALISATION DES MODULES
# ============================================================================

func _initialize_modules() -> void:
	"""Crée et initialise tous les modules 3D"""
	
	# Terrain 3D
	terrain_module = TerrainModule3D.new()
	terrain_module.tile_size = TILE_SIZE
	terrain_module.grid_width = GRID_WIDTH
	terrain_module.grid_height = GRID_HEIGHT
	grid_container.add_child(terrain_module)
	
	# Unit Manager 3D
	unit_manager = UnitManager3D.new()
	unit_manager.tile_size = TILE_SIZE
	unit_manager.terrain = terrain_module
	units_container.add_child(unit_manager)
	
	# Movement Module 3D
	movement_module = MovementModule3D.new()
	movement_module.terrain = terrain_module
	movement_module.unit_manager = unit_manager
	add_child(movement_module)
	
	# Action Module 3D
	action_module = ActionModule3D.new()
	action_module.unit_manager = unit_manager
	action_module.terrain = terrain_module
	add_child(action_module)
	
	# Modules non-3D (réutilisés)
	objective_module = ObjectiveModule.new()
	add_child(objective_module)
	
	scenario_module = ScenarioModule.new()
	add_child(scenario_module)
	
	stats_tracker = BattleStatsTracker.new()
	add_child(stats_tracker)
	
	ai_module = AIModule3D.new()
	ai_module.terrain = terrain_module
	ai_module.unit_manager = unit_manager
	ai_module.movement_module = movement_module
	ai_module.action_module = action_module
	add_child(ai_module)
	
	_connect_modules()
	await get_tree().process_frame
	print("[BattleMapManager3D] Modules 3D initialisés")

func _connect_modules() -> void:
	"""Connecte les signaux entre modules"""
	unit_manager.unit_died.connect(_on_unit_died)
	unit_manager.unit_moved.connect(_on_unit_moved)
	movement_module.movement_completed.connect(stats_tracker.record_movement)
	action_module.action_executed.connect(stats_tracker.record_action)
	objective_module.objective_completed.connect(_on_objective_completed)
	objective_module.all_objectives_completed.connect(_on_victory)

# ============================================================================
# CHARGEMENT
# ============================================================================

func _load_terrain(terrain_data: Variant) -> void:
	if typeof(terrain_data) == TYPE_STRING:
		terrain_module.load_preset(terrain_data)
	elif typeof(terrain_data) == TYPE_DICTIONARY:
		terrain_module.load_custom(terrain_data)
	await terrain_module.generation_complete
	print("[BattleMapManager3D] Terrain 3D chargé")

func _load_objectives(objectives_data: Dictionary) -> void:
	objective_module.setup_objectives(objectives_data)
	await get_tree().process_frame

func _load_scenario(scenario_data: Dictionary) -> void:
	scenario_module.setup_scenario(scenario_data)
	await get_tree().process_frame

func _spawn_units(player_units: Array, enemy_units: Array) -> void:
	for unit_data in player_units:
		var unit = unit_manager.spawn_unit(unit_data, true)
		if unit:
			stats_tracker.register_unit(unit)
	
	for unit_data in enemy_units:
		var unit = unit_manager.spawn_unit(unit_data, false)
		if unit:
			stats_tracker.register_unit(unit)
	
	await get_tree().process_frame
	print("[BattleMapManager3D] Unités 3D spawnées")

# ============================================================================
# DÉMARRAGE
# ============================================================================

func _start_battle() -> void:
	if scenario_module.has_intro():
		change_phase(TurnPhase.CUTSCENE)
		await scenario_module.play_intro()
	
	EventBus.battle_started.emit(battle_data)
	change_phase(TurnPhase.PLAYER_TURN)
	_start_player_turn()

# ============================================================================
# GESTION DES TOURS (identique)
# ============================================================================

func change_phase(new_phase: TurnPhase) -> void:
	current_phase = new_phase
	turn_phase_changed.emit(new_phase)
	print("[BattleMapManager3D] Phase: ", TurnPhase.keys()[new_phase])

func _start_player_turn() -> void:
	print("[BattleMapManager3D] === Tour ", current_turn, " - JOUEUR ===")
	unit_manager.reset_player_units()
	scenario_module.trigger_turn_event(current_turn, true)
	set_process_input(true)

func _end_player_turn() -> void:
	print("[BattleMapManager3D] Fin du tour joueur")
	set_process_input(false)
	if selected_unit:
		_deselect_unit()
	
	change_phase(TurnPhase.ENEMY_TURN)
	await get_tree().create_timer(0.5).timeout
	_start_enemy_turn()

func _start_enemy_turn() -> void:
	print("[BattleMapManager3D] === Tour ", current_turn, " - ENNEMI ===")
	unit_manager.reset_enemy_units()
	scenario_module.trigger_turn_event(current_turn, false)
	await ai_module.execute_enemy_turn()
	_end_enemy_turn()

func _end_enemy_turn() -> void:
	print("[BattleMapManager3D] Fin du tour ennemi")
	current_turn += 1
	objective_module.check_objectives()
	change_phase(TurnPhase.PLAYER_TURN)
	await get_tree().create_timer(0.5).timeout
	_start_player_turn()

# ============================================================================
# PROCESS & INPUT 3D
# ============================================================================

func _process(delta: float) -> void:
	_process_camera_rotation(delta)

func _process_camera_rotation(delta: float) -> void:
	"""Gère la rotation progressive de la caméra"""
	if is_camera_rotating:
		var angle_diff = camera_rotation_target - camera_rotation_current
		
		if abs(angle_diff) < 0.1:
			camera_rotation_current = camera_rotation_target
			is_camera_rotating = false
		else:
			var rotation_step = CAMERA_ROTATION_SPEED * delta
			if angle_diff < 0:
				rotation_step = -rotation_step
			
			camera_rotation_current += rotation_step
			_update_camera_position()

func _update_camera_position() -> void:
	"""Met à jour la position et rotation de la caméra"""
	var angle_rad = deg_to_rad(camera_rotation_current)
	
	# Position du rig de caméra (rotation autour de l'origine)
	camera_rig.rotation.y = angle_rad
	
	# La caméra reste à distance et angle fixes
	var cam_angle_rad = deg_to_rad(CAMERA_ANGLE)
	camera.position = Vector3(
		0,
		CAMERA_HEIGHT,
		CAMERA_DISTANCE
	)
	camera.rotation.x = -cam_angle_rad

func rotate_camera(degrees: float) -> void:
	"""Demande une rotation de la caméra"""
	camera_rotation_target += degrees
	
	# Normaliser entre 0 et 360
	while camera_rotation_target >= 360:
		camera_rotation_target -= 360
	while camera_rotation_target < 0:
		camera_rotation_target += 360
	
	is_camera_rotating = true

func _input(event: InputEvent) -> void:
	if not is_battle_active or current_phase != TurnPhase.PLAYER_TURN:
		return
	
	# Rotation de la caméra avec A/E
	if event.is_action_pressed("ui_home"):  # A
		rotate_camera(-90)
	elif event.is_action_pressed("ui_end"):  # E
		rotate_camera(90)
	
	# Clic souris pour sélection/action
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse_click(event.position)

# ============================================================================
# RAYCASTING & SÉLECTION 3D
# ============================================================================

func _handle_mouse_click(mouse_pos: Vector2) -> void:
	"""Gère le clic souris avec raycasting 3D"""
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * mouse_ray_length
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collision_mask = 3  # Layers 1 (terrain) et 2 (units)
	
	var result = space_state.intersect_ray(query)
	
	if result:
		_handle_raycast_hit(result)

func _handle_raycast_hit(result: Dictionary) -> void:
	"""Traite le résultat du raycast"""
	var collider = result.collider
	
	# Clic sur une unité
	if collider.has_meta("unit"):
		var unit = collider.get_meta("unit")
		_handle_unit_click(unit)
		return
	
	# Clic sur le terrain
	if collider is StaticBody3D:
		var mesh_parent = collider.get_parent()
		if mesh_parent.has_meta("grid_position"):
			var grid_pos = mesh_parent.get_meta("grid_position")
			_handle_terrain_click(grid_pos)

func _handle_unit_click(unit: BattleUnit3D) -> void:
	"""Gère le clic sur une unité"""
	if unit.is_player_unit:
		_select_unit(unit)
	elif selected_unit and selected_unit.can_act():
		_attack_unit(selected_unit, unit)

func _handle_terrain_click(grid_pos: Vector2i) -> void:
	"""Gère le clic sur le terrain"""
	if not selected_unit or not selected_unit.can_move():
		return
	
	if movement_module.can_move_to(selected_unit, grid_pos):
		await movement_module.move_unit(selected_unit, grid_pos)
		selected_unit.movement_used = true

# ============================================================================
# SÉLECTION D'UNITÉ
# ============================================================================

func _select_unit(unit: BattleUnit3D) -> void:
	if selected_unit == unit:
		return
	
	if selected_unit:
		_deselect_unit()
	
	selected_unit = unit
	selected_unit.set_selected(true)
	unit_selected.emit(unit)
	
	# Afficher les portées
	if unit.can_move():
		var reachable = movement_module.calculate_reachable_positions(unit)
		terrain_module.highlight_tiles(reachable, MOVEMENT_COLOR)
	
	if unit.can_act():
		var attack_positions = action_module.get_attack_positions(unit)
		terrain_module.highlight_tiles(attack_positions, ATTACK_COLOR)
	
	print("[BattleMapManager3D] Unité sélectionnée: ", unit.unit_name)

func _deselect_unit() -> void:
	if selected_unit:
		selected_unit.set_selected(false)
		selected_unit = null
		unit_deselected.emit()
		terrain_module.clear_all_highlights()

# ============================================================================
# ACTIONS
# ============================================================================

func _attack_unit(attacker: BattleUnit3D, target: BattleUnit3D) -> void:
	if not action_module.can_attack(attacker, target):
		return
	
	await action_module.execute_attack(attacker, target)
	attacker.action_used = true
	
	if not attacker.can_act():
		_deselect_unit()

# ============================================================================
# CALLBACKS (identiques à la version 2D)
# ============================================================================

func _on_unit_died(unit: BattleUnit3D) -> void:
	print("[BattleMapManager3D] Unité morte: ", unit.unit_name)
	EventBus.unit_died.emit(unit)
	stats_tracker.record_death(unit)
	_check_battle_end()

func _on_unit_moved(unit: BattleUnit3D, from: Vector2i, to: Vector2i) -> void:
	scenario_module.trigger_position_event(unit, to)
	objective_module.check_position_objectives(unit, to)

func _on_objective_completed(objective_id: String) -> void:
	print("[BattleMapManager3D] Objectif complété: ", objective_id)
	EventBus.notify("Objectif complété!", "success")

func _on_victory() -> void:
	print("[BattleMapManager3D] === VICTOIRE ===")
	change_phase(TurnPhase.VICTORY)
	await _end_battle(true)

func _check_battle_end() -> void:
	if unit_manager.get_alive_player_units().is_empty():
		print("[BattleMapManager3D] === DÉFAITE ===")
		change_phase(TurnPhase.DEFEAT)
		await _end_battle(false)
		return
	
	if unit_manager.get_alive_enemy_units().is_empty():
		if objective_module.are_all_completed():
			_on_victory()

func _end_battle(victory: bool) -> void:
	is_battle_active = false
	
	if scenario_module.has_outro():
		change_phase(TurnPhase.CUTSCENE)
		await scenario_module.play_outro(victory)
	
	var battle_stats = stats_tracker.get_final_stats()
	var results = {
		"victory": victory,
		"turns": current_turn,
		"stats": battle_stats,
		"objectives": objective_module.get_completion_status(),
		"mvp": stats_tracker.get_mvp(),
		"rewards": _calculate_rewards(victory, battle_stats)
	}
	
	EventBus.battle_ended.emit(results)
	await get_tree().create_timer(2.0).timeout
	EventBus.change_scene(SceneRegistry.SceneID.BATTLE_RESULTS)

func _calculate_rewards(victory: bool, stats: Dictionary) -> Dictionary:
	if not victory:
		return {"gold": 0, "exp": 0}
	
	var base_gold = 100
	var base_exp = 50
	var efficiency_bonus = 1.0 + (stats.get("efficiency", 0) * 0.1)
	
	return {
		"gold": int(base_gold * efficiency_bonus),
		"exp": int(base_exp * efficiency_bonus)
	}

# ============================================================================
# EVENTBUS
# ============================================================================

func _connect_to_event_bus() -> void:
	EventBus.safe_connect("battle_started", _on_eventbus_battle_started)

func _on_eventbus_battle_started(data: Dictionary) -> void:
	if not is_battle_active and data.has("battle_id"):
		initialize_battle(data)

# ============================================================================
# NETTOYAGE
# ============================================================================

func _exit_tree() -> void:
	EventBus.disconnect_all(self)
	print("[BattleMapManager3D] Nettoyé")
