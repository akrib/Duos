# scenes/battle/lua_battle_event_handler.gd
extends Node
class_name LuaBattleEventHandler

var lua_scenario: LuaScenarioModule
var battle_manager: BattleMapManager3D

func _ready():
	# S'abonner aux événements EventBus
	EventBus.safe_connect("unit_attacked", _on_unit_attacked)
	EventBus.safe_connect("unit_died", _on_unit_died)
	EventBus.safe_connect("turn_started", _on_turn_started)
	EventBus.safe_connect("turn_ended", _on_turn_ended)

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
