extends Node3D
## BattleMapManager3D - Gestionnaire principal du combat en 3D
## VERSION CORRIGÉE : Meilleur timing de chargement et système de dialogue intégré

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

enum ActionState {
	IDLE,              # Aucune action en cours
	UNIT_SELECTED,     # Unité sélectionnée, menu ouvert
	CHOOSING_DUO,      # En train de choisir un partenaire de duo
	SHOWING_MOVE,      # Affichage des cases de mouvement
	SHOWING_ATTACK,    # Affichage des cases d'attaque
	EXECUTING_ACTION   # En train d'exécuter une action
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

# Menu d'actions
@onready var action_popup: PopupPanel = $UILayer/BattleUI/ActionPopup
@onready var move_button: Button = $UILayer/BattleUI/ActionPopup/VBoxContainer/MoveButton
@onready var attack_button: Button = $UILayer/BattleUI/ActionPopup/VBoxContainer/AttackButton
@onready var defend_button: Button = $UILayer/BattleUI/ActionPopup/VBoxContainer/DefendButton
@onready var abilities_button: Button = $UILayer/BattleUI/ActionPopup/VBoxContainer/AbilitiesButton
@onready var items_button: Button = $UILayer/BattleUI/ActionPopup/VBoxContainer/ItemsButton
@onready var wait_action_button: Button = $UILayer/BattleUI/ActionPopup/VBoxContainer/WaitActionButton
@onready var cancel_button: Button = $UILayer/BattleUI/ActionPopup/VBoxContainer/CancelButton

# Menu de sélection de duo
#@onready var duo_popup: PopupPanel = $UILayer/BattleUI/DuoSelectionPopup
#@onready var duo_units_container: VBoxContainer = $UILayer/BattleUI/DuoSelectionPopup/VBoxContainer/UnitsContainer
#@onready var solo_button: Button = $UILayer/BattleUI/DuoSelectionPopup/VBoxContainer/SoloButton
#@onready var cancel_duo_button: Button = $UILayer/BattleUI/DuoSelectionPopup/VBoxContainer/CancelDuoButton



# Labels d'info (panel bas à droite)
@onready var info_unit_name_label: Label = $UILayer/BattleUI/UnitInfoPanel/MarginContainer/VBoxContainer/UnitNameLabel
@onready var info_class_label: Label = $UILayer/BattleUI/UnitInfoPanel/MarginContainer/VBoxContainer/ClassLabel
@onready var info_hp_value: Label = $UILayer/BattleUI/UnitInfoPanel/MarginContainer/VBoxContainer/StatsGrid/HPValue
@onready var info_atk_value: Label = $UILayer/BattleUI/UnitInfoPanel/MarginContainer/VBoxContainer/StatsGrid/ATKValue
@onready var info_def_value: Label = $UILayer/BattleUI/UnitInfoPanel/MarginContainer/VBoxContainer/StatsGrid/DEFValue
@onready var info_mov_value: Label = $UILayer/BattleUI/UnitInfoPanel/MarginContainer/VBoxContainer/StatsGrid/MOVValue
@onready var turn_label: Label = $UILayer/BattleUI/TopBar/MarginContainer/HBoxContainer/TurnLabel
@onready var phase_label: Label = $UILayer/BattleUI/TopBar/MarginContainer/HBoxContainer/PhaseLabel

# Boutons de contrôle
@onready var end_turn_button: Button = $UILayer/BattleUI/BottomBar/MarginContainer/HBoxContainer/ButtonsContainer/EndTurnButton
@onready var undo_button: Button = $UILayer/BattleUI/BottomBar/MarginContainer/HBoxContainer/ButtonsContainer/UndoButton
# dialogue
@onready var dialogue_box: DialogueBox = $UILayer/DialogueBox

# ============================================================================
# MODULES
# ============================================================================
var hovered_unit: BattleUnit3D = null
var terrain_module: TerrainModule3D
var unit_manager: UnitManager3D
var movement_module: MovementModule3D
var action_module: ActionModule3D
var objective_module: ObjectiveModule

var stats_tracker: BattleStatsTracker
var ai_module: AIModule3D
var json_scenario_module: JSONScenarioModule
var battle_state_machine: BattleStateMachine
var command_history: CommandHistory

var duo_system: DuoSystem
var ring_system: RingSystem
var data_validation: DataValidationModule

# ============================================================================
# CONFIGURATION
# ============================================================================

const TILE_SIZE: float = 1.0
const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 15

# Configuration caméra
const CAMERA_ROTATION_SPEED: float = 90.0
const CAMERA_DISTANCE: float = 15.0
const CAMERA_HEIGHT: float = 12.0
const CAMERA_ANGLE: float = 45.0

# Couleurs de highlight
const MOVEMENT_COLOR: Color = Color(0.3, 0.6, 1.0, 0.5)
const ATTACK_COLOR: Color = Color(1.0, 0.3, 0.3, 0.5)
# Scènes préchargées
const DUO_ATTACK_OPTION_SCENE = preload("res://scenes/ui/duo_attack_option.tscn")
const CHARACTER_MINI_CARD_SCENE = preload("res://scenes/ui/character_mini_card.tscn")

# ============================================================================
# ÉTAT
# ============================================================================

var battle_data: Dictionary = {}
var current_turn: int = 1
var selected_unit: BattleUnit3D = null
var duo_partner: BattleUnit3D = null
var is_battle_active: bool = false
var current_action_state: ActionState = ActionState.IDLE
var current_attack_profile: Dictionary = {}

# Caméra
var camera_rotation_target: float = 0.0
var camera_rotation_current: float = 0.0
var is_camera_rotating: bool = false

# Raycasting
var mouse_ray_length: float = 1000.0


@onready var duo_popup: PopupPanel = $UILayer/BattleUI/DuoSelectionPopup
@onready var support_card_container: PanelContainer = $UILayer/BattleUI/DuoSelectionPopup/MarginContainer/HBoxContainer/SupportMiniCard
@onready var leader_card_container: PanelContainer = $UILayer/BattleUI/DuoSelectionPopup/MarginContainer/HBoxContainer/LeaderMiniCard
@onready var duo_options_container: VBoxContainer = $UILayer/BattleUI/DuoSelectionPopup/MarginContainer/HBoxContainer/CenterContainer/DuoOptionsContainer
@onready var solo_button_duo: Button = $UILayer/BattleUI/DuoSelectionPopup/MarginContainer/HBoxContainer/CenterContainer/ButtonsContainer/SoloButton
@onready var cancel_duo_button: Button = $UILayer/BattleUI/DuoSelectionPopup/MarginContainer/HBoxContainer/CenterContainer/ButtonsContainer/CancelDuoButton

# Instances des cartes
var support_mini_card: CharacterMiniCard = null
var leader_mini_card: CharacterMiniCard = null

# ============================================================================
# INITIALISATION
# ============================================================================


func _ready() -> void:
	battle_state_machine = BattleStateMachine.new()
	battle_state_machine.debug_mode = true
	add_child(battle_state_machine)
	
