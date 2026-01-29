# addons/core/data/ability_data_loader.gd
class_name AbilityDataLoader
extends Node

## Charge les données d'abilities depuis JSON
## Format: data/abilities/*.json

const ABILITIES_DIR = "res://data/abilities/"

var _json_loader: JSONDataLoader
var abilities: Dictionary = {}

func _init():
	_json_loader = JSONDataLoader.new()

func load_all_abilities() -> void:
	abilities = _json_loader.load_json_directory(ABILITIES_DIR, false)
	
	if abilities.is_empty():
		push_warning("No abilities loaded from " + ABILITIES_DIR)
		EventBus.emit_signal("data_load_warning", "abilities", "No data found")
	else:
		print("Loaded %d abilities" % abilities.size())
		EventBus.emit_signal("data_loaded", "abilities", abilities)

func get_ability(ability_id: String) -> Dictionary:
	if abilities.has(ability_id):
		return abilities[ability_id]
	
	push_error("Ability not found: " + ability_id)
	return {}

func reload_ability(ability_id: String) -> void:
	var file_path = ABILITIES_DIR.path_join(ability_id + ".json")
	_json_loader.clear_cache(file_path)
	var data = _json_loader.load_json_file(file_path)
	
	if data:
		abilities[ability_id] = data
		EventBus.emit_signal("ability_reloaded", ability_id)

## Valide les champs requis d'une ability
func validate_ability(data: Dictionary) -> bool:
	var required = ["id", "name", "type", "cost"]
	return _json_loader.validate_schema(data, required)
