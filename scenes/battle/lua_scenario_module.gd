# scenes/battle/lua_scenario_module.gd
extends Node
class_name LuaScenarioModule

## 🎬 MODULE DE SCÉNARIO 100% LUA
## Gère tous les événements, dialogues et triggers via Lua uniquement

# ============================================================================
# SIGNAUX
# ============================================================================

signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal event_triggered(event_id: String)

# ============================================================================
# DONNÉES
# ============================================================================

var lua_script_path: String = ""
var lua_functions: Dictionary = {}
var triggered_events: Array[String] = []

# ✅ Référence à la DialogueBox (comme l'ancien ScenarioModule)
var dialogue_box: DialogueBox = null

# ============================================================================
# SETUP
# ============================================================================

func setup_lua_scenario(script_path: String) -> void:
	"""Configure un scénario Lua"""
	lua_script_path = script_path
	
	# Charger le script Lua
	var error = LuaManager.load_script(script_path)
	if error:
		push_error("[LuaScenarioModule] Erreur : ", error.message)
		return
	
	# Récupérer les fonctions exposées
	_discover_lua_functions()
	
	print("[LuaScenarioModule] ✅ Scénario Lua chargé : ", script_path)

func _discover_lua_functions() -> void:
	"""Détecte les fonctions Lua exposées"""
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

# ============================================================================
# INTRO / OUTRO
# ============================================================================

func has_intro() -> bool:
	"""Vérifie s'il y a une intro Lua"""
	return lua_functions.has("on_intro")

func play_intro() -> void:
	"""Joue l'intro depuis Lua"""
	if not lua_functions.has("on_intro"):
		return
	
	var dialogue_data = LuaManager.call_lua_function("on_intro", [])
	if dialogue_data:
		await _play_lua_dialogue(dialogue_data)

func has_outro() -> bool:
	"""Vérifie s'il y a une outro Lua"""
	return lua_functions.has("on_outro")

func play_outro(victory: bool) -> void:
	"""Joue l'outro depuis Lua"""
	if not lua_functions.has("on_outro"):
		return
	
	var dialogue_data = LuaManager.call_lua_function("on_outro", [victory])
	if dialogue_data:
		await _play_lua_dialogue(dialogue_data)

# ============================================================================
# TRIGGERS
# ============================================================================

func trigger_turn_event(turn: int, is_player: bool) -> void:
	"""Déclenche les événements de tour depuis Lua"""
	if not lua_functions.has("on_turn_start"):
		return
	
	var event_data = LuaManager.call_lua_function("on_turn_start", [turn, is_player])
	if event_data:
		await _execute_lua_event(event_data)

func trigger_position_event(unit: BattleUnit3D, pos: Vector2i) -> void:
	"""Déclenche les événements de position depuis Lua"""
	if not lua_functions.has("on_unit_move"):
		return
	
	var unit_data = {
		"name": unit.unit_name,
		"position": {"x": pos.x, "y": pos.y}
	}
	
	var event_data = LuaManager.call_lua_function("on_unit_move", [unit_data])
	if event_data:
		await _execute_lua_event(event_data)

# ============================================================================
# EXÉCUTION D'ÉVÉNEMENTS LUA
# ============================================================================

func _execute_lua_event(event_data: Dictionary) -> void:
	"""Exécute un événement Lua"""
	match event_data.get("type", ""):
		"dialogue":
			await _play_lua_dialogue(event_data.get("dialogue", []))
		
		"spawn_units":
			EventBus.emit_signal("units_spawn_requested", event_data.get("units", []))
		
		"trigger_cutscene":
			EventBus.emit_signal("cutscene_requested", event_data.get("cutscene_id", ""))
		
		_:
			push_warning("[LuaScenarioModule] Type d'événement inconnu : ", event_data.type)

# ============================================================================
# SYSTÈME DE DIALOGUE
# ============================================================================

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
	
	# Attendre la fin
	await Dialogue_Manager.dialogue_ended
