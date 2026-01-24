# scripts/core/enemy_data_loader.gd
extends Node
class_name EnemyDataLoader

## Charge et gère les données d'ennemis depuis des fichiers Lua

const ENEMIES_PATH = "res://lua/enemies/"

var _enemy_cache: Dictionary = {}
var _lua: LuaAPI

func _init():
	_lua = LuaAPI.new()
	_setup_lua_environment()

func _setup_lua_environment():
	_lua.bind_libraries(["base", "table", "string"])
	print("[EnemyDataLoader] Environnement Lua initialisé")

## Charge tous les ennemis d'un fichier Lua
func load_enemies_from_file(file_name: String) -> Dictionary:
	print("[EnemyDataLoader] Chargement des ennemis depuis : ", file_name)
	
	var file_path = ENEMIES_PATH + file_name + ".lua"
	
	if not FileAccess.file_exists(file_path):
		push_error("[EnemyDataLoader] Fichier introuvable : ", file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[EnemyDataLoader] Impossible d'ouvrir : ", file_path)
		return {}
	
	var lua_content = file.get_as_text()
	file.close()
	
	# Exécuter le script Lua
	var error = _lua.do_string(lua_content)
	if error is LuaError:
		push_error("[EnemyDataLoader] Erreur Lua : ", error.message)
		return {}
	
	var raw_enemies = _lua.pull_variant("_RESULT")
	
	if typeof(raw_enemies) != TYPE_DICTIONARY:
		push_error("[EnemyDataLoader] Format invalide pour : ", file_name)
		return {}
	
	# Post-traiter chaque ennemi
	var processed_enemies = {}
	for enemy_id in raw_enemies:
		var enemy = _process_enemy_data(raw_enemies[enemy_id])
		processed_enemies[enemy_id] = enemy
		_enemy_cache[enemy_id] = enemy
	
	print("[EnemyDataLoader] ✅ ", processed_enemies.size(), " ennemis chargés")
	return processed_enemies

## Charge un ennemi spécifique par son ID
func load_enemy(enemy_id: String) -> Dictionary:
	# Vérifier le cache
	if _enemy_cache.has(enemy_id):
		return _enemy_cache[enemy_id]
	
	# Charger tous les fichiers jusqu'à trouver l'ennemi
	var enemy_files = _get_enemy_files()
	
	for file_name in enemy_files:
		var enemies = load_enemies_from_file(file_name)
		if enemies.has(enemy_id):
			return enemies[enemy_id]
	
	push_error("[EnemyDataLoader] Ennemi introuvable : ", enemy_id)
	return {}

## Post-traite les données d'ennemi pour Godot
func _process_enemy_data(raw_data: Dictionary) -> Dictionary:
	var processed = raw_data.duplicate(true)
	
	# Convertir la couleur {r, g, b, a} en Color
	if processed.has("color"):
		var c = processed.color
		processed.color = Color(
			c.get("r", 1.0),
			c.get("g", 1.0),
			c.get("b", 1.0),
			c.get("a", 1.0)
		)
	
	return processed

## Obtient la liste de tous les fichiers d'ennemis
func _get_enemy_files() -> Array:
	var files = []
	var dir = DirAccess.open(ENEMIES_PATH)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".lua"):
				files.append(file_name.replace(".lua", ""))
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return files

## Charge tous les ennemis de tous les fichiers
func load_all_enemies() -> Dictionary:
	print("[EnemyDataLoader] Chargement de tous les ennemis...")
	
	var all_enemies = {}
	var enemy_files = _get_enemy_files()
	
	for file_name in enemy_files:
		var enemies = load_enemies_from_file(file_name)
		all_enemies.merge(enemies)
	
	print("[EnemyDataLoader] ✅ Total : ", all_enemies.size(), " ennemis chargés")
	return all_enemies

## Obtient tous les ennemis d'une faction
func get_enemies_by_faction(faction: String) -> Array:
	var enemies = []
	
	for enemy_id in _enemy_cache:
		var enemy = _enemy_cache[enemy_id]
		if enemy.get("faction") == faction:
			enemies.append(enemy)
	
	return enemies

## Obtient tous les ennemis d'un niveau spécifique
func get_enemies_by_level(level: int) -> Array:
	var enemies = []
	
	for enemy_id in _enemy_cache:
		var enemy = _enemy_cache[enemy_id]
		if enemy.has("stats") and enemy.stats.get("level") == level:
			enemies.append(enemy)
	
	return enemies

