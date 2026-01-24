# scripts/core/item_data_loader.gd
extends Node
class_name ItemDataLoader

## Charge et gère les données d'items depuis des fichiers Lua

const ITEMS_PATH = "res://lua/items/"

var _item_cache: Dictionary = {}
var _lua: LuaAPI

func _init():
	_lua = LuaAPI.new()
	_setup_lua_environment()

func _setup_lua_environment():
	_lua.bind_libraries(["base", "table", "string"])
	print("[ItemDataLoader] Environnement Lua initialisé")

## Charge tous les items d'un fichier Lua (ex: potions.lua)
func load_items_from_file(file_name: String) -> Dictionary:
	print("[ItemDataLoader] Chargement des items depuis : ", file_name)
	
	var file_path = ITEMS_PATH + file_name + ".lua"
	
	if not FileAccess.file_exists(file_path):
		push_error("[ItemDataLoader] Fichier introuvable : ", file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[ItemDataLoader] Impossible d'ouvrir : ", file_path)
		return {}
	
	var lua_content = file.get_as_text()
	file.close()
	
	# Exécuter le script Lua
	var error = _lua.do_string(lua_content)
	if error is LuaError:
		push_error("[ItemDataLoader] Erreur Lua : ", error.message)
		return {}
	
	# Récupérer tous les items
	var raw_items = _lua.pull_variant("_RESULT")
	
	if typeof(raw_items) != TYPE_DICTIONARY:
		push_error("[ItemDataLoader] Format invalide pour : ", file_name)
		return {}
	
	# Post-traiter chaque item
	var processed_items = {}
	for item_id in raw_items:
		var item = _process_item_data(raw_items[item_id])
		processed_items[item_id] = item
		_item_cache[item_id] = item
	
	print("[ItemDataLoader] ✅ ", processed_items.size(), " items chargés depuis ", file_name)
	return processed_items

## Charge un item spécifique par son ID
func load_item(item_id: String) -> Dictionary:
	# Vérifier le cache
	if _item_cache.has(item_id):
		return _item_cache[item_id]
	
	# Charger tous les fichiers jusqu'à trouver l'item
	var item_files = _get_item_files()
	
	for file_name in item_files:
		var items = load_items_from_file(file_name)
		if items.has(item_id):
			return items[item_id]
	
	push_error("[ItemDataLoader] Item introuvable : ", item_id)
	return {}

## Post-traite les données d'item pour Godot
func _process_item_data(raw_data: Dictionary) -> Dictionary:
	var processed = raw_data.duplicate(true)
	
	# Convertir area_size {x, y} en Vector2i si présent
	if processed.has("usage") and processed.usage.has("area_size"):
		var area = processed.usage.area_size
		processed.usage.area_size = Vector2i(area.x, area.y)
	
	return processed

## Obtient la liste de tous les fichiers d'items
func _get_item_files() -> Array:
	var files = []
	var dir = DirAccess.open(ITEMS_PATH)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".lua"):
				files.append(file_name.replace(".lua", ""))
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return files

## Charge tous les items de tous les fichiers
func load_all_items() -> Dictionary:
	print("[ItemDataLoader] Chargement de tous les items...")
	
	var all_items = {}
	var item_files = _get_item_files()
	
	for file_name in item_files:
		var items = load_items_from_file(file_name)
		all_items.merge(items)
	
	print("[ItemDataLoader] ✅ Total : ", all_items.size(), " items chargés")
	return all_items

## Obtient tous les items d'une catégorie
func get_items_by_category(category: String) -> Array:
	var items = []
	
	for item_id in _item_cache:
		var item = _item_cache[item_id]
		if item.get("category") == category:
			items.append(item)
	
	return items

## Obtient tous les items d'une rareté
func get_items_by_rarity(rarity: String) -> Array:
	var items = []
	
	for item_id in _item_cache:
		var item = _item_cache[item_id]
		if item.get("rarity") == rarity:
			items.append(item)
	
	return items

## Obtient tous les items consommables
func get_consumable_items() -> Array:
	var items = []
	
	for item_id in _item_cache:
		var item = _item_cache[item_id]
		if item.get("type") == "consumable":
			items.append(item)
	
	return items

## Obtient tous les équipements
func get_equipment_items() -> Array:
	var items = []
	
	for item_id in _item_cache:
		var item = _item_cache[item_id]
		if item.get("type") == "equipment":
			items.append(item)
	
	return items

## Vide le cache
func clear_cache() -> void:
	_item_cache.clear()
	print("[ItemDataLoader] Cache vidé")

## Vérifie si un item existe
func item_exists(item_id: String) -> bool:
	if _item_cache.has(item_id):
		return true
	
	# Charger tous les items si pas en cache
	load_all_items()
	return _item_cache.has(item_id)

## Crée une instance d'item avec une quantité
func create_item_instance(item_id: String, quantity: int = 1) -> Dictionary:
	var item_data = load_item(item_id)
	
	if item_data.is_empty():
		return {}
	
	return {
		"item_id": item_id,
		"data": item_data,
		"quantity": quantity,
		"instance_id": _generate_instance_id()
	}

func _generate_instance_id() -> String:
	return "item_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
