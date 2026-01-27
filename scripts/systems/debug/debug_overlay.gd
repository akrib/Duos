extends CanvasLayer
## Debug Overlay - Interface de debug en jeu (F3)

var is_visible: bool = false
var panel: PanelContainer
var info_label: RichTextLabel

var watched_variables: Dictionary = {}  # key -> { object: Node, property: String }

func _ready() -> void:
	layer = 100
	_create_ui()
	visible = false

func _create_ui() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(10, 10)
	panel.custom_minimum_size = Vector2(400, 600)
	add_child(panel)
	
	var scroll = ScrollContainer.new()
	panel.add_child(scroll)
	
	info_label = RichTextLabel.new()
	info_label.bbcode_enabled = true
	info_label.fit_content = true
	info_label.scroll_active = false
	scroll.add_child(info_label)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):  # ✅ Changé de ui_text_toggle_auto à debug_toggle
		toggle_visibility()

func toggle_visibility() -> void:
	is_visible = not is_visible
	visible = is_visible

func _process(_delta: float) -> void:
	if not is_visible:
		return
	
	_update_display()

func _update_display() -> void:
	var text = "[b]DEBUG OVERLAY[/b]\n\n"
	
	# FPS
	text += "[color=yellow]FPS:[/color] %d\n" % Engine.get_frames_per_second()
	
	# Mémoire
	var mem_static = OS.get_static_memory_usage() / 1024.0 / 1024.0
	text += "[color=yellow]Mémoire:[/color] %.2f MB\n\n" % mem_static
	
	# Variables surveillées
	if not watched_variables.is_empty():
		text += "[b]Variables:[/b]\n"
		
		for key in watched_variables:
			var entry = watched_variables[key]
			var obj = entry.object
			var prop = entry.property
			
			if is_instance_valid(obj) and obj.get(prop) != null:
				var value = obj.get(prop)
				text += "  [color=cyan]%s:[/color] %s\n" % [key, str(value)]
		
		text += "\n"
	
	# GameManager
	if is_instance_valid(GameManager):
		text += "[b]GameManager:[/b]\n"
		text += "  Scène: %s\n" % SceneRegistry.get_scene_name(GameManager.current_scene_id)
		text += "  Loading: %s\n\n" % GameManager.is_loading()
	
	# EventBus connections
	text += "[b]EventBus:[/b]\n"
	text += "  Signaux actifs: TODO\n"
		
	if GameManager.current_scene_id == SceneRegistry.SceneID.BATTLE:
		text += "[b]Combat:[/b]\n"
		text += "  État: %s\n" % watched_variables.get("Phase", "N/A")
		text += "  Tour: %s\n" % watched_variables.get("Tour actuel", "N/A")
		
		var player_units = watched_variables.get("Unités joueur", [])
		var enemy_units = watched_variables.get("Unités ennemies", [])
		text += "  Joueur: %d unités\n" % player_units.size()
		text += "  Ennemis: %d unités\n\n" % enemy_units.size()

	info_label.text = text

func watch_variable(key: String, object: Node, property: String) -> void:
	watched_variables[key] = {"object": object, "property": property}

func unwatch_variable(key: String) -> void:
	watched_variables.erase(key)
