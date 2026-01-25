# scripts/core/item_data_loader.gd
extends Node
class_name ItemDataLoader

const ITEMS_PATH = "res://lua/items/"

var _item_cache: Dictionary = {}

## Charge tous les items d'un fichier
func load_items_from_file(file_name: String) -> Dictionary:
	var lua_path = ITEMS_PATH + file_name + ".lua"
	
	# ✅ UTILISER LE HELPER
	var items = LuaDataLoader.load_lua_data(lua_path, true, true)
	
	if typeof(items) == TYPE_DICTIONARY:
		_item_cache.merge(items)
		return items
	
	return {}

## Charge TOUS les items
func load_all_items() -> Dictionary:
	return LuaDataLoader.load_lua_folder(ITEMS_PATH, true)

## Charge un item spécifique
func load_item(item_id: String) -> Dictionary:
	# Charger tous si pas en cache
	if not _item_cache.has(item_id):
		_item_cache = load_all_items()
	
	return _item_cache.get(item_id, {})
