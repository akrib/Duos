# scenes/world/world_map.gd
extends Node2D
## World Map - Carte du monde pilotée par Lua
## VERSION 2.0 : Génération dynamique depuis Lua

class_name WorldMap

# ============================================================================
# RÉFÉRENCES
# ============================================================================

@onready var camera: Camera2D = $Camera2D
@onready var ui_layer: CanvasLayer = $UI
@onready var locations_container: Node2D = $LocationsContainer
@onready var connections_container: Node2D = $ConnectionsContainer
@onready var player_container: Node2D = $PlayerContainer

# Labels UI existants
@onready var info_label: Label = $UI/BottomBar/MarginContainer/HBoxContainer/InfoLabel
@onready var party_button: Button = $UI/BottomBar/MarginContainer/HBoxContainer/ButtonsContainer/PartyButton
@onready var inventory_button: Button = $UI/BottomBar/MarginContainer/HBoxContainer/ButtonsContainer/InventoryButton
@onready var menu_button: Button = $UI/BottomBar/MarginContainer/HBoxContainer/ButtonsContainer/MenuButton
@onready var notification_panel: PanelContainer = $UI/NotificationPanel
@onready var notification_label: Label = $UI/NotificationPanel/MarginContainer/NotificationLabel

# ============================================================================
# DONNÉES LUA
# ============================================================================

var world_map_data: Dictionary = {}
var locations: Dictionary = {}  # location_id -> WorldMapLocation
var player: WorldMapPlayer = null

# ============================================================================
# ÉTAT
# ============================================================================

var current_step: int = 0  # Progression du joueur
var selected_location: WorldMapLocation = null

# Menu d'actions
var action_menu: PopupPanel = null
var action_menu_container: VBoxContainer = null

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	_create_containers()
	_create_action_menu()
	_connect_ui_buttons()
	_load_world_map_data()
	_generate_map()
	_spawn_player()
	
	EventBus.safe_connect("notification_posted", _on_notification_posted)
	
	print("[WorldMap] ✅ Carte générée depuis Lua")

func _create_containers() -> void:
	"""Crée les containers si ils n'existent pas"""
	
	if not has_node("LocationsContainer"):
		locations_container = Node2D.new()
		locations_container.name = "LocationsContainer"
		add_child(locations_container)
	
	if not has_node("ConnectionsContainer"):
		connections_container = Node2D.new()
		connections_container.name = "ConnectionsContainer"
		add_child(connections_container)
	
	if not has_node("PlayerContainer"):
		player_container = Node2D.new()
		player_container.name = "PlayerContainer"
		add_child(player_container)

func _create_action_menu() -> void:
	"""Crée le menu d'actions (popup)"""
	
	action_menu = PopupPanel.new()
	action_menu.name = "ActionMenu"
	action_menu.visible = false
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	action_menu.add_child(margin)
	
	action_menu_container = VBoxContainer.new()
	action_menu_container.add_theme_constant_override("separation", 5)
	margin.add_child(action_menu_container)
	
	ui_layer.add_child(action_menu)