## Obtient tous les ennemis dans une plage de niveaux
func get_enemies_by_level_range(min_level: int, max_level: int) -> Array:
	var enemies = []
	
	for enemy_id in _enemy_cache:
		var enemy = _enemy_cache[enemy_id]
		if enemy.has("stats"):
			var level = enemy.stats.get("level", 0)
			if level >= min_level and level <= max_level:
				enemies.append(enemy)
	
	return enemies

## Obtient tous les boss
func get_boss_enemies() -> Array:
	var bosses = []
	
	for enemy_id in _enemy_cache:
		var enemy = _enemy_cache[enemy_id]
		if enemy.get("boss", false) or enemy.get("elite", false):
			bosses.append(enemy)
	
	return bosses

## Crée une instance d'ennemi avec des modifications optionnelles
func create_enemy_instance(enemy_id: String, level_modifier: int = 0, stat_multipliers: Dictionary = {}) -> Dictionary:
	var enemy_data = load_enemy(enemy_id)
	
	if enemy_data.is_empty():
		return {}
	
	# Dupliquer pour ne pas modifier le cache
	var instance = enemy_data.duplicate(true)
	
	# Appliquer le modificateur de niveau
	if level_modifier != 0 and instance.has("stats"):
		instance.stats.level += level_modifier
		
		# Ajuster les stats en fonction du niveau
		var level_scaling = 1.0 + (level_modifier * 0.1)
		instance.stats.hp = int(instance.stats.hp * level_scaling)
		instance.stats.max_hp = int(instance.stats.max_hp * level_scaling)
		instance.stats.attack = int(instance.stats.attack * level_scaling)
		instance.stats.defense = int(instance.stats.defense * level_scaling)
	
	# Appliquer les multiplicateurs de stats
	if not stat_multipliers.is_empty() and instance.has("stats"):
		for stat in stat_multipliers:
			if instance.stats.has(stat):
				instance.stats[stat] = int(instance.stats[stat] * stat_multipliers[stat])
	
	# Ajouter un ID d'instance unique
	instance.instance_id = _generate_instance_id()
	
	return instance

## Calcule le niveau de menace d'un ennemi
func calculate_threat_level(enemy_id: String) -> int:
	var enemy = load_enemy(enemy_id)
	
	if enemy.is_empty() or not enemy.has("stats"):
		return 0
	
	var stats = enemy.stats
	var threat = 0
	
	# Formule de base du niveau de menace
	threat += stats.get("hp", 0) / 10
	threat += stats.get("attack", 0) * 2
	threat += stats.get("defense", 0)
	threat += stats.get("magic", 0) * 1.5
	threat += enemy.get("abilities", []).size() * 10
	
	# Bonus pour boss/elite
	if enemy.get("boss", false):
		threat *= 2
	elif enemy.get("elite", false):
		threat *= 1.5
	
	return int(threat)

## Obtient le loot table d'un ennemi
func get_enemy_loot(enemy_id: String) -> Dictionary:
	var enemy = load_enemy(enemy_id)
	return enemy.get("loot_table", {})

## Génère un loot aléatoire basé sur le loot table
func generate_random_loot(enemy_id: String) -> Dictionary:
	var loot_table = get_enemy_loot(enemy_id)
	
	if loot_table.is_empty():
		return {}
	
	var loot = {
		"gold": 0,
		"experience": 0,
		"items": []
	}
	
	# Générer l'or
	if loot_table.has("gold"):
		var gold_range = loot_table.gold
		loot.gold = randi_range(gold_range.min, gold_range.max)
	
	# Ajouter l'expérience
	if loot_table.has("experience"):
		loot.experience = loot_table.experience
	
	# Générer les items garantis
	if loot_table.has("guaranteed_items"):
		for item_drop in loot_table.guaranteed_items:
			loot.items.append(item_drop.id)
	
	# Générer les items avec chance
	if loot_table.has("items"):
		for item_drop in loot_table.items:
			var roll = randi_range(1, 100)
			if roll <= item_drop.get("chance", 100):
				loot.items.append(item_drop.id)
	
	return loot

## Vide le cache
func clear_cache() -> void:
	_enemy_cache.clear()
	print("[EnemyDataLoader] Cache vidé")

## Vérifie si un ennemi existe
func enemy_exists(enemy_id: String) -> bool:
	if _enemy_cache.has(enemy_id):
		return true
	
	load_all_enemies()
	return _enemy_cache.has(enemy_id)

func _generate_instance_id() -> String:
	return "enemy_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
