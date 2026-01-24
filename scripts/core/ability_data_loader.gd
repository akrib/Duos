# scripts/core/ability_data_loader.gd
extends Node
class_name AbilityDataLoader

## Charge et gère les données de capacités/sorts depuis des fichiers Lua

const ABILITIES_PATH = "res://lua/abilities/"

var _ability_cache: Dictionary = {}
var _lua: LuaAPI

func _init():
	_lua = LuaAPI.new()
	_setup_lua_environment()

func _setup_lua_environment():
	_lua.bind_libraries(["base", "table", "string"])
	print("[AbilityDataLoader] Environnement Lua initialisé")

## Charge toutes les capacités d'un fichier Lua
func load_abilities_from_file(file_name: String) -> Dictionary:
	print("[AbilityDataLoader] Chargement des capacités depuis : ", file_name)
	
	var file_path = ABILITIES_PATH + file_name + ".lua"
	
	if not FileAccess.file_exists(file_path):
		push_error("[AbilityDataLoader] Fichier introuvable : ", file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[AbilityDataLoader] Impossible d'ouvrir : ", file_path)
		return {}
	
	var lua_content = file.get_as_text()
	file.close()
	
	# Exécuter le script Lua
	var error = _lua.do_string(lua_content)
	if error is LuaError:
		push_error("[AbilityDataLoader] Erreur Lua : ", error.message)
		return {}
	
	var raw_abilities = _lua.pull_variant("_RESULT")
	
	if typeof(raw_abilities) != TYPE_DICTIONARY:
		push_error("[AbilityDataLoader] Format invalide pour : ", file_name)
		return {}
	
	# Post-traiter chaque capacité
	var processed_abilities = {}
	for ability_id in raw_abilities:
		var ability = _process_ability_data(raw_abilities[ability_id])
		processed_abilities[ability_id] = ability
		_ability_cache[ability_id] = ability
	
	print("[AbilityDataLoader] ✅ ", processed_abilities.size(), " capacités chargées")
	return processed_abilities

## Charge une capacité spécifique par son ID
func load_ability(ability_id: String) -> Dictionary:
	# Vérifier le cache
	if _ability_cache.has(ability_id):
		return _ability_cache[ability_id]
	
	# Charger tous les fichiers jusqu'à trouver la capacité
	var ability_files = _get_ability_files()
	
	for file_name in ability_files:
		var abilities = load_abilities_from_file(file_name)
		if abilities.has(ability_id):
			return abilities[ability_id]
	
	push_error("[AbilityDataLoader] Capacité introuvable : ", ability_id)
	return {}

## Post-traite les données de capacité pour Godot
func _process_ability_data(raw_data: Dictionary) -> Dictionary:
	var processed = raw_data.duplicate(true)
	
	# Convertir area_size si présent
	if processed.has("targeting") and processed.targeting.has("area_size"):
		var area = processed.targeting.area_size
		processed.targeting.area_size = Vector2i(area.x, area.y)
	
	return processed

## Obtient la liste de tous les fichiers de capacités
func _get_ability_files() -> Array:
	var files = []
	var dir = DirAccess.open(ABILITIES_PATH)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".lua"):
				files.append(file_name.replace(".lua", ""))
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return files

## Charge toutes les capacités de tous les fichiers
func load_all_abilities() -> Dictionary:
	print("[AbilityDataLoader] Chargement de toutes les capacités...")
	
	var all_abilities = {}
	var ability_files = _get_ability_files()
	
	for file_name in ability_files:
		var abilities = load_abilities_from_file(file_name)
		all_abilities.merge(abilities)
	
	print("[AbilityDataLoader] ✅ Total : ", all_abilities.size(), " capacités chargées")
	return all_abilities

## Obtient toutes les capacités d'une catégorie
func get_abilities_by_category(category: String) -> Array:
	var abilities = []
	
	for ability_id in _ability_cache:
		var ability = _ability_cache[ability_id]
		if ability.get("category") == category:
			abilities.append(ability)
	
	return abilities

## Obtient toutes les capacités d'une classe
func get_abilities_by_class(class_name: String) -> Array:
	var abilities = []
	
	for ability_id in _ability_cache:
		var ability = _ability_cache[ability_id]
		if ability.get("class") == class_name:
			abilities.append(ability)
	
	return abilities

## Obtient toutes les capacités actives
func get_active_abilities() -> Array:
	var abilities = []
	
	for ability_id in _ability_cache:
		var ability = _ability_cache[ability_id]
		if ability.get("type") == "active":
			abilities.append(ability)
	
	return abilities

## Obtient toutes les capacités passives
func get_passive_abilities() -> Array:
	var abilities = []
	
	for ability_id in _ability_cache:
		var ability = _ability_cache[ability_id]
		if ability.get("type") == "passive":
			abilities.append(ability)
	
	return abilities

## Vérifie si une unité peut utiliser une capacité
func can_use_ability(unit_data: Dictionary, ability_id: String) -> bool:
	var ability = load_ability(ability_id)
	
	if ability.is_empty():
		return false
	
	# Vérifier le coût en mana
	if ability.has("cost") and ability.cost.has("mana"):
		var mana_cost = ability.cost.mana
		if unit_data.get("mana", 0) < mana_cost:
			return false
	
	# Vérifier le cooldown (nécessite un système de tracking des cooldowns)
	# À implémenter selon le système de jeu
	
	return true

## Calcule les dégâts d'une capacité pour une unité
func calculate_ability_damage(ability_id: String, unit_stats: Dictionary) -> int:
	var ability = load_ability(ability_id)
	
	if ability.is_empty() or not ability.has("effects"):
		return 0
	
	var total_damage = 0
	
	for effect in ability.effects:
		if effect.get("type") == "damage":
			var base_damage = effect.get("base_damage", 0)
			var damage = base_damage
			
			# Appliquer le scaling
			if effect.has("scaling"):
				var scaling = effect.scaling
				var stat_value = unit_stats.get(scaling.stat, 0)
				var ratio = scaling.get("ratio", 1.0)
				damage += int(stat_value * ratio)
			
			total_damage += damage
	
	return total_damage

## Vide le cache
func clear_cache() -> void:
	_ability_cache.clear()
	print("[AbilityDataLoader] Cache vidé")

## Vérifie si une capacité existe
func ability_exists(ability_id: String) -> bool:
	if _ability_cache.has(ability_id):
		return true
	
	load_all_abilities()
	return _ability_cache.has(ability_id)
