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
var connections: Dictionary = {}  # connection_id -> WorldMapConnection

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
	_create_action_menu()
	_connect_ui_buttons()
	_load_world_map_data()
	_generate_map()
	_spawn_player()
	
	EventBus.safe_connect("notification_posted", _on_notification_posted)
	
	print("[WorldMap] ✅ Carte générée depuis Lua")

func _create_action_menu() -> void:
	"""Crée le menu d'actions (popup)"""
	
	action_menu = PopupPanel.new()
	action_menu.name = "ActionMenu"
	action_menu.visible = false
	
	# ✅ AJOUT : Configurer le popup
	action_menu.popup_window = false  # Pas de fenêtre OS séparée
	action_menu.transparent_bg = false
	action_menu.borderless = false
	
	# ✅ AJOUT : StyleBox pour visibilité
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color(0.9, 0.9, 0.9)
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	
	action_menu.add_theme_stylebox_override("panel", stylebox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	action_menu.add_child(margin)
	
	action_menu_container = VBoxContainer.new()
	action_menu_container.custom_minimum_size = Vector2(220, 100) 
	action_menu_container.add_theme_constant_override("separation", 5)
	margin.add_child(action_menu_container)
	
	ui_layer.add_child(action_menu)
	
	print("[WorldMap] ✅ Menu d'actions créé")

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
		
		# ✅ CORRECTION : Ajouter AVANT de setup
		locations_container.add_child(location)
		
		# Maintenant setup (le node est dans la scène)
		location.setup(location_data)
		
		# Vérifier si déverrouillée
		var unlocked = location_data.get("unlocked_at_step", 0) <= current_step
		location.set_unlocked(unlocked)
		
		# Signaux
		location.clicked.connect(_on_location_clicked)
		location.hovered.connect(_on_location_hovered)
		location.unhovered.connect(_on_location_unhovered)
		
		locations[location_data.id] = location
		
		# ✅ DEBUG
		print("[WorldMap] 🎯 Location créée : ", location.location_name, " à ", location.position, " visible=", location.visible)

# ============================================================================
# GÉNÉRATION DES CONNEXIONS (CORRIGÉ)
# ============================================================================

func _create_connections() -> void:
	"""Crée les connexions entre locations avec états"""
	
	var visual_config = world_map_data.get("connections_visual", {})
	
	# ✅ CORRECTION : Configurer les variables STATIQUES de classe
	if visual_config.has("width"):
		WorldMapConnection.default_line_width = visual_config.width
	if visual_config.has("dash_length"):
		WorldMapConnection.default_dash_length = visual_config.dash_length
	
	# Couleurs
	if visual_config.has("color"):
		var c = visual_config.color
		WorldMapConnection.default_color_unlocked = Color(
			c.get("r", 0.7), 
			c.get("g", 0.7), 
			c.get("b", 0.7), 
			c.get("a", 0.8)
		)
	
	if visual_config.has("color_locked"):
		var c = visual_config.color_locked
		WorldMapConnection.default_color_locked = Color(
			c.get("r", 0.3), 
			c.get("g", 0.3), 
			c.get("b", 0.3), 
			c.get("a", 0.4)
		)
	
	# Charger les états des connexions depuis les données
	var connection_states = world_map_data.get("connection_states", {})
	
	# Parcourir toutes les locations
	for location_id in locations:
		var location = locations[location_id]
		var location_connections = location.get_connections()
		
		for target_id in location_connections:
			if not locations.has(target_id):
				continue
			
			var target_location = locations[target_id]
			
			# Ne créer qu'une seule ligne par paire (éviter doublons)
			var connection_id = _get_connection_id(location_id, target_id)
			if connections.has(connection_id):
				continue
			
			# Créer la connexion
			var connection = WorldMapConnection.new()
			
			# Déterminer l'état initial
			var initial_state = _get_connection_state(location_id, target_id, connection_states)
			
			connection.setup(location, target_location, initial_state)
			
			connections_container.add_child(connection)
			connections[connection_id] = connection
	
	print("[WorldMap] ✅ ", connections.size(), " connexions créées")

# ============================================================================
# HELPERS POUR LES CONNEXIONS
# ============================================================================

func _get_connection_id(from_id: String, to_id: String) -> String:
	"""Génère un ID unique pour une paire de locations (ordre alphabétique)"""
	var ids = [from_id, to_id]
	ids.sort()
	return ids[0] + "_to_" + ids[1]

func _get_connection_state(from_id: String, to_id: String, states: Dictionary) -> WorldMapConnection.ConnectionState:
	"""Détermine l'état d'une connexion depuis les données"""
	
	var connection_id = _get_connection_id(from_id, to_id)
	
	# Vérifier si un état spécifique est défini
	if states.has(connection_id):
		var state_str = states[connection_id]
		match state_str:
			"unlocked":
				return WorldMapConnection.ConnectionState.UNLOCKED
			"locked":
				return WorldMapConnection.ConnectionState.LOCKED
			"hidden":
				return WorldMapConnection.ConnectionState.HIDDEN
	
	# Par défaut : déverrouillé si les deux locations sont déverrouillées
	var from_loc = locations.get(from_id)
	var to_loc = locations.get(to_id)
	
	if from_loc and to_loc and from_loc.is_unlocked and to_loc.is_unlocked:
		return WorldMapConnection.ConnectionState.UNLOCKED
	
	# Sinon : caché par défaut
	return WorldMapConnection.ConnectionState.HIDDEN

# ============================================================================
# API PUBLIQUE POUR CONTRÔLER LES CONNEXIONS
# ============================================================================

func unlock_connection(from_id: String, to_id: String) -> void:
	"""Déverrouille une connexion"""
	var connection_id = _get_connection_id(from_id, to_id)
	
	if connections.has(connection_id):
		connections[connection_id].unlock()
		print("[WorldMap] 🔓 Connexion déverrouillée : ", connection_id)

func lock_connection(from_id: String, to_id: String) -> void:
	"""Verrouille une connexion (la rend visible mais bloquée)"""
	var connection_id = _get_connection_id(from_id, to_id)
	
	if connections.has(connection_id):
		connections[connection_id].lock()
		print("[WorldMap] 🔒 Connexion verrouillée : ", connection_id)

func hide_connection(from_id: String, to_id: String) -> void:
	"""Cache une connexion complètement"""
	var connection_id = _get_connection_id(from_id, to_id)
	
	if connections.has(connection_id):
		connections[connection_id].hide_connection()
		print("[WorldMap] 👁️ Connexion cachée : ", connection_id)

func reveal_connection(from_id: String, to_id: String, locked: bool = true) -> void:
	"""Révèle une connexion cachée (verrouillée par défaut)"""
	var connection_id = _get_connection_id(from_id, to_id)
	
	if connections.has(connection_id):
		if locked:
			connections[connection_id].lock()
		else:
			connections[connection_id].unlock()
		print("[WorldMap] 🔍 Connexion révélée : ", connection_id)

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
	
	print("[WorldMap] 🎮 Placement du joueur...")
	print("[WorldMap]   start_location_id = ", start_location_id)
	
	if locations.has(start_location_id):
		var start_loc = locations[start_location_id]
		print("[WorldMap]   ✅ Location trouvée : ", start_loc.location_name)
		player.set_location(start_loc)
		print("[WorldMap]   player.current_location_id = ", player.current_location_id)
	else:
		push_warning("[WorldMap] Location de départ introuvable : ", start_location_id)
		# Fallback : première location déverrouillée
		for loc_id in locations:
			if locations[loc_id].is_unlocked:
				print("[WorldMap]   🔄 Fallback sur : ", loc_id)
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
	print("[WorldMap]   player.current_location_id = ", player.current_location_id)
	print("[WorldMap]   location.location_id = ", location.location_id)
	# Si le joueur est déjà sur cette location
	if player.current_location_id == location.location_id:
		print("[WorldMap] ✅ Joueur sur place, ouverture menu...")
		_open_location_menu(location)
		return
	
	# Sinon, vérifier si on peut y aller (connexions)
	var current_loc = locations.get(player.current_location_id)
	
	if not current_loc:
		print("[WorldMap] ❌ Location actuelle introuvable !")
		return
	
	var location_connections = current_loc.get_connections()
	print("[WorldMap]   Connexions depuis location actuelle : ", location_connections)
	
	if location.location_id in location_connections:
		# Déplacer le joueur
		print("[WorldMap] 🚶 Déplacement du joueur...")
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
	print("[WorldMap] 📋 Ouverture menu pour : ", location.location_id)
	selected_location = location
	
	# Charger les données détaillées de la location
	var location_data = WorldMapDataLoader.load_location_data(location.location_id)
	print("[WorldMap]   Données chargées : ", not location_data.is_empty())
	if location_data.is_empty():
		show_notification("Aucune action disponible ici", 2.0)
		return
	print("[WorldMap]   Actions disponibles : ", location_data.get("actions", []).size())
	# Nettoyer le menu
	for child in action_menu_container.get_children():
		child.queue_free()
	
	# Créer les boutons d'action
	var actions = location_data.get("actions", [])
	
	for action in actions:
		# Vérifier si l'action est déverrouillée
		if action.has("unlocked_at_step") and action.unlocked_at_step > current_step:
			print("[WorldMap]   Action verrouillée : ", action.get("label", "?"))
			continue
		
		print("[WorldMap]   Action verrouillée : ", action.get("label", "?"))
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
	
	print("[WorldMap] 📋 Menu prêt, affichage popup...")
	# Positionner et afficher
	action_menu.popup_centered()
	print("[WorldMap] ✅ Popup affiché (visible = ", action_menu.visible, ")")

func _close_location_menu() -> void:
	"""Ferme le menu d'actions"""
	action_menu.hide()
	selected_location = null

func _on_action_selected(action: Dictionary) -> void:
	"""Action sélectionnée dans le menu"""
	
	print("[WorldMap] 🎬 Action sélectionnée : ", action.get("id"))
	
	_close_location_menu()
	
	match action.get("type"):
		"battle":  # ← NOUVEAU
			_handle_battle_action(action)
		
		"exploration":
			_handle_exploration_action(action)
		
		"building":
			_handle_building_action(action)
		
		"shop":
			_handle_shop_action(action)
		
		"quest_board":
			_handle_quest_board_action(action)
			
		"dialogue":  # ← NOUVEAU (bonus)
			_handle_dialogue_action(action)
			
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
# GESTION DES ACTIONS - AJOUTS
# ============================================================================

func _handle_battle_action(action: Dictionary) -> void:
	"""Gère le lancement d'un combat"""
	
	var battle_id = action.get("battle_id", "")
	
	if battle_id == "":
		show_notification("ID de combat manquant", 2.0)
		return
	
	print("[WorldMap] ⚔️ Lancement du combat : ", battle_id)
	
	# Charger les données du combat
	var battle_data_path = "res://data/battles/" + battle_id + ".json"
	
	if not FileAccess.file_exists(battle_data_path):
		show_notification("Combat introuvable : " + battle_id, 2.0)
		push_error("[WorldMap] Fichier de combat introuvable : ", battle_data_path)
		return
	
	# Charger le JSON
	var file = FileAccess.open(battle_data_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		show_notification("Erreur de chargement du combat", 2.0)
		push_error("[WorldMap] Erreur JSON pour : ", battle_data_path)
		return
	
	var battle_data = json.data
	
	# Envoyer les données au BattleDataManager
	var converted_data = _convert_battle_json_to_godot_types(battle_data)
	BattleDataManager.set_battle_data(converted_data)
	
	# Notification
	var battle_name = battle_data.get("name", "Combat")
	show_notification("Chargement : " + battle_name, 1.5)
	
	# Attendre un peu puis charger la scène de combat
	await get_tree().create_timer(1.5).timeout
	
	# Changer vers la scène de combat 3D
	#EventBus.music_change_requested.emit("res://audio/music/battle_theme.ogg")
	EventBus.change_scene(SceneRegistry.SceneID.BATTLE)

func _handle_dialogue_action(action: Dictionary) -> void:
	"""Gère une action de dialogue"""
	
	var dialogue_id = action.get("dialogue_id", "")
	
	if dialogue_id == "":
		show_notification("ID de dialogue manquant", 2.0)
		return
	
	print("[WorldMap] 💬 Lancement du dialogue : ", dialogue_id)
	
	# Charger le dialogue
	var dialogue_loader = DialogueDataLoader.new()
	var dialogue_data_dict = dialogue_loader.load_dialogue(dialogue_id)
	
	if dialogue_data_dict.is_empty():
		show_notification("Dialogue introuvable : " + dialogue_id, 2.0)
		return
	
	# Convertir en DialogueData (fonction helper déjà existante dans intro_dialogue.gd)
	var dialogue_data = _convert_dialogue_dict_to_data(dialogue_data_dict)
	
	# Récupérer la DialogueBox depuis l'UI
	var dialogue_box = $UI/DialogueBox
	
	if not dialogue_box:
		push_error("[WorldMap] DialogueBox introuvable dans l'UI")
		return
	
	# Démarrer le dialogue
	Dialogue_Manager.start_dialogue(dialogue_data, dialogue_box)

func _convert_battle_json_to_godot_types(battle_data: Dictionary) -> Dictionary:
	var converted = battle_data.duplicate(true)
	
	# Convertir les unités du joueur
	if converted.has("player_units"):
		converted["player_units"] = _convert_units_array(converted["player_units"])
	
	# Convertir les unités ennemies
	if converted.has("enemy_units"):
		converted["enemy_units"] = _convert_units_array(converted["enemy_units"])
	
	# Convertir les obstacles du terrain
	if converted.has("terrain_obstacles"):
		converted["terrain_obstacles"] = _convert_obstacles_array(converted["terrain_obstacles"])
	
	# Convertir grid_size si c'est un Dictionary
	if converted.has("grid_size") and converted["grid_size"] is Dictionary:
		var grid = converted["grid_size"]
		if grid.has("width") and grid.has("height"):
			converted["grid_size"] = Vector2i(int(grid["width"]), int(grid["height"]))
	
	return converted

## Convertit un tableau d'unités (player ou enemy)
func _convert_units_array(units: Array) -> Array:
	var converted_units: Array = []
	
	for unit in units:
		if unit is Dictionary:
			var converted_unit = unit.duplicate(true)
			
			# Convertir hp (float → int)
			if converted_unit.has("hp"):
				converted_unit["hp"] = int(converted_unit["hp"])
			
			# Convertir position (Array → Vector2i)
			if converted_unit.has("position"):
				var pos = converted_unit["position"]
				if pos is Array and pos.size() >= 2:
					converted_unit["position"] = Vector2i(int(pos[0]), int(pos[1]))
			
			# Convertir stats si nécessaire
			if converted_unit.has("stats") and converted_unit["stats"] is Dictionary:
				var stats = converted_unit["stats"]
				for key in stats.keys():
					if stats[key] is float:
						stats[key] = int(stats[key])
			
			converted_units.append(converted_unit)
	
	return converted_units

## Convertit un tableau d'obstacles
func _convert_obstacles_array(obstacles: Array) -> Array:
	var converted_obstacles: Array = []
	
	for obstacle in obstacles:
		if obstacle is Dictionary:
			var converted_obstacle = obstacle.duplicate(true)
			
			# Convertir position (Array → Vector2i)
			if converted_obstacle.has("position"):
				var pos = converted_obstacle["position"]
				if pos is Array and pos.size() >= 2:
					converted_obstacle["position"] = Vector2i(int(pos[0]), int(pos[1]))
			
			converted_obstacles.append(converted_obstacle)
	
	return converted_obstacles

func _convert_dialogue_dict_to_data(lua_dict: Dictionary) -> DialogueData:
	"""Convertit un dictionnaire de dialogue en DialogueData"""
	
	var dialogue = DialogueData.new(lua_dict.get("id", ""))
	
	dialogue.category = lua_dict.get("category", "general")
	dialogue.priority = lua_dict.get("priority", 0)
	dialogue.skippable = lua_dict.get("skippable", true)
	dialogue.pausable = lua_dict.get("pausable", true)
	
	# Traiter les séquences
	if lua_dict.has("sequences"):
		for sequence in lua_dict.sequences:
			if sequence.has("lines"):
				for line in sequence.lines:
					dialogue.add_line(
						line.get("speaker", ""),
						line.get("text", ""),
						{
							"emotion": line.get("emotion", "neutral"),
							"auto_advance": false
						}
					)
	
	return dialogue

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