	# Créer l'historique de commandes
	command_history = CommandHistory.new()
	add_child(command_history)
	
	_setup_camera()
	_connect_ui_buttons()
	
	
	print("[BattleMapManager3D] Initialisé, vérification des données...")
	
	await get_tree().process_frame
	
	if BattleDataManager.has_battle_data():
		var battle_data = BattleDataManager.get_battle_data()
		print("[BattleMapManager3D] ✅ Données récupérées : ", battle_data.get("battle_id"))
		call_deferred("initialize_battle", battle_data)
	else:
		push_error("[BattleMapManager3D] ❌ Aucune donnée de combat disponible")
	battle_state_machine.state_changed.connect(_on_battle_state_changed)
	
	support_mini_card = CHARACTER_MINI_CARD_SCENE.instantiate()
	support_card_container.add_child(support_mini_card)

	leader_mini_card = CHARACTER_MINI_CARD_SCENE.instantiate()
	leader_card_container.add_child(leader_mini_card)
	
	
	if DebugOverlay:
		DebugOverlay.watch_variable("Tour actuel", self, "current_turn")
		DebugOverlay.watch_variable("Phase", self, "current_phase")
		DebugOverlay.watch_variable("Unités joueur", unit_manager, "player_units")
		DebugOverlay.watch_variable("Unités ennemies", unit_manager, "enemy_units")

func _setup_camera() -> void:
	camera_rig.position = Vector3.ZERO
	camera_rotation_current = 0.0
	camera_rotation_target = 0.0
	_update_camera_position()

func _connect_ui_buttons() -> void:
	"""Connecte tous les boutons de l'interface"""
	# Menu d'actions
	move_button.pressed.connect(_on_move_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	defend_button.pressed.connect(_on_defend_pressed)
	abilities_button.pressed.connect(_on_abilities_pressed)
	items_button.pressed.connect(_on_items_pressed)
	wait_action_button.pressed.connect(_on_wait_action_pressed)
	cancel_button.pressed.connect(_on_cancel_action_pressed)
	
	# Menu de duo
	solo_button_duo.pressed.connect(_on_solo_attack_pressed)  
	cancel_duo_button.pressed.connect(_on_cancel_duo_pressed)
	
	# Boutons de contrôle
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	undo_button.pressed.connect(_on_undo_pressed)
	
func initialize_battle(data: Dictionary) -> void:
	if is_battle_active:
		push_warning("[BattleMapManager3D] Combat déjà en cours")
		return
	
	battle_data = data
	is_battle_active = true
	
	print("[BattleMapManager3D] ⚔️ Initialisation du combat 3D...")
	
	await _initialize_modules()
	
	if json_scenario_module and dialogue_box:
		json_scenario_module.dialogue_box = dialogue_box
		print("[BattleMapManager3D] DialogueBox configurée pour lua_scenario_module")
	
	await _load_terrain(data.get("terrain", "plains"))
	await _load_objectives(data.get("objectives", {}))
	await _load_scenario(data.get("scenario", {}))
	await _spawn_units(data.get("player_units", []), data.get("enemy_units", []))
	await _start_battle()
	
	print("[BattleMapManager3D] ✅ Combat prêt !")
	battle_map_ready.emit()
	
# ============================================================================
# INITIALISATION DES MODULES (identique)
# ============================================================================

func _initialize_modules() -> void:
	terrain_module = TerrainModule3D.new()
	terrain_module.tile_size = TILE_SIZE
	terrain_module.grid_width = GRID_WIDTH
	terrain_module.grid_height = GRID_HEIGHT
	grid_container.add_child(terrain_module)
	
	unit_manager = UnitManager3D.new()
	unit_manager.tile_size = TILE_SIZE
	unit_manager.terrain = terrain_module
	units_container.add_child(unit_manager)
	
	movement_module = MovementModule3D.new()
	movement_module.terrain = terrain_module
	movement_module.unit_manager = unit_manager
	add_child(movement_module)
	
	action_module = ActionModule3D.new()
	action_module.unit_manager = unit_manager
	action_module.terrain = terrain_module
	add_child(action_module)
	
	objective_module = ObjectiveModule.new()
	add_child(objective_module)
	
	json_scenario_module = JSONScenarioModule.new()
	add_child(json_scenario_module)
	
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
	
	duo_system = DuoSystem.new()
	duo_system.terrain_module  = terrain_module  # Injection de dépendance
	add_child(duo_system)
	
	ring_system = RingSystem.new()
	add_child(ring_system)
	
	data_validation = DataValidationModule.new()
	add_child(data_validation)
	
	# Charger les données
	ring_system.load_rings_from_json("res://data/ring/rings.json")
	
	# Valider les données
	var validation_report = data_validation.validate_all_data()
	
	if not validation_report.is_valid:
		push_error("[BattleMapManager3D] ❌ Validation des données échouée!")
		# Afficher les erreurs dans l'UI
		for error in validation_report.errors:
			print("  ERROR: ", error)
	
	# Connecter signaux
	_connect_duo_signals()
	
	print("[BattleMapManager3D] ✅ Modules Phase 1 initialisés")

	

func _connect_modules() -> void:
	unit_manager.unit_died.connect(_on_unit_died)
	unit_manager.unit_moved.connect(_on_unit_moved)
	movement_module.movement_completed.connect(stats_tracker.record_movement)
	action_module.action_executed.connect(stats_tracker.record_action)
	objective_module.objective_completed.connect(_on_objective_completed)
	objective_module.all_objectives_completed.connect(_on_victory)

# ============================================================================
# CHARGEMENT (identique)
# ============================================================================

func _load_terrain(terrain_data: Variant) -> void:
	if typeof(terrain_data) == TYPE_STRING:
		terrain_module.load_preset(terrain_data)
	elif typeof(terrain_data) == TYPE_DICTIONARY:
		terrain_module.load_custom(terrain_data)
	print("[BattleMapManager3D] Terrain 3D chargé")

func _load_objectives(objectives_data: Dictionary) -> void:
	if objectives_data.is_empty():
		return
	objective_module.setup_objectives(objectives_data)
	await get_tree().process_frame

func _load_scenario(scenario_data: Dictionary) -> void:
	if scenario_data.has("scenario_file"):
		json_scenario_module.setup_scenario(scenario_data.scenario_file)
	else:
		push_warning("[BattleMapManager3D] Pas de fichier de scénario fourni")
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
	print("[BattleMapManager3D] 🎬 Démarrage du combat...")
	
	if json_scenario_module.has_intro():
		change_phase(TurnPhase.CUTSCENE)
		await json_scenario_module.play_intro()
		print("[BattleMapManager3D] Intro terminée")
	
	EventBus.battle_started.emit(battle_data)
	change_phase(TurnPhase.PLAYER_TURN)
	_start_player_turn()

# ============================================================================
# GESTION DES TOURS
# ============================================================================

func change_phase(new_phase: TurnPhase) -> void:
	var state_name = TurnPhase.keys()[new_phase]
	battle_state_machine.change_state(state_name)

func _start_player_turn() -> void:
	print("[BattleMapManager3D] === Tour ", current_turn, " - JOUEUR ===")
	turn_label.text = "Tour " + str(current_turn)
	unit_manager.reset_player_units()
	
	# ✅ NOUVEAU : Mettre à jour les torus
	_update_all_torus_states(true)
	
	json_scenario_module.trigger_turn_event(current_turn, false)
	set_process_input(true)

func _update_all_torus_states(is_player_turn: bool) -> void:
	var all_units = unit_manager.get_all_units()
	
	for unit in all_units:
		var is_current_turn = (is_player_turn and unit.is_player_unit) or (not is_player_turn and not unit.is_player_unit)
		unit.update_torus_state(is_current_turn)

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
	
	# ✅ NOUVEAU : Mettre à jour les torus
	_update_all_torus_states(false)
	
	json_scenario_module.trigger_turn_event(current_turn, false)
	await ai_module.execute_enemy_turn()
	_end_enemy_turn()

func _end_enemy_turn() -> void:
	print("[BattleMapManager3D] Fin du tour ennemi")
	current_turn += 1
	objective_module.check_objectives()
	change_phase(TurnPhase.PLAYER_TURN)
	await get_tree().create_timer(0.5).timeout
	_start_player_turn()

func _on_end_turn_pressed() -> void:
	"""Bouton Fin de Tour"""
	_end_player_turn()

# ============================================================================
# PROCESS & INPUT 3D
# ============================================================================

func _process(delta: float) -> void:
	_process_camera_rotation(delta)
	_update_info_panel()

func _process_camera_rotation(delta: float) -> void:
	if is_camera_rotating:
		var angle_diff = camera_rotation_target - camera_rotation_current
		
		while angle_diff > 180:
			angle_diff -= 360
		while angle_diff < -180:
			angle_diff += 360
		
		if abs(angle_diff) < 0.1:
			camera_rotation_current = camera_rotation_target
			is_camera_rotating = false
		else:
			var rotation_step = CAMERA_ROTATION_SPEED * delta
			
			if abs(angle_diff) < rotation_step:
				camera_rotation_current = camera_rotation_target
				is_camera_rotating = false
			else:
				if angle_diff > 0:
					camera_rotation_current += rotation_step
				else:
					camera_rotation_current -= rotation_step
			
			while camera_rotation_current >= 360:
				camera_rotation_current -= 360
			while camera_rotation_current < 0:
				camera_rotation_current += 360
			
			_update_camera_position()

func _update_camera_position() -> void:
	var angle_rad = deg_to_rad(camera_rotation_current)
	camera_rig.rotation.y = angle_rad
	
	var cam_angle_rad = deg_to_rad(CAMERA_ANGLE)
	camera.position = Vector3(0, CAMERA_HEIGHT, CAMERA_DISTANCE)
	camera.rotation.x = -cam_angle_rad

func rotate_camera(degrees: float) -> void:
	camera_rotation_target += degrees
	while camera_rotation_target >= 360:
		camera_rotation_target -= 360
	while camera_rotation_target < 0:
		camera_rotation_target += 360
	is_camera_rotating = true

func _input(event: InputEvent) -> void:
	if not is_battle_active or  battle_state_machine.current_state  != "PLAYER_TURN":
		return
	
	# Rotation de la caméra
	if event.is_action_pressed("ui_home"):
		rotate_camera(-90)
	elif event.is_action_pressed("ui_end"):
		rotate_camera(90)
	
	# Clic souris pour sélection/action
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Ne pas traiter les clics si un menu est ouvert
		if not action_popup.visible and not duo_popup.visible:
			_handle_mouse_click(event.position)

# ============================================================================
# RAYCASTING & SÉLECTION 3D
# ============================================================================

func _handle_mouse_click(mouse_pos: Vector2) -> void:
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * mouse_ray_length
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collision_mask = 3
	
	var result = space_state.intersect_ray(query)
	
	if result:
		_handle_raycast_hit(result)

func _handle_raycast_hit(result: Dictionary) -> void:
	var collider = result.collider
	
	# Clic sur une unité
	if collider.has_meta("unit"):
		var unit = collider.get_meta("unit")
		
		if hovered_unit != unit:
			hovered_unit = unit
			_update_info_panel()
		
		_handle_unit_click(unit)
		return
	
	if hovered_unit != null:
		hovered_unit = null
		_update_info_panel()
	
	# Clic sur le terrain
	if collider is StaticBody3D:
		var mesh_parent = collider.get_parent()
		if mesh_parent.has_meta("grid_position"):
			var grid_pos = mesh_parent.get_meta("grid_position")
			_handle_terrain_click(grid_pos)

func _handle_unit_click(unit: BattleUnit3D) -> void:
	if unit.is_player_unit:
		# Clic sur unité alliée
		if current_action_state == ActionState.CHOOSING_DUO:
			# En train de choisir un partenaire de duo
			_select_duo_partner(unit)
		else:
			# Sélection normale
			_select_unit(unit)
	elif selected_unit and selected_unit.can_act():
		# Clic sur unité ennemie pendant mode attaque
		if current_action_state == ActionState.SHOWING_ATTACK:
			_attack_unit(selected_unit, unit)

func _handle_terrain_click(grid_pos: Vector2i) -> void:
	if not selected_unit or current_action_state != ActionState.SHOWING_MOVE:
		return
	
	if movement_module.can_move_to(selected_unit, grid_pos):
		var cmd = MoveUnitCommand.new(selected_unit, grid_pos, unit_manager)
		command_history.execute_command(cmd)
		selected_unit.movement_used = true
		_close_all_menus()
		_deselect_unit()

# ============================================================================
# PANEL D'INFORMATION (BAS DROITE)
# ============================================================================

func _update_info_panel() -> void:
	"""Met à jour le panel d'information en bas à droite"""
	
	# Priorité 1 : Unité survolée
	if hovered_unit and hovered_unit != selected_unit:
		_display_unit_info(hovered_unit)
		return
	
	# Priorité 2 : Unité sélectionnée
	if selected_unit:
		_display_unit_info(selected_unit)
		return
	
	# Priorité 3 : Info de terrain
	_display_terrain_info()

func _display_unit_info(unit: BattleUnit3D) -> void:
	"""Affiche les infos d'une unité dans le panel"""
	info_unit_name_label.text = unit.unit_name
	info_class_label.text = "Classe: " + unit.get_meta("class", "Guerrier")
	
	info_hp_value.text = "%d/%d" % [unit.current_hp, unit.max_hp]
	info_atk_value.text = str(unit.attack_power)
	info_def_value.text = str(unit.defense_power)
	info_mov_value.text = str(unit.movement_range)
	
	# Couleur selon HP
	var hp_percent = unit.get_hp_percentage()
	if hp_percent > 0.6:
		info_hp_value.add_theme_color_override("font_color", Color.GREEN)
	elif hp_percent > 0.3:
		info_hp_value.add_theme_color_override("font_color", Color.YELLOW)
	else:
		info_hp_value.add_theme_color_override("font_color", Color.RED)

func _display_terrain_info() -> void:
	"""Affiche les infos de terrain quand aucune unité n'est sélectionnée"""
	
	# ✅ CORRECTION : Vérifier que le terrain est chargé
	if not terrain_module:
		info_unit_name_label.text = "[Chargement...]"
		info_class_label.text = ""
		info_hp_value.text = "--"
		info_atk_value.text = "--"
		info_def_value.text = "--"
		info_mov_value.text = "--"
		return
	
	# Trouver la tuile sous la souris (ou tuile par défaut)
	var grid_pos = _get_mouse_grid_position()
	
	if not terrain_module.is_in_bounds(grid_pos):
		grid_pos = Vector2i(0, 0)  # Première tuile par défaut
	
	var tile_type = terrain_module.get_tile_type(grid_pos)
	var tile_name = TerrainModule3D.TileType.keys()[tile_type]
	
	info_unit_name_label.text = "[Terrain]"
	info_class_label.text = "Type: " + tile_name
	
	var move_cost = terrain_module.get_movement_cost(grid_pos)
	var defense_bonus = terrain_module.get_defense_bonus(grid_pos)
	
	info_hp_value.text = "Coût: " + ("∞" if move_cost == INF else str(move_cost))
	info_atk_value.text = "--"
	info_def_value.text = "+" + str(defense_bonus)
	info_mov_value.text = "--"
	
	info_hp_value.add_theme_color_override("font_color", Color.WHITE)

func _get_mouse_grid_position() -> Vector2i:
	"""Retourne la position de grille sous la souris"""
	
	# ✅ CORRECTION : Vérifier que terrain_module existe
	if not terrain_module:
		return Vector2i(-1, -1)
	
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * mouse_ray_length
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collision_mask = 1  # Terrain uniquement
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider is StaticBody3D:
		var mesh_parent = result.collider.get_parent()
		if mesh_parent.has_meta("grid_position"):
			return mesh_parent.get_meta("grid_position")
	
	return Vector2i(-1, -1)

# ============================================================================
# SÉLECTION D'UNITÉ & MENU D'ACTIONS
# ============================================================================

func _select_unit(unit: BattleUnit3D) -> void:
	if selected_unit == unit:
		return
	
	if selected_unit:
		_deselect_unit()
	
	selected_unit = unit
	selected_unit.set_selected(true)
	unit_selected.emit(unit)
	
	# Ouvrir le menu d'actions
	_open_action_menu()
	
	current_action_state = ActionState.UNIT_SELECTED
	print("[BattleMapManager3D] Unité sélectionnée: ", unit.unit_name)

func _deselect_unit() -> void:
	if selected_unit:
		selected_unit.set_selected(false)
		selected_unit = null
		duo_partner = null
		unit_deselected.emit()
		terrain_module.clear_all_highlights()
		_close_all_menus()
		current_action_state = ActionState.IDLE

# ============================================================================
# MENU D'ACTIONS
# ============================================================================

func _open_action_menu() -> void:
	if not selected_unit:
		return
	
	# Positionner le menu près de l'unité sélectionnée
	var screen_pos = camera.unproject_position(selected_unit.position)
	action_popup.position = screen_pos + Vector2(50, -100)
	
	# Activer/désactiver les boutons selon l'état de l'unité
	move_button.disabled = not selected_unit.can_move()
	attack_button.disabled = not selected_unit.can_act()
	defend_button.disabled = not selected_unit.can_act()
	abilities_button.disabled = not selected_unit.can_act() or selected_unit.abilities.is_empty()
	
	action_popup.popup()

func _close_all_menus() -> void:
	action_popup.hide()
	duo_popup.hide()
	terrain_module.clear_all_highlights()

# ============================================================================
# ACTIONS DU MENU
# ============================================================================

func _on_move_pressed() -> void:
	if not selected_unit or not selected_unit.can_move():
		return
	
	action_popup.hide()
	current_action_state = ActionState.SHOWING_MOVE
	
	# Afficher les cases accessibles
	var reachable = movement_module.calculate_reachable_positions(selected_unit)
	terrain_module.highlight_tiles(reachable, MOVEMENT_COLOR)
	
	print("[BattleMapManager3D] Mode déplacement activé")

# scenes/battle/battle_map_manager_3d.gd
# MODIFIER _on_attack_pressed() :

func _on_attack_pressed() -> void:
	if not selected_unit or not selected_unit.can_act():
		return
	
	action_popup.hide()
	
	# Vérifier si l'unité est déjà en duo
	if duo_system.is_unit_in_duo(selected_unit):
		var duo_data = duo_system.get_duo_for_unit(selected_unit)
		duo_partner = duo_data.support if duo_data.leader == selected_unit else duo_data.leader
		print("[Battle] ✅ Duo existant utilisé")
		_show_attack_range()
	else:
		# Ouvrir le menu de sélection de duo
		_open_duo_selection_menu()

# MODIFIER _select_duo_partner() :


func _on_defend_pressed() -> void:
	if not selected_unit or not selected_unit.can_act():
		return
	
	print("[BattleMapManager3D] Défense (à implémenter)")
	selected_unit.action_used = true
	selected_unit.defense_power = int(selected_unit.defense_power * 1.5)
	_close_all_menus()
	_deselect_unit()

func _on_abilities_pressed() -> void:
	if not selected_unit or not selected_unit.can_act():
		return
	
	print("[BattleMapManager3D] Capacités (à implémenter)")
	_close_all_menus()

func _on_items_pressed() -> void:
	print("[BattleMapManager3D] Objets (à implémenter)")
	_close_all_menus()

func _on_wait_action_pressed() -> void:
	if not selected_unit:
		return
	
	# L'unité passe son tour
	selected_unit.movement_used = true
	selected_unit.action_used = true
	_close_all_menus()
	_deselect_unit()

func _on_cancel_action_pressed() -> void:
	_close_all_menus()
	current_action_state = ActionState.IDLE

# ============================================================================
# SYSTÈME DE DUO
# ============================================================================

func _open_duo_selection_menu() -> void:
	if not selected_unit:
		return
	
	# ✅ NOUVEAU : Vérifier si attaque solo est possible
	var allies = unit_manager.get_alive_player_units()
	var can_duo = allies.size() > 1  # Au moins 2 alliés vivants
	
	# Nettoyer le container des boutons précédents - ✅ CORRIGER ICI
	for child in duo_options_container.get_children():  # ← Changé de duo_units_container à duo_options_container
		child.queue_free()
	
	if can_duo:
		# Créer boutons pour chaque allié
		var duo_candidates: Array[BattleUnit3D] = []
		
		for ally in allies:
			if ally == selected_unit:
				continue
			
			var distance = terrain_module.get_distance(selected_unit.grid_position, ally.grid_position)
			if distance <= 3:
				duo_candidates.append(ally)
		
		for candidate in duo_candidates:
			var button = Button.new()
			button.text = "👥 " + candidate.unit_name
			button.custom_minimum_size = Vector2(180, 40)
			button.pressed.connect(func(): _select_duo_partner(candidate))
			duo_options_container.add_child(button)  # ← Changé de duo_units_container à duo_options_container
	
	# ✅ Bouton solo (toujours disponible) - CORRIGER ICI
	solo_button_duo.visible = true  # ← Changé de solo_button à solo_button_duo
	solo_button_duo.text = "🚶 Attaquer Seul" if can_duo else "⚔️ Attaquer"  # ← Changé
	
	# Positionner et afficher
	var screen_pos = camera.unproject_position(selected_unit.position)
	duo_popup.position = screen_pos + Vector2(50, -200)
	duo_popup.popup()
	
	current_action_state = ActionState.CHOOSING_DUO
func _on_duo_option_hovered(partner: BattleUnit3D) -> void:
	"""Mise à jour de la carte Support au survol"""
	support_mini_card.setup_from_unit(partner)

func _on_duo_option_selected(
	partner: BattleUnit3D, 
	ring_combo: Dictionary
) -> void:
	"""Option de duo sélectionnée"""
	
	# Former le duo
	var success = duo_system.try_form_duo(selected_unit, partner)
	
	if not success:
		EventBus.notify("Impossible de former ce duo", "error")
		return
	
	# Stocker le partenaire et la combinaison d'anneaux
	duo_partner = partner
	current_attack_profile = ring_combo  # Stocker pour utilisation ultérieure
	
	# Fermer le popup et afficher la portée d'attaque
	duo_popup.hide()
	_show_attack_range()
	
	EventBus.notify(
		"Duo formé : %s + %s" % [selected_unit.unit_name, partner.unit_name],
		"info"
	)

func _clear_duo_options() -> void:
	"""Nettoie toutes les options de duo"""
	for child in duo_options_container.get_children():
		child.queue_free()

func _select_duo_partner(partner: BattleUnit3D) -> void:
	if partner == selected_unit:
		return
	
	# ✅ NOUVEAU : Utiliser DuoSystem
	if duo_system.try_form_duo(selected_unit, partner):
		duo_partner = partner
		duo_popup.hide()
		_show_attack_range()
		
		print("[Battle] ✅ Duo formé via DuoSystem")
	else:
		EventBus.notify("Impossible de former ce duo", "warning")

func _on_solo_attack_pressed() -> void:
	"""Attaque solo sans duo"""
	duo_popup.hide()
	duo_partner = null
	_show_attack_range()

func _on_cancel_duo_pressed() -> void:
	"""Annuler la formation de duo"""
	duo_popup.hide()
	current_action_state = ActionState.UNIT_SELECTED
	_open_action_menu() 

func _show_attack_range() -> void:
	if not selected_unit:
		return
	
	current_action_state = ActionState.SHOWING_ATTACK
	
	# Afficher les cases d'attaque
	var attack_positions = action_module.get_attack_positions(selected_unit)
	terrain_module.highlight_tiles(attack_positions, ATTACK_COLOR)
	
	print("[BattleMapManager3D] Portée d'attaque affichée")

# ============================================================================
# ACTIONS DE COMBAT
# ============================================================================

func _attack_unit(attacker: BattleUnit3D, target: BattleUnit3D) -> void:
	if not action_module.can_attack(attacker, target):
		return
	
	current_action_state = ActionState.EXECUTING_ACTION
	
	# Si duo, notifier le système
	if duo_partner:
		EventBus.form_duo(attacker, duo_partner)
		print("[BattleMapManager3D] Attaque en duo!")
	
	await action_module.execute_attack(attacker, target)
	attacker.action_used = true
	
	if duo_partner:
		EventBus.break_duo(attacker, duo_partner)
	
	_close_all_menus()
	_deselect_unit()

# ============================================================================
# CALLBACKS
# ============================================================================

func _on_unit_died(unit: BattleUnit3D) -> void:
	print("[BattleMapManager3D] Unité morte: ", unit.unit_name)
	EventBus.unit_died.emit(unit)
	stats_tracker.record_death(unit)
	_check_battle_end()

func _on_unit_moved(unit: BattleUnit3D, from: Vector2i, to: Vector2i) -> void:
	json_scenario_module.trigger_position_event(unit, to)
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
	duo_system.clear_all_duos()
	if victory:
		_award_xp_to_survivors()
	
	if json_scenario_module.has_outro():
		change_phase(TurnPhase.CUTSCENE)
		await json_scenario_module.play_outro(victory)
	
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

func _award_xp_to_survivors() -> void:
	var player_units = unit_manager.get_alive_player_units()
	var xp_per_unit = 50 + (current_turn * 10)  # Formule simple
	
	for unit in player_units:
		unit.award_xp(xp_per_unit)

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
# NETTOYAGE
# ============================================================================

func _exit_tree() -> void:
	EventBus.disconnect_all(self)
	print("[BattleMapManager3D] Nettoyé")
	
func _on_battle_state_changed(from: String, to: String) -> void:
	print("[BattleMapManager] État : ", from, " → ", to)
	phase_label.text = "Phase: " + to

func _on_undo_pressed() -> void:
	if command_history.can_undo():
		command_history.undo()
		
func _connect_duo_signals() -> void:
	duo_system.duo_formed.connect(_on_duo_formed)
	duo_system.duo_broken.connect(_on_duo_broken)
	duo_system.duo_validation_failed.connect(_on_duo_validation_failed)
	
	
	
func _on_duo_formed(duo_data: Dictionary) -> void:
	var leader = duo_data.leader as BattleUnit3D
	var support = duo_data.support as BattleUnit3D
	
	print("[Battle] 👥 Duo formé : ", leader.unit_name, " + ", support.unit_name)
	EventBus.notify("Duo formé : " + leader.unit_name + " + " + support.unit_name, "success")

func _on_duo_broken(duo_id: String) -> void:
	print("[Battle] 💔 Duo rompu : ", duo_id)

func _on_duo_validation_failed(reason: String) -> void:
	EventBus.notify("Formation de duo impossible : " + reason, "warning")
	
func _get_unit_equipped_rings(unit: BattleUnit3D) -> Array:
	"""
	Récupère les anneaux équipés par une unité
	
	Retourne un Array de Dictionary :
	[
		{
			"channeling_ring_id": "chan_fire",
			"channeling_ring_name": "Anneau de Feu",
			"channeling_icon": "res://...",
			"materialization_ring_id": "mat_basic_line",
			"materialization_ring_name": "Lame Basique",
			"materialization_icon": "res://..."
		}
	]
	"""
	
	var combos = []
	
	# Méthode 1 : Via RingSystem (si implémenté)
	if ring_system:
		var rings = ring_system.get_unit_rings(unit.unit_id)
		
		if rings.has("mat") and rings.has("chan"):
			var mat_ring = ring_system.get_materialization_ring(rings["mat"])
			var chan_ring = ring_system.get_channeling_ring(rings["chan"])
			
			combos.append({
				"channeling_ring_id": chan_ring.ring_id,
				"channeling_ring_name": chan_ring.ring_name,
				"channeling_icon": _get_ring_icon(chan_ring),
				"materialization_ring_id": mat_ring.ring_id,
				"materialization_ring_name": mat_ring.ring_name,
				"materialization_icon": _get_ring_icon(mat_ring)
			})
	
	# Méthode 2 : Via metadata de l'unité (fallback)
	if combos.is_empty():
		# Données par défaut (à personnaliser)
		combos.append({
			"channeling_ring_id": "chan_fire",
			"channeling_ring_name": "Feu Basique",
			"channeling_icon": "",
			"materialization_ring_id": "mat_basic_line",
			"materialization_ring_name": "Lame Basique",
			"materialization_icon": ""
		})
	
	return combos

func _find_potential_duo_partners(leader: BattleUnit3D) -> Array[BattleUnit3D]:
	"""Trouve les partenaires potentiels pour un duo"""
	
	var partners: Array[BattleUnit3D] = []
	var all_units = unit_manager.get_alive_player_units()
	
	for unit in all_units:
		if unit == leader:
			continue
		
		if duo_system.is_unit_in_duo(unit):
			continue
		
		var distance = terrain_module.get_distance(
			leader.grid_position,
			unit.grid_position
		)
		
		if distance <= 3:  # Distance max pour duo
			partners.append(unit)
	
	return partners

func _get_ring_icon(ring: RingSystem) -> String:
	"""Retourne l'icône de l'anneau ou une chaîne vide"""
	if ring.has("icon"):
		return ring.icon
	return ""
