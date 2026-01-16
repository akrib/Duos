extends Node2D
## World Map - Carte du monde interactive
## Point central de navigation entre les différentes zones du jeu

class_name WorldMap

# Références UI
@onready var camera: Camera2D = $Camera2D
@onready var info_label: Label = $UI/BottomBar/MarginContainer/HBoxContainer/InfoLabel
@onready var party_button: Button = $UI/BottomBar/MarginContainer/HBoxContainer/ButtonsContainer/PartyButton
@onready var inventory_button: Button = $UI/BottomBar/MarginContainer/HBoxContainer/ButtonsContainer/InventoryButton
@onready var menu_button: Button = $UI/BottomBar/MarginContainer/HBoxContainer/ButtonsContainer/MenuButton
@onready var notification_panel: PanelContainer = $UI/NotificationPanel
@onready var notification_label: Label = $UI/NotificationPanel/MarginContainer/NotificationLabel
@onready var astraeon_label: Label = $UI/TopBar/MarginContainer/HBoxContainer/DivinityPanel/AstraeonLabel
@onready var kharvul_label: Label = $UI/TopBar/MarginContainer/HBoxContainer/DivinityPanel/KharvulLabel
@onready var debug_info: Label = $UI/DebugInfo

# Zones interactives
@onready var town1_area: Area2D = $InteractionAreas/Town1Area
@onready var castle_area: Area2D = $InteractionAreas/CastleArea
@onready var town2_area: Area2D = $InteractionAreas/Town2Area
@onready var battle_area: Area2D = $InteractionAreas/BattleArea

# État
var camera_velocity: Vector2 = Vector2.ZERO
var camera_drag_start: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var selected_location: String = ""

# Statistiques divines
var divine_points: Dictionary = {
	"Astraeon": 0,
	"Kharvûl": 0
}

# Paramètres de navigation
const CAMERA_SPEED: float = 400.0
const CAMERA_ZOOM_SPEED: float = 0.1
const MIN_ZOOM: float = 0.5
const MAX_ZOOM: float = 1.5

func _ready() -> void:
	# Connexions aux événements
	_connect_to_event_bus()
	
		# AJOUT : Rendre les zones visibles en mode debug
	if OS.is_debug_build():
		_make_areas_visible()
	
	# Afficher le mode debug si activé
	debug_info.visible = OS.is_debug_build()
	
	# Message de bienvenue
	show_notification("Bienvenue sur la carte du monde !", 3.0)
	
	print("[WorldMap] Carte du monde initialisée")

## Auto-connexion des signaux via SceneLoader
func _get_signal_connections() -> Array:
	"""
	Retourne les connexions de signaux pour SceneLoader
	"""
	if not is_node_ready():
		return []
	
	return [
		{
			"source": party_button,
			"signal_name": "pressed",
			"target": self,
			"method": "_on_party_pressed"
		},
		{
			"source": inventory_button,
			"signal_name": "pressed",
			"target": self,
			"method": "_on_inventory_pressed"
		},
		{
			"source": menu_button,
			"signal_name": "pressed",
			"target": self,
			"method": "_on_menu_pressed"
		},
		{
			"source": town1_area,
			"signal_name": "input_event",
			"target": self,
			"method": "_on_town1_clicked"
		},
		{
			"source": castle_area,
			"signal_name": "input_event",
			"target": self,
			"method": "_on_castle_clicked"
		},
		{
			"source": town2_area,
			"signal_name": "input_event",
			"target": self,
			"method": "_on_town2_clicked"
		},
		{
			"source": battle_area,
			"signal_name": "input_event",
			"target": self,
			"method": "_on_battle_clicked"
		},
	]

# ============================================================================
# CONNEXIONS EVENTBUS
# ============================================================================

func _connect_to_event_bus() -> void:
	"""Connexion aux événements globaux"""
	EventBus.safe_connect("notification_posted", _on_notification_posted)
	EventBus.safe_connect("divine_points_gained", _on_divine_points_gained)
	EventBus.safe_connect("battle_ended", _on_battle_ended)
	EventBus.safe_connect("location_discovered", _on_location_discovered)

# ============================================================================
# PROCESS & INPUT
# ============================================================================

func _process(delta: float) -> void:
	# Navigation au clavier (WASD / Flèches)
	_handle_keyboard_navigation(delta)
	
	# Mise à jour du debug
	if OS.is_debug_build():
		_update_debug_info()

