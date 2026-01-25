# scripts/core/ability_data_loader.gd
extends Node
class_name AbilityDataLoader

## 📘 DATA LOADER MÉTIER POUR LES CAPACITÉS
##
## Responsabilités :
## - Charger les capacités via LuaDataLoader
## - Maintenir un cache métier par ability_id
## - Fournir des requêtes (par catégorie, classe, type)
## - Implémenter la logique gameplay liée aux capacités

const ABILITIES_PATH := "res://lua/abilities/"

# ============================================================================
# CACHE MÉTIER
# ============================================================================

static var _ability_cache: Dictionary = {}

# ============================================================================
# CHARGEMENT
# ============================================================================

## Charge toutes les capacités (lazy-safe)
static func load_all_abilities(use_cache: bool = true) -> Dictionary:
	if use_cache and not _ability_cache.is_empty():
		return _ability_cache
	
	var raw_data = LuaDataLoader.load_lua_folder(ABILITIES_PATH, use_cache)
	
	if typeof(raw_data) != TYPE_DICTIONARY:
		push_error("[AbilityDataLoader] Données invalides")
		return {}
	
	for ability_id in raw_data:
		_ability_cache[ability_id] = _post_process_ability(raw_data[ability_id])
	
	print("[AbilityDataLoader] ✅ ", _ability_cache.size(), " capacités chargées")
	return _ability_cache

## Charge une capacité spécifique
static func load_ability(ability_id: String) -> Dictionary:
	if _ability_cache.has(ability_id):
		return _ability_cache[ability_id]
	
	load_all_abilities()
	
	if _ability_cache.has(ability_id):
		return _ability_cache[ability_id]
	
	push_error("[AbilityDataLoader] Capacité introuvable : ", ability_id)
	return {}

## Vérifie l’existence d’une capacité
static func ability_exists(ability_id: String) -> bool:
	if _ability_cache.has(ability_id):
		return true
	
	load_all_abilities()
	return _ability_cache.has(ability_id)

# ============================================================================
# POST-TRAITEMENT
# ============================================================================

## Post-traitement métier (Lua → gameplay)
static func _post_process_ability(raw_data: Dictionary) -> Dictionary:
	var ability := raw_data.duplicate(true)

	# Valeurs par défaut
	if not ability.has("type"):
		ability.type = "active"

	if not ability.has("cost"):
		ability.cost = {}

	if not ability.has("effects"):
		ability.effects = []

	return ability

# ============================================================================
# REQUÊTES
# ============================================================================

static func get_abilities_by_category(category: String) -> Array:
	load_all_abilities()
	
	var result := []
	for ability in _ability_cache.values():
		if ability.get("category") == category:
			result.append(ability)
	return result

static func get_abilities_by_class(class__name: String) -> Array:
	load_all_abilities()
	
	var result := []
	for ability in _ability_cache.values():
		if ability.get("class") == class__name:
			result.append(ability)
	return result

static func get_active_abilities() -> Array:
	load_all_abilities()
	
	var result := []
	for ability in _ability_cache.values():
		if ability.get("type") == "active":
			result.append(ability)
	return result

static func get_passive_abilities() -> Array:
	load_all_abilities()
	
	var result := []
	for ability in _ability_cache.values():
		if ability.get("type") == "passive":
			result.append(ability)
	return result

# ============================================================================
# LOGIQUE GAMEPLAY
# ============================================================================

## Vérifie si une unité peut utiliser une capacité
static func can_use_ability(unit_data: Dictionary, ability_id: String) -> bool:
	var ability = load_ability(ability_id)
	if ability.is_empty():
		return false
	
	# Coût en mana
	if ability.has("cost") and ability.cost.has("mana"):
		if unit_data.get("mana", 0) < ability.cost.mana:
			return false
	
	# Cooldowns → volontairement hors scope ici
	return true

## Calcule les dégâts d'une capacité
static func calculate_ability_damage(ability_id: String, unit_stats: Dictionary) -> int:
	var ability = load_ability(ability_id)
	if ability.is_empty():
		return 0
	
	var total_damage := 0
	
	for effect in ability.get("effects", []):
		if effect.get("type") != "damage":
			continue
		
		var damage: int = effect.get("base_damage", 0)
		
		if effect.has("scaling"):
			var scaling = effect.scaling
			var stat_value = unit_stats.get(scaling.get("stat"), 0)
			var ratio = scaling.get("ratio", 1.0)
			damage += int(stat_value * ratio)
		
		total_damage += damage
	
	return total_damage

# ============================================================================
# CACHE
# ============================================================================

static func clear_cache() -> void:
	_ability_cache.clear()
	print("[AbilityDataLoader] Cache vidé")
