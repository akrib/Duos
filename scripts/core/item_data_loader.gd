# scripts/core/item_data_loader.gd
extends Node
class_name ItemDataLoader

const ITEMS_PATH = "res://lua/items/"

static var _item_cache: Dictionary = {}

# ============================================================================
# CHARGEMENT
# ============================================================================

## Charge tous les items d'un fichier (avec validation)
static func load_items_from_file(file_name: String, use_cache: bool = true) -> Dictionary:
	var lua_path = ITEMS_PATH + file_name + ".lua"
	
	var raw_items = LuaDataLoader.load_lua_data(lua_path, use_cache)
	
	if typeof(raw_items) != TYPE_DICTIONARY:
		push_error("[ItemDataLoader] Format invalide : ", lua_path)
		return {}
	
	var processed: Dictionary = {}
	
	for item_id in raw_items:
		var item_data = raw_items[item_id]
		
		# ✅ VALIDATION
		var validation = DataValidator.validate_item(item_data, item_id)
		
		if not validation.valid:
			push_error("[ItemDataLoader] ❌ Item invalide : ", item_id)
			for error in validation.errors:
				push_error("  - ", error)
			
			# Mode strict : on skip
			if LuaDataLoader.validation_mode == LuaDataLoader.ValidationMode.STRICT:
				continue
		
		# Warnings
		for warning in validation.warnings:
			push_warning("[ItemDataLoader] ⚠️ ", item_id, " : ", warning)
		
		# Post-processing et stockage
		if typeof(item_data) == TYPE_DICTIONARY:
			processed[item_id] = item_data
			_item_cache[item_id] = item_data
	
	return processed

## Charge TOUS les items de tous les fichiers (avec validation)
static func load_all_items(use_cache: bool = true) -> Dictionary:
	var all_items: Dictionary = {}
	var files = _get_item_files()
	
	for file_name in files:
		all_items.merge(load_items_from_file(file_name, use_cache))
	
	print("[ItemDataLoader] ✅ ", all_items.size(), " items chargés et validés")
	return all_items

## Charge un item spécifique
static func load_item(item_id: String) -> Dictionary:
	if _item_cache.has(item_id):
		return _item_cache[item_id]
	
	load_all_items()
	return _item_cache.get(item_id, {})

## Vérifie l'existence
static func item_exists(item_id: String) -> bool:
	if _item_cache.has(item_id):
		return true
	
	load_all_items()
	return _item_cache.has(item_id)

# ============================================================================
# QUERIES
# ============================================================================

static func get_items_by_category(category: String) -> Array:
	load_all_items()
	
	var result: Array = []
	for item in _item_cache.values():
		if item.get("category") == category:
			result.append(item)
	return result

static func get_items_by_type(type: String) -> Array:
	load_all_items()
	
	var result: Array = []
	for item in _item_cache.values():
		if item.get("type") == type:
			result.append(item)
	return result

static func get_consumable_items() -> Array:
	return get_items_by_type("consumable")

static func get_equipment_items() -> Array:
	return get_items_by_type("equipment")

# ============================================================================
# INSTANCIATION
# ============================================================================

static func create_item_instance(item_id: String, quantity: int = 1) -> Dictionary:
	var base_data = load_item(item_id)
	if base_data.is_empty():
		return {}
	
	var instance = base_data.duplicate(true)
	instance.instance_id = _generate_instance_id()
	instance.quantity = quantity
	
	return instance

# ============================================================================
# UTILITAIRES
# ============================================================================

static func clear_cache() -> void:
	_item_cache.clear()

static func _get_item_files() -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(ITEMS_PATH)
	
	if not dir:
		return files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".lua"):
			files.append(file_name.replace(".lua", ""))
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return files

static func _generate_instance_id() -> String:
	return "item_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
