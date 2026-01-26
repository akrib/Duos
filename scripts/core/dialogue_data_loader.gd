# addons/core/data/dialogue_data_loader.gd
class_name DialogueDataLoader
extends Node

## Charge les dialogues depuis JSON
## Format: data/dialogues/*.json

const DIALOGUES_DIR = "res://data/dialogues/"

var _json_loader: JSONDataLoader
var dialogues: Dictionary = {}

func _init():
	_json_loader = JSONDataLoader.new()

func load_all_dialogues() -> void:
	dialogues = _json_loader.load_json_directory(DIALOGUES_DIR, true)
	
	if dialogues.is_empty():
		push_warning("No dialogues loaded")
	else:
		print("Loaded %d dialogue sets" % dialogues.size())
		EventBus.emit_signal("data_loaded", "dialogues", dialogues)

func get_dialogue(dialogue_id: String) -> Dictionary:
	if dialogues.has(dialogue_id):
		return dialogues[dialogue_id]
	
	push_error("Dialogue not found: " + dialogue_id)
	return {}

func get_dialogue_node(dialogue_id: String, node_id: String) -> Dictionary:
	var dialogue = get_dialogue(dialogue_id)
	if dialogue.has("nodes") and dialogue.nodes.has(node_id):
		return dialogue.nodes[node_id]
	return {}

## Charge un dialogue spécifique pour hot-reload
func reload_dialogue(dialogue_id: String) -> void:
	var file_path = DIALOGUES_DIR.path_join(dialogue_id + ".json")
	_json_loader.clear_cache(file_path)
	var data = _json_loader.load_json_file(file_path)
	
	if data:
		dialogues[dialogue_id] = data
		EventBus.emit_signal("dialogue_reloaded", dialogue_id)
