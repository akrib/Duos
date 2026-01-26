# addons/core/data/world_map_data_loader.gd
class_name WorldMapDataLoader
extends Node

## Charge les données de cartes du monde depuis JSON
## Format: data/maps/*.json

const MAPS_DIR = "res://data/maps/"

var _json_loader: JSONDataLoader
var maps: Dictionary = {}
var current_map: Dictionary = {}

func _init():
	_json_loader = JSONDataLoader.new()

func load_all_maps() -> void:
	maps = _json_loader.load_json_directory(MAPS_DIR, true)
	
	if maps.is_empty():
		push_warning("No maps loaded")
	else:
		print("Loaded %d maps" % maps.size())
		EventBus.emit_signal("data_loaded", "maps", maps)

func get_map(map_id: String) -> Dictionary:
	if maps.has(map_id):
		return maps[map_id]
	
	push_error("Map not found: " + map_id)
	return {}

func load_map(map_id: String) -> bool:
	var map_data = get_map(map_id)
	
	if map_data.is_empty():
		return false
	
	current_map = map_data
	EventBus.emit_signal("map_loaded", map_id, map_data)
	return true

func get_location(location_id: String) -> Dictionary:
	if current_map.has("locations"):
		for loc in current_map.locations:
			if loc.id == location_id:
				return loc
	return {}

func get_connections_from(location_id: String) -> Array:
	if current_map.has("connections"):
		var result = []
		for conn in current_map.connections:
			if conn.from == location_id:
				result.append(conn)
		return result
	return []
