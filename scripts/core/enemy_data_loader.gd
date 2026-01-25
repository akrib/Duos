# scripts/core/enemy_data_loader.gd
extends Node
class_name EnemyDataLoader

## Gestion des données d'ennemis (via LuaDataLoader)

const ENEMIES_PATH := "res://lua/enemies/"

# Cache métier (ennemis par ID)
static var _enemy_cache: Dictionary = {}

# ============================================================================
# CHARGEMENT
# ============================================================================

## Charge tous les ennemis d'un fichier Lua
static func load_enemies_from_file(file_name: String, use_cache: bool = true) -> Dictionary:
	var file_path = ENEMIES_PATH.path_join(file_name + ".lua")
	
	var raw_enemies = LuaDataLoader.load_lua_data(file_path, use_cache)
	
	if typeof(raw_enemies) != TYPE_DICTIONARY:
		push_error("[EnemyDataLoader] Format invalide : ", file_path)
		return {}
	
	var processed: Dictionary = {}
	
	for enemy_id in raw_enemies:
		var enemy_data = raw_enemies[enemy_id]
		
		# ✅ VALIDATION
		var validation = DataValidator.validate_enemy(enemy_data, enemy_id)
		
		if not validation.valid:
			push_error("[EnemyDataLoader] ❌ Ennemi invalide : ", enemy_id)
			for error in validation.errors:
				push_error("  - ", error)
			
			if LuaDataLoader.validation_mode == LuaDataLoader.ValidationMode.STRICT:
				continue
		
		# Warnings
		for warning in validation.warnings:
			push_warning("[EnemyDataLoader] ⚠️ ", enemy_id, " : ", warning)
		
		if typeof(enemy_data) == TYPE_DICTIONARY:
			processed[enemy_id] = enemy_data
			_enemy_cache[enemy_id] = enemy_data
	
	return processed

## Charge tous les ennemis de tous les fichiers
static func load_all_enemies(use_cache: bool = true) -> Dictionary:
	var all_enemies: Dictionary = {}
	var files = _get_enemy_files()
	
	for file_name in files:
		all_enemies.merge(load_enemies_from_file(file_name, use_cache))
	
	return all_enemies

## Charge un ennemi spécifique par son ID
static func load_enemy(enemy_id: String) -> Dictionary:
	if _enemy_cache.has(enemy_id):
		return _enemy_cache[enemy_id]
	
	load_all_enemies()
	return _enemy_cache.get(enemy_id, {})

# ============================================================================
# QUERIES
# ============================================================================

static func enemy_exists(enemy_id: String) -> bool:
	if _enemy_cache.has(enemy_id):
		return true
	
	load_all_enemies()
	return _enemy_cache.has(enemy_id)

static func get_enemies_by_faction(faction: String) -> Array:
	var result: Array = []
	
	for enemy in _enemy_cache.values():
		if enemy.get("faction") == faction:
			result.append(enemy)
	
	return result

static func get_enemies_by_level(level: int) -> Array:
	var result: Array = []
	
	for enemy in _enemy_cache.values():
		if enemy.has("stats") and enemy.stats.get("level") == level:
			result.append(enemy)
	
	return result

static func get_enemies_by_level_range(min_level: int, max_level: int) -> Array:
	var result: Array = []
	
	for enemy in _enemy_cache.values():
		if enemy.has("stats"):
			var lvl = enemy.stats.get("level", 0)
			if lvl >= min_level and lvl <= max_level:
				result.append(enemy)
	
	return result

static func get_boss_enemies() -> Array:
	var result: Array = []
	
	for enemy in _enemy_cache.values():
		if enemy.get("boss", false) or enemy.get("elite", false):
			result.append(enemy)
	
	return result

# ============================================================================
# INSTANCIATION / GAMEPLAY
# ============================================================================

static func create_enemy_instance(
	enemy_id: String,
	level_modifier: int = 0,
	stat_multipliers: Dictionary = {}
) -> Dictionary:
	var base_data = load_enemy(enemy_id)
	if base_data.is_empty():
		return {}
	
	var instance = base_data.duplicate(true)
	
	# Niveau & scaling
	if level_modifier != 0 and instance.has("stats"):
		instance.stats.level += level_modifier
		
		var scale := 1.0 + level_modifier * 0.1
		instance.stats.hp = int(instance.stats.hp * scale)
		instance.stats.max_hp = int(instance.stats.max_hp * scale)
		instance.stats.attack = int(instance.stats.attack * scale)
		instance.stats.defense = int(instance.stats.defense * scale)
	
	# Multiplicateurs
	if not stat_multipliers.is_empty() and instance.has("stats"):
		for stat in stat_multipliers:
			if instance.stats.has(stat):
				instance.stats[stat] = int(instance.stats[stat] * stat_multipliers[stat])
	
	instance.instance_id = _generate_instance_id()
	return instance

static func calculate_threat_level(enemy_id: String) -> int:
	var enemy = load_enemy(enemy_id)
	if enemy.is_empty() or not enemy.has("stats"):
		return 0
	
	var stats = enemy.stats
	var threat := 0
	
	threat += stats.get("hp", 0) / 10
	threat += stats.get("attack", 0) * 2
	threat += stats.get("defense", 0)
	threat += stats.get("magic", 0) * 1.5
	threat += enemy.get("abilities", []).size() * 10
	
	if enemy.get("boss", false):
		threat *= 2
	elif enemy.get("elite", false):
		threat *= 1.5
	
	return int(threat)

# ============================================================================
# LOOT
# ============================================================================

static func get_enemy_loot(enemy_id: String) -> Dictionary:
	return load_enemy(enemy_id).get("loot_table", {})

static func generate_random_loot(enemy_id: String) -> Dictionary:
	var loot_table = get_enemy_loot(enemy_id)
	if loot_table.is_empty():
		return {}
	
	var loot = {
		"gold": 0,
		"experience": 0,
		"items": []
	}
	
	if loot_table.has("gold"):
		loot.gold = randi_range(loot_table.gold.min, loot_table.gold.max)
	
	if loot_table.has("experience"):
		loot.experience = loot_table.experience
	
	if loot_table.has("guaranteed_items"):
		for item in loot_table.guaranteed_items:
			loot.items.append(item.id)
	
	if loot_table.has("items"):
		for item in loot_table.items:
			if randi_range(1, 100) <= item.get("chance", 100):
				loot.items.append(item.id)
	
	return loot

# ============================================================================
# UTILITAIRES
# ============================================================================

static func clear_cache() -> void:
	_enemy_cache.clear()

static func _get_enemy_files() -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(ENEMIES_PATH)
	
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
	return "enemy_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
