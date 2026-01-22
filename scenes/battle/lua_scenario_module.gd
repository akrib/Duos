# scenes/battle/lua_scenario_module.gd
extends ScenarioModule
class_name LuaScenarioModule

var lua_script_path: String = ""
var lua_functions: Dictionary = {}

func setup_lua_scenario(script_path: String) -> void:
	lua_script_path = script_path
	
	# Charger le script Lua
	var error = LuaManager.load_script(script_path)
	if error:
		push_error("[LuaScenarioModule] Erreur: ", error.message)
		return
	
	# Récupérer les fonctions exposées
	_discover_lua_functions()
	
	print("[LuaScenarioModule] Scénario Lua chargé: ", script_path)

func _discover_lua_functions() -> void:
	# Vérifier quelles fonctions le script Lua expose
	var standard_functions = [
		"on_intro",
		"on_outro",
		"on_turn_start",
		"on_turn_end",
		"on_unit_move",
		"on_unit_attack",
		"on_unit_death",
		"check_victory_condition",
		"check_defeat_condition"
	]
	
	for func_name in standard_functions:
		if LuaManager.function_exists(func_name):
			lua_functions[func_name] = true

func play_intro() -> void:
	if lua_functions.has("on_intro"):
		var dialogue_data = LuaManager.call_lua_function("on_intro", [])
		if dialogue_data:
			await _play_lua_dialogue(dialogue_data)
	else:
		await super.play_intro()

func trigger_turn_event(turn: int, is_player: bool) -> void:
	if lua_functions.has("on_turn_start"):
		var event_data = LuaManager.call_lua_function("on_turn_start", [turn, is_player])
		if event_data:
			await _execute_lua_event(event_data)
	
	super.trigger_turn_event(turn, is_player)

func _execute_lua_event(event_data: Dictionary) -> void:
	match event_data.get("type", ""):
		"dialogue":
			await _play_lua_dialogue(event_data.get("dialogue", []))
		
		"spawn_units":
			EventBus.emit_signal("units_spawn_requested", event_data.get("units", []))
		
		"trigger_cutscene":
			EventBus.emit_signal("cutscene_requested", event_data.get("cutscene_id", ""))
		
		_:
			push_warning("[LuaScenarioModule] Type d'événement inconnu: ", event_data.type)

func _play_lua_dialogue(dialogue_lines: Array) -> void:
	"""Joue un dialogue provenant de Lua"""
	
	if not dialogue_box:
		push_warning("[LuaScenarioModule] DialogueBox non configurée")
		return
	
	# Créer un DialogueData à partir des lignes Lua
	var dialogue_data = DialogueData.new("lua_dialogue_" + str(Time.get_ticks_msec()))
	
	for line in dialogue_lines:
		if typeof(line) != TYPE_DICTIONARY:
			continue
		
		var speaker = line.get("speaker", "")
		var text = line.get("text", "")
		
		dialogue_data.add_line(speaker, text)
	
	# Démarrer le dialogue
	Dialogue_Manager.start_dialogue(dialogue_data, dialogue_box)
	
	# Attendre que le dialogue se termine
	await Dialogue_Manager.dialogue_ended