func _connect_ui_buttons() -> void:
	"""Connecte les boutons UI existants"""
	
	if party_button:
		party_button.pressed.connect(_on_party_pressed)
	if inventory_button:
		inventory_button.pressed.connect(_on_inventory_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

# ============================================================================
# CHARGEMENT DES DONNÉES LUA
# ============================================================================

func _load_world_map_data() -> void:
	"""Charge les données de la world map depuis Lua"""
	
	world_map_data = WorldMapDataLoader.load_world_map_data("world_map_data", true)
	
	if world_map_data.is_empty():
		push_error("[WorldMap] ❌ Impossible de charger les données de la carte")
		return
	
	print("[WorldMap] 📦 Données chargées : ", world_map_data.get("name", "???"))

# ============================================================================
# GÉNÉRATION DE LA CARTE
# ============================================================================

func _generate_map() -> void:
	"""Génère tous les éléments de la carte"""
	
	if world_map_data.is_empty():
		return
	
	# 1. Créer les locations
	_create_locations()
	
	# 2. Créer les connexions
	_create_connections()
	
	print("[WorldMap] ✅ Carte générée : ", locations.size(), " locations")

func _create_locations() -> void:
	"""Crée toutes les locations sur la carte"""
	
	var locations_data = world_map_data.get("locations", [])
	
	for location_data in locations_data:
		var location = WorldMapLocation.new()
		location.setup(location_data)
		
		# Vérifier si déverrouillée
		var unlocked = location_data.get("unlocked_at_step", 0) <= current_step
		location.set_unlocked(unlocked)
		
		# Signaux
		location.clicked.connect(_on_location_clicked)
		location.hovered.connect(_on_location_hovered)
		location.unhovered.connect(_on_location_unhovered)
		
		locations_container.add_child(location)
		locations[location_data.id] = location

func _create_connections() -> void:
	"""Crée les lignes entre les locations"""
	
	var visual_config = world_map_data.get("connections_visual", {})
	var line_color = Color(0.7, 0.7, 0.7, 0.6)
	var line_color_locked = Color(0.3, 0.3, 0.3, 0.3)
	var line_width = 3.0
	
	if visual_config.has("color"):
		var c = visual_config.color
		line_color = Color(c.get("r", 0.7), c.get("g", 0.7), c.get("b", 0.7), c.get("a", 0.6))
	
	if visual_config.has("color_locked"):
		var c = visual_config.color_locked
		line_color_locked = Color(c.get("r", 0.3), c.get("g", 0.3), c.get("b", 0.3), c.get("a", 0.3))
	
	if visual_config.has("width"):
		line_width = visual_config.width
	
	# Parcourir toutes les locations
	for location_id in locations:
		var location = locations[location_id]
		var connections = location.get_connections()
		
		for target_id in connections:
			if not locations.has(target_id):
				continue
			
			var target_location = locations[target_id]
			
			# Ne créer qu'une seule ligne par paire (éviter doublons)
			if location_id > target_id:
				continue
			
			# Créer la ligne
			var line = Line2D.new()
			line.add_point(location.position)
			line.add_point(target_location.position)
			line.width = line_width
			
			# Couleur selon si les deux locations sont déverrouillées
			if location.is_unlocked and target_location.is_unlocked:
				line.default_color = line_color
			else:
				line.default_color = line_color_locked
			
			# Pointillés
			if visual_config.has("dash_length"):
				line.default_color.a *= 0.8  # Un peu plus transparent
			
			connections_container.add_child(line)

# ============================================================================
# JOUEUR
# ============================================================================

func _spawn_player() -> void:
	"""Spawn le sprite du joueur sur la carte"""
	
	player = WorldMapPlayer.new()
	player_container.add_child(player)
	
	# Configuration depuis Lua
	var player_config = world_map_data.get("player", {})
	player.setup(player_config)
	
	# Placer à la location de départ
	var start_location_id = player_config.get("start_location", "")
	
	if locations.has(start_location_id):
		player.set_location(locations[start_location_id])
	else:
		push_warning("[WorldMap] Location de départ introuvable : ", start_location_id)
		# Fallback : première location déverrouillée
		for loc_id in locations:
			if locations[loc_id].is_unlocked:
				player.set_location(locations[loc_id])
				break
	
	# Signaux
	player.movement_completed.connect(_on_player_movement_completed)

# ============================================================================
# INTERACTIONS AVEC LES LOCATIONS
# ============================================================================

func _on_location_clicked(location: WorldMapLocation) -> void:
	"""Clic sur une location"""
	
	print("[WorldMap] 🖱️ Clic sur : ", location.location_name)
	
	# Si le joueur est déjà sur cette location
	if player.current_location_id == location.location_id:
		_open_location_menu(location)
		return
	
	# Sinon, vérifier si on peut y aller (connexions)
	var current_loc = locations.get(player.current_location_id)
	
	if not current_loc:
		return
	
	var connections = current_loc.get_connections()
	
	if location.location_id in connections:
		# Déplacer le joueur
		player.move_to_location(location)
	else:
		show_notification("Impossible d'aller directement à " + location.location_name, 2.0)

func _on_player_movement_completed() -> void:
	"""Joueur arrivé à destination"""
	
	var current_loc = locations.get(player.current_location_id)
	
	if current_loc:
		show_notification("Arrivée à " + current_loc.location_name, 2.0)
		
		# Ouvrir automatiquement le menu
		await get_tree().create_timer(0.5).timeout
		_open_location_menu(current_loc)

func _on_location_hovered(location: WorldMapLocation) -> void:
	"""Survol d'une location"""
	info_label.text = location.location_name

func _on_location_unhovered(_location: WorldMapLocation) -> void:
	"""Fin de survol"""
	info_label.text = ""

# ============================================================================
# MENU D'ACTIONS
# ============================================================================

func _open_location_menu(location: WorldMapLocation) -> void:
	"""Ouvre le menu d'actions pour une location"""
	
	selected_location = location
	
	# Charger les données détaillées de la location
	var location_data = WorldMapDataLoader.load_location_data(location.location_id)
	
	if location_data.is_empty():
		show_notification("Aucune action disponible ici", 2.0)
		return
	
	# Nettoyer le menu
	for child in action_menu_container.get_children():
		child.queue_free()
	
	# Créer les boutons d'action
	var actions = location_data.get("actions", [])
	
	for action in actions:
		# Vérifier si l'action est déverrouillée
		if action.has("unlocked_at_step") and action.unlocked_at_step > current_step:
			continue
		
		var button = Button.new()
		button.text = action.get("label", "Action")
		button.custom_minimum_size = Vector2(200, 40)
		
		# Icône si présente
		if action.has("icon"):
			var icon_path = action.icon
			if ResourceLoader.exists(icon_path):
				button.icon = load(icon_path)
		
		# Connexion
		var action_data = action.duplicate()
		button.pressed.connect(func(): _on_action_selected(action_data))
		
		action_menu_container.add_child(button)
	
	# Bouton "Fermer"
	var close_button = Button.new()
	close_button.text = "✕ Fermer"
	close_button.custom_minimum_size = Vector2(200, 40)
	close_button.pressed.connect(_close_location_menu)
	action_menu_container.add_child(close_button)
	
	# Positionner et afficher
	action_menu.popup_centered()

func _close_location_menu() -> void:
	"""Ferme le menu d'actions"""
	action_menu.hide()
	selected_location = null

func _on_action_selected(action: Dictionary) -> void:
	"""Action sélectionnée dans le menu"""
	
	print("[WorldMap] 🎬 Action sélectionnée : ", action.get("id"))
	
	_close_location_menu()
	
	match action.get("type"):
		"exploration":
			_handle_exploration_action(action)
		
		"building":
			_handle_building_action(action)
		
		"shop":
			_handle_shop_action(action)
		
		"quest_board":
			_handle_quest_board_action(action)
		
		"custom":
			_handle_custom_action(action)
		
		_:
			show_notification("Type d'action non géré : " + action.get("type"), 2.0)

func _handle_exploration_action(action: Dictionary) -> void:
	"""Gère une action d'exploration"""
	show_notification("Exploration (à implémenter)", 2.0)
	
	# TODO: Émettre un événement custom via EventBus
	if action.has("event"):
		var event_data = action.event
		EventBus.emit_event(event_data.get("type"), [event_data])

func _handle_building_action(action: Dictionary) -> void:
	"""Gère l'entrée dans un bâtiment"""
	
	if action.has("scene"):
		show_notification("Entrée dans " + action.get("label"), 1.5)
		# TODO: Charger la scène
		# EventBus.change_scene(...)

func _handle_shop_action(action: Dictionary) -> void:
	"""Gère l'ouverture d'un magasin"""
	
	var shop_id = action.get("shop_id", "")
	show_notification("Magasin : " + shop_id + " (à implémenter)", 2.0)
	
	# TODO: Ouvrir l'interface de magasin

func _handle_quest_board_action(action: Dictionary) -> void:
	"""Gère le panneau de quêtes"""
	show_notification("Panneau de quêtes (à implémenter)", 2.0)
	
	# TODO: Ouvrir l'interface de quêtes

func _handle_custom_action(action: Dictionary) -> void:
	"""Gère une action custom"""
	
	if action.has("event"):
		var event_data = action.event
		EventBus.emit_event(event_data.get("type"), [event_data])

# ============================================================================
# PROGRESSION
# ============================================================================

func set_current_step(step: int) -> void:
	"""Définit le step de progression actuel"""
	
	if step == current_step:
		return
	
	current_step = step
	
	# Mettre à jour les locations déverrouillées
	_update_unlocked_locations()

func _update_unlocked_locations() -> void:
	"""Met à jour les locations déverrouillées"""
	
	for location_id in locations:
		var location = locations[location_id]
		var location_ref = _get_location_ref(location_id)
		
		if location_ref.is_empty():
			continue
		
		var unlocked = location_ref.get("unlocked_at_step", 0) <= current_step
		location.set_unlocked(unlocked)
	
	# Recréer les connexions
	_refresh_connections()

func _get_location_ref(location_id: String) -> Dictionary:
	"""Récupère la référence d'une location dans les données"""
	
	var locations_data = world_map_data.get("locations", [])
	
	for loc in locations_data:
		if loc.get("id") == location_id:
			return loc
	
	return {}

func _refresh_connections() -> void:
	"""Rafraîchit les lignes de connexion"""
	
	# Supprimer les anciennes
	for child in connections_container.get_children():
		child.queue_free()
	
	# Recréer
	_create_connections()

# ============================================================================
# UI CALLBACKS (existants)
# ============================================================================

func _on_party_pressed() -> void:
	show_notification("Menu Équipe (à implémenter)", 2.0)

func _on_inventory_pressed() -> void:
	show_notification("Inventaire (à implémenter)", 2.0)

func _on_menu_pressed() -> void:
	EventBus.game_paused.emit(true)

# ============================================================================
# NOTIFICATIONS
# ============================================================================

func show_notification(message: String, duration: float = 2.0) -> void:
	notification_label.text = message
	notification_panel.visible = true
	notification_panel.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(notification_panel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(duration)
	tween.tween_property(notification_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): notification_panel.visible = false)

func _on_notification_posted(message: String, type: String) -> void:
	var duration = 2.0
	if type == "warning":
		duration = 3.0
	elif type == "error":
		duration = 4.0
	show_notification(message, duration)

# ============================================================================
# NETTOYAGE
# ============================================================================

func _exit_tree() -> void:
	EventBus.disconnect_all(self)