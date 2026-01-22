# scenes/battle/lua_battle_event_handler.gd
extends Node
class_name LuaBattleEventHandler

var lua_scenario: LuaScenarioModule
var battle_manager: BattleMapManager3D

func _ready():
	# S'abonner aux événements EventBus
	EventBus.safe_connect("unit_attacked", _on_unit_attacked)
	EventBus.safe_connect("unit_died", _on_unit_died)
	# Note: turn_started et turn_ended ne sont pas encore définis dans EventBus
	# EventBus.safe_connect("turn_started", _on_turn_started)
	# EventBus.safe_connect("turn_ended", _on_turn_ended)

func set_lua_scenario(scenario: LuaScenarioModule):
	lua_scenario = scenario

func _on_unit_attacked(attacker: BattleUnit3D, target: BattleUnit3D, damage: int):
	if not lua_scenario or not lua_scenario.lua_functions.has("on_unit_attack"):
		return
	
	var unit_data = {
		"attacker": _serialize_unit(attacker),
		"target": _serialize_unit(target),
		"damage": damage
	}
	
	var result = LuaManager.call_lua_function("on_unit_attack", [unit_data])
	
	if result:
		_handle_lua_result(result)

func _on_unit_died(unit: BattleUnit3D):
	if not lua_scenario or not lua_scenario.lua_functions.has("on_unit_death"):
		return
	
	var unit_data = _serialize_unit(unit)
	var result = LuaManager.call_lua_function("on_unit_death", [unit_data])
	
	if result:
		_handle_lua_result(result)

func _on_turn_started(unit: BattleUnit3D):
	if not lua_scenario or not lua_scenario.lua_functions.has("on_turn_start"):
		return
	
	var unit_data = _serialize_unit(unit)
	var result = LuaManager.call_lua_function("on_turn_start", [unit_data])
	
	if result:
		_handle_lua_result(result)

func _on_turn_ended(unit: BattleUnit3D):
	if not lua_scenario or not lua_scenario.lua_functions.has("on_turn_end"):
		return
	
	var unit_data = _serialize_unit(unit)
	var result = LuaManager.call_lua_function("on_turn_end", [unit_data])
	
	if result:
		_handle_lua_result(result)

func _serialize_unit(unit: BattleUnit3D) -> Dictionary:
	return {
		"name": unit.unit_name,
		"id": unit.unit_id,
		"position": {"x": unit.grid_position.x, "y": unit.grid_position.y},
		"hp": unit.current_hp,
		"max_hp": unit.max_hp,
		"is_alive": unit.is_alive(),
		"is_player": unit.is_player_unit
	}

func _handle_lua_result(result: Dictionary):
	match result.get("type", ""):
		"apply_effect":
			_apply_effect_from_lua(result)
		
		"spawn_units":
			_spawn_units_from_lua(result)
		
		"dialogue":
			_trigger_dialogue_from_lua(result)
		
		_:
			push_warning("[LuaBattleEventHandler] Type de résultat inconnu: ", result.get("type"))

func _apply_effect_from_lua(result: Dictionary):
	"""Applique un effet provenant de Lua"""
	print("[LuaBattleEventHandler] Application d'effet Lua: ", result)
	
	# TODO: Implémenter l'application d'effets
	var targets = result.get("targets", "")
	var effect = result.get("effect", {})
	
	EventBus.notify("Effet Lua appliqué", "info")

func _spawn_units_from_lua(result: Dictionary):
	"""Spawn des unités depuis Lua"""
	print("[LuaBattleEventHandler] Spawn d'unités Lua: ", result)
	
	var units = result.get("units", [])
	
	# TODO: Implémenter le spawn d'unités
	EventBus.notify(str(units.size()) + " renforts arrivent!", "info")

func _trigger_dialogue_from_lua(result: Dictionary):
	"""Déclenche un dialogue depuis Lua"""
	print("[LuaBattleEventHandler] Dialogue Lua: ", result)
	
	var dialogue = result.get("dialogue", [])
	
	if not battle_manager or not battle_manager.dialogue_box:
		return
	
	# Créer un DialogueData
	var dialogue_data = DialogueData.new("lua_event_" + str(Time.get_ticks_msec()))
	
	for line in dialogue:
		if typeof(line) == TYPE_DICTIONARY:
			dialogue_data.add_line(
				line.get("speaker", ""),
				line.get("text", "")
			)
	
	# Démarrer le dialogue
	Dialogue_Manager.start_dialogue(dialogue_data, battle_manager.dialogue_box)