func _input(event: InputEvent) -> void:
	# Zoom avec la molette
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(CAMERA_ZOOM_SPEED)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(-CAMERA_ZOOM_SPEED)
		
		# Drag de la caméra
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_dragging = true
				camera_drag_start = event.position
			else:
				is_dragging = false
	
	elif event is InputEventMouseMotion and is_dragging:
		var delta_pos = (event.position - camera_drag_start) / camera.zoom.x
		camera.position -= delta_pos
		camera_drag_start = event.position
	
	# Raccourci menu (ESC)
	if event.is_action_pressed("ui_cancel"):
		_on_menu_pressed()

func _handle_keyboard_navigation(delta: float) -> void:
	"""Navigation de la caméra au clavier"""
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	
	if direction != Vector2.ZERO:
		camera.position += direction.normalized() * CAMERA_SPEED * delta

# ============================================================================
# CAMÉRA
# ============================================================================

func _zoom_camera(zoom_delta: float) -> void:
	"""Zoom de la caméra"""
	var new_zoom = camera.zoom.x + zoom_delta
	new_zoom = clamp(new_zoom, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = Vector2(new_zoom, new_zoom)

func move_camera_to(target_position: Vector2, duration: float = 1.0) -> void:
	"""Déplace la caméra vers une position avec animation"""
	var tween = create_tween()
	tween.tween_property(camera, "position", target_position, duration).set_ease(Tween.EASE_IN_OUT)

# ============================================================================
# INTERACTIONS AVEC LES ZONES
# ============================================================================

func _on_town1_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	"""Clic sur le Village du Nord"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_location("Village du Nord", town1_area.position)

func _on_castle_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	"""Clic sur le Château Royal"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_location("Château Royal", castle_area.position)

func _on_town2_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	"""Clic sur le Port de l'Est"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_location("Port de l'Est", town2_area.position)

# func _on_battle_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
#	"""Clic sur la Zone de Combat"""
#	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
#		select_location("Zone de Combat", battle_area.position)


# func _on_forest_battle_clicked() -> void:
func _on_battle_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	"""Quand le joueur clique sur une zone de combat dans la forêt"""
	
	# Préparer les données du combat
	var battle_data = _create_forest_battle_data()
	
	# Notifier l'EventBus et charger la scène de combat
	EventBus.start_battle(battle_data)
	EventBus.change_scene(SceneRegistry.SceneID.BATTLE)

func _create_forest_battle_data() -> Dictionary:
	"""Crée les données pour un combat en forêt"""
	
	return {
		# Identifiant unique
		"battle_id": "forest_battle_" + str(Time.get_unix_time_from_system()),
		
		# Terrain (preset ou personnalisé)
		"terrain": "forest",
		
		# Unités du joueur
		"player_units": [
			{
				"name": "Sir Gaheris",
				"position": Vector2i(3, 7),
				"stats": {
					"hp": 120,
					"attack": 28,
					"defense": 22,
					"movement": 4,
					"range": 1
				},
				"abilities": ["Shield Bash", "Defend"],
				"color": Color(0.2, 0.3, 0.8)
			},
			{
				"name": "Elara l'Archère",
				"position": Vector2i(4, 6),
				"stats": {
					"hp": 85,
					"attack": 22,
					"defense": 12,
					"movement": 5,
					"range": 3
				},
				"abilities": ["Multi-Shot"],
				"color": Color(0.2, 0.7, 0.3)
			},
			{
				"name": "Père Aldric",
				"position": Vector2i(2, 8),
				"stats": {
					"hp": 95,
					"attack": 15,
					"defense": 18,
					"movement": 4,
					"range": 2
				},
				"abilities": ["Heal"],
				"color": Color(0.8, 0.8, 0.3)
			}
		],
		
		# Unités ennemies
		"enemy_units": [
			{
				"name": "Chef Gobelin",
				"position": Vector2i(15, 8),
				"stats": {
					"hp": 90,
					"attack": 25,
					"defense": 15,
					"movement": 5,
					"range": 1
				},
				"abilities": [],
				"color": Color(0.9, 0.2, 0.2)
			},
			{
				"name": "Gobelin Guerrier",
				"position": Vector2i(16, 7),
				"stats": {
					"hp": 60,
					"attack": 20,
					"defense": 10,
					"movement": 5,
					"range": 1
				},
				"color": Color(0.7, 0.2, 0.2)
			},
			{
				"name": "Gobelin Guerrier",
				"position": Vector2i(16, 9),
				"stats": {
					"hp": 60,
					"attack": 20,
					"defense": 10,
					"movement": 5,
					"range": 1
				},
				"color": Color(0.7, 0.2, 0.2)
			},
			{
				"name": "Gobelin Archer",
				"position": Vector2i(18, 8),
				"stats": {
					"hp": 45,
					"attack": 18,
					"defense": 6,
					"movement": 4,
					"range": 3
				},
				"color": Color(0.8, 0.3, 0.2)
			},
			{
				"name": "Shaman Gobelin",
				"position": Vector2i(19, 7),
				"stats": {
					"hp": 55,
					"attack": 22,
					"defense": 8,
					"movement": 4,
					"range": 2
				},
				"abilities": ["Heal"],
				"color": Color(0.6, 0.2, 0.6)
			}
		],
		
		# Objectifs
		"objectives": {
			"primary": [
				{
					"type": "defeat_all_enemies",
					"description": "Éliminez tous les gobelins"
				}
			],
			"secondary": [
				{
					"type": "survive_turns",
					"turns": 10,
					"description": "Survivez sans perdre d'unité"
				}
			]
		},
		
		# Scénario
		"scenario": {
			# Dialogue d'introduction
			"intro_dialogue": [
				{"speaker": "Sir Gaheris", "text": "Une embuscade gobeline ! En formation !"},
				{"speaker": "Elara", "text": "Leur chef est là-bas. Si on l'élimine, les autres fuiront !"},
				{"speaker": "Père Aldric", "text": "Que la lumière nous protège. Je veillerai sur vous."}
			],
			
			# Dialogue de victoire
			"outro_victory": [
				{"speaker": "Sir Gaheris", "text": "Victoire ! Bien joué, compagnons."},
				{"speaker": "Elara", "text": "Leur camp ne devrait plus être loin."}
			],
			
			# Dialogue de défaite
			"outro_defeat": [
				{"speaker": "Sir Gaheris", "text": "Retraite ! Nous reviendrons mieux préparés !"}
			],
			
			# Événements pendant le combat
			"turn_events": {
				# Au tour 3, renforts ennemis
				3: {
					"type": "dialogue",
					"text": "Des renforts gobelins arrivent depuis la forêt !"
				},
				
				# Au tour 5, trésor découvert
				5: {
					"type": "dialogue",
					"text": "Une lueur étrange émane d'un arbre creux..."
				}
			},
			
			# Événements de position
			"position_events": {
				# Trésor caché
				"12,10": {
					"type": "treasure",
					"item": "Potion de Soin",
					"text": "Vous avez trouvé une Potion de Soin !"
				}
			}
		},
		
		# Autres paramètres
		"difficulty": "normal",
		"music": "res://audio/music/battle_forest.ogg"
	}



func select_location(location_name: String, position: Vector2) -> void:
	"""Sélectionne une location et propose d'y voyager"""
	selected_location = location_name
	info_label.text = "Voyager vers : " + location_name + " ? (Appuyez sur Entrée)"
	
	# Centrer la caméra sur la location
	move_camera_to(position, 0.8)
	
	print("[WorldMap] Location sélectionnée : ", location_name)

func travel_to_selected_location() -> void:
	"""Voyage vers la location sélectionnée"""
	if selected_location == "":
		return
	
	show_notification("Voyage vers " + selected_location + "...", 2.0)
	
	# Router vers la scène appropriée
	match selected_location:
		"Village du Nord":
			EventBus.notify("Village du Nord (scène à créer)", "info")
			# EventBus.change_scene(SceneRegistry.SceneID.TOWN)
		
		"Château Royal":
			EventBus.notify("Château Royal (scène à créer)", "info")
			# EventBus.change_scene(SceneRegistry.SceneID.CASTLE)
		
		"Port de l'Est":
			EventBus.notify("Port de l'Est (scène à créer)", "info")
			# EventBus.change_scene(SceneRegistry.SceneID.TOWN)
		
		"Zone de Combat":
			# Préparer les données de combat
			var battle_data = {
				"location": "Northern Plains",
				"enemy_count": 6,
				"difficulty": "normal"
			}
			EventBus.start_battle(battle_data)
			EventBus.change_scene(SceneRegistry.SceneID.BATTLE)
	
	selected_location = ""

# ============================================================================
# UI CALLBACKS
# ============================================================================

func _on_party_pressed() -> void:
	"""Ouvrir le menu de l'équipe"""
	print("[WorldMap] Menu Équipe")
	show_notification("Menu Équipe (à implémenter)", 2.0)

func _on_inventory_pressed() -> void:
	"""Ouvrir l'inventaire"""
	print("[WorldMap] Inventaire")
	show_notification("Inventaire (à implémenter)", 2.0)

func _on_menu_pressed() -> void:
	"""Ouvrir le menu pause"""
	print("[WorldMap] Menu Pause")
	EventBus.game_paused.emit(true)
	show_notification("Menu Pause (à implémenter)", 2.0)
	# EventBus.change_scene(SceneRegistry.SceneID.PAUSE_MENU)

# ============================================================================
# NOTIFICATIONS
# ============================================================================

func show_notification(message: String, duration: float = 2.0) -> void:
	"""Affiche une notification temporaire"""
	notification_label.text = message
	notification_panel.visible = true
	notification_panel.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(notification_panel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(duration)
	tween.tween_property(notification_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): notification_panel.visible = false)

func _on_notification_posted(message: String, type: String) -> void:
	"""Callback pour les notifications via EventBus"""
	var duration = 2.0
	if type == "warning":
		duration = 3.0
	elif type == "error":
		duration = 4.0
	
	show_notification(message, duration)

# ============================================================================
# SYSTÈME DIVIN
# ============================================================================

func _on_divine_points_gained(god_name: String, points: int) -> void:
	"""Mise à jour des points divins"""
	if divine_points.has(god_name):
		divine_points[god_name] += points
		_update_divine_ui()
		
		print("[WorldMap] +", points, " points pour ", god_name)

func _update_divine_ui() -> void:
	"""Met à jour l'affichage des points divins"""
	astraeon_label.text = "⚖ Astraeon: " + str(divine_points["Astraeon"])
	kharvul_label.text = "⚡ Kharvûl: " + str(divine_points["Kharvûl"])

# ============================================================================
# CALLBACKS EVENTBUS
# ============================================================================

func _on_battle_ended(results: Dictionary) -> void:
	"""Réaction à la fin d'un combat"""
	print("[WorldMap] Combat terminé : ", results)
	
	if results.get("victory", false):
		show_notification("Victoire ! +" + str(results.get("rewards", {}).get("gold", 0)) + " or", 3.0)
	elif results.get("retreat", false):
		show_notification("Retraite réussie", 2.0)
	else:
		show_notification("Défaite...", 2.0)

func _on_location_discovered(location_name: String) -> void:
	"""Nouvelle location découverte"""
	print("[WorldMap] Location découverte : ", location_name)
	show_notification("Nouvelle zone découverte : " + location_name, 3.0)

# ============================================================================
# DEBUG
# ============================================================================

func _update_debug_info() -> void:
	"""Met à jour les informations de debug"""
	debug_info.text = "[DEBUG]\n"
	debug_info.text += "Camera: (" + str(int(camera.position.x)) + ", " + str(int(camera.position.y)) + ")\n"
	debug_info.text += "Zoom: " + str(snappedf(camera.zoom.x, 0.01)) + "\n"
	debug_info.text += "Selected: " + selected_location

# ============================================================================
# NETTOYAGE
# ============================================================================

func _exit_tree() -> void:
	"""Nettoyage à la fermeture de la scène"""
	EventBus.disconnect_all(self)
	print("[WorldMap] Scène nettoyée")


func _make_areas_visible() -> void:
	"""Rend les zones cliquables visibles en mode debug"""
	for area in [town1_area, castle_area, town2_area, battle_area]:
		# Créer un ColorRect pour visualiser la zone
		var visual = ColorRect.new()
		visual.size = Vector2(100, 100)
		visual.position = -visual.size / 2
		visual.color = Color(1, 0, 0, 0.3)  # Rouge transparent
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Ne pas bloquer les clics
		area.add_child(visual)
		
		# Ajouter un label avec le nom
		var label = Label.new()
		label.text = area.name
		label.position = Vector2(-50, 60)
		label.add_theme_color_override("font_color", Color.YELLOW)
		area.add_child(label)
