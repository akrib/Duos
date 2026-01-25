# scripts/core/data_validator.gd
extends Node
class_name DataValidator

## ⚠️ Validateur centralisé pour toutes les données Lua
## 
## Responsabilités :
## - Définir les schémas de validation
## - Valider les données selon leur type
## - Fournir des rapports d'erreur détaillés
## 
## Usage :
##   var result = DataValidator.validate_ability(ability_data)
##   if not result.valid:
##       print("Erreurs : ", result.errors)

# ============================================================================
# RÉSULTAT DE VALIDATION
# ============================================================================

class ValidationResult:
	var valid: bool = true
	var errors: Array[String] = []
	var warnings: Array[String] = []
	
	func add_error(message: String) -> void:
		errors.append(message)
		valid = false
	
	func add_warning(message: String) -> void:
		warnings.append(message)
	
	func to_dict() -> Dictionary:
		return {
			"valid": valid,
			"errors": errors,
			"warnings": warnings
		}

# ============================================================================
# VALIDATION : ABILITIES
# ============================================================================

static func validate_ability(data: Dictionary, ability_id: String = "") -> ValidationResult:
	"""
	Valide une capacité
	
	Schéma attendu :
	{
	    "id": String,
	    "name": String,
	    "type": "active" | "passive",
	    "category": String,
	    "effects": Array[Dictionary]
	}
	"""
	
	var result = ValidationResult.new()
	var context = "ability[" + ability_id + "]" if ability_id else "ability"
	
	# Champs obligatoires
	_check_required(result, data, context, [
		"id",
		"name",
		"type",
		"category"
	])
	
	# Vérifier le type
	if data.has("type"):
		var valid_types = ["active", "passive"]
		if data.type not in valid_types:
			result.add_error(context + " : type invalide '" + str(data.type) + "' (attendu: " + str(valid_types) + ")")
	
	# Vérifier les effets
	if data.has("effects"):
		if typeof(data.effects) != TYPE_ARRAY:
			result.add_error(context + " : effects doit être un Array")
		elif data.effects.is_empty():
			result.add_warning(context + " : effects est vide")
		else:
			for i in range(data.effects.size()):
				_validate_ability_effect(result, data.effects[i], context + ".effects[" + str(i) + "]")
	else:
		if data.get("type") == "active":
			result.add_error(context + " : capacité active sans effects")
	
	# Vérifier le coût (si active)
	if data.get("type") == "active":
		if not data.has("cost"):
			result.add_warning(context + " : capacité active sans cost défini")
		else:
			_validate_cost(result, data.cost, context + ".cost")
	
	return result

static func _validate_ability_effect(result: ValidationResult, effect: Dictionary, context: String) -> void:
	"""Valide un effet de capacité"""
	
	_check_required(result, effect, context, ["type"])
	
	if effect.has("type"):
		var valid_effect_types = ["damage", "heal", "buff", "debuff", "apply_status", "remove_status"]
		if effect.type not in valid_effect_types:
			result.add_error(context + " : type d'effet invalide '" + str(effect.type) + "'")
		
		# Validation spécifique par type
		match effect.type:
			"damage":
				_check_required(result, effect, context, ["base_damage"])
			"heal":
				_check_required(result, effect, context, ["base_amount"])
			"buff", "debuff":
				_check_required(result, effect, context, ["stat", "amount", "duration"])
			"apply_status":
				_check_required(result, effect, context, ["status", "duration"])

static func _validate_cost(result: ValidationResult, cost: Dictionary, context: String) -> void:
	"""Valide le coût d'une capacité"""
	
	if cost.has("mana") and typeof(cost.mana) != TYPE_INT:
		result.add_error(context + ".mana : doit être un entier")
	
	if cost.has("action_points") and typeof(cost.action_points) != TYPE_INT:
		result.add_error(context + ".action_points : doit être un entier")

# ============================================================================
# VALIDATION : ENEMIES
# ============================================================================

static func validate_enemy(data: Dictionary, enemy_id: String = "") -> ValidationResult:
	"""
	Valide un ennemi
	
	Schéma attendu :
	{
	    "id": String,
	    "name": String,
	    "stats": {
	        "hp": int,
	        "attack": int,
	        "defense": int,
	        "movement": int
	    },
	    "type": String,
	    "faction": String
	}
	"""
	
	var result = ValidationResult.new()
	var context = "enemy[" + enemy_id + "]" if enemy_id else "enemy"
	
	# Champs obligatoires
	_check_required(result, data, context, [
		"id",
		"name",
		"stats",
		"type",
		"faction"
	])
	
	# Valider les stats
	if data.has("stats"):
		_validate_unit_stats(result, data.stats, context + ".stats")
	
	# Valider les résistances (optionnel)
	if data.has("resistances") and typeof(data.resistances) != TYPE_DICTIONARY:
		result.add_error(context + ".resistances : doit être un Dictionary")
	
	# Valider le loot_table
	if data.has("loot_table"):
		_validate_loot_table(result, data.loot_table, context + ".loot_table")
	
	return result

static func _validate_unit_stats(result: ValidationResult, stats: Dictionary, context: String) -> void:
	"""Valide les stats d'une unité"""
	
	var required_stats = ["hp", "max_hp", "attack", "defense", "movement"]
	
	for stat in required_stats:
		if not stats.has(stat):
			result.add_error(context + " : stat manquante '" + stat + "'")
		elif typeof(stats[stat]) != TYPE_INT:
			result.add_error(context + "." + stat + " : doit être un entier")

static func _validate_loot_table(result: ValidationResult, loot: Dictionary, context: String) -> void:
	"""Valide une table de loot"""
	
	if loot.has("gold"):
		if typeof(loot.gold) != TYPE_DICTIONARY:
			result.add_error(context + ".gold : doit être un Dictionary {min, max}")
		else:
			_check_required(result, loot.gold, context + ".gold", ["min", "max"])

# ============================================================================
# VALIDATION : ITEMS
# ============================================================================

static func validate_item(data: Dictionary, item_id: String = "") -> ValidationResult:
	"""Valide un item"""
	
	var result = ValidationResult.new()
	var context = "item[" + item_id + "]" if item_id else "item"
	
	_check_required(result, data, context, [
		"id",
		"name",
		"type",
		"category"
	])
	
	# Vérifier le type
	if data.has("type"):
		var valid_types = ["consumable", "equipment", "key_item"]
		if data.type not in valid_types:
			result.add_error(context + " : type invalide '" + str(data.type) + "'")
	
	# Si consommable, vérifier les effets
	if data.get("type") == "consumable":
		if not data.has("effects"):
			result.add_error(context + " : item consommable sans effects")
	
	return result

# ============================================================================
# VALIDATION : DIALOGUES
# ============================================================================

static func validate_dialogue(data: Dictionary, dialogue_id: String = "") -> ValidationResult:
	"""Valide un dialogue"""
	
	var result = ValidationResult.new()
	var context = "dialogue[" + dialogue_id + "]" if dialogue_id else "dialogue"
	
	_check_required(result, data, context, [
		"id"
	])
	
	# Vérifier les séquences
	if data.has("sequences"):
		if typeof(data.sequences) != TYPE_ARRAY:
			result.add_error(context + ".sequences : doit être un Array")
		elif data.sequences.is_empty():
			result.add_warning(context + ".sequences : est vide")
		else:
			for i in range(data.sequences.size()):
				_validate_dialogue_sequence(result, data.sequences[i], context + ".sequences[" + str(i) + "]")
	
	return result

static func _validate_dialogue_sequence(result: ValidationResult, sequence: Dictionary, context: String) -> void:
	"""Valide une séquence de dialogue"""
	
	_check_required(result, sequence, context, ["id", "type", "lines"])
	
	if sequence.has("lines"):
		if typeof(sequence.lines) != TYPE_ARRAY:
			result.add_error(context + ".lines : doit être un Array")
		elif sequence.lines.is_empty():
			result.add_warning(context + ".lines : est vide")

# ============================================================================
# HELPERS
# ============================================================================

static func _check_required(result: ValidationResult, data: Dictionary, context: String, fields: Array) -> void:
	"""Vérifie la présence de champs obligatoires"""
	
	for field in fields:
		if not data.has(field):
			result.add_error(context + " : champ obligatoire manquant '" + field + "'")

static func _check_type(result: ValidationResult, data: Dictionary, context: String, field: String, expected_type: int) -> void:
	"""Vérifie le type d'un champ"""
	
	if data.has(field):
		if typeof(data[field]) != expected_type:
			var type_names = {
				TYPE_NIL: "null",
				TYPE_BOOL: "bool",
				TYPE_INT: "int",
				TYPE_FLOAT: "float",
				TYPE_STRING: "String",
				TYPE_ARRAY: "Array",
				TYPE_DICTIONARY: "Dictionary"
			}
			result.add_error(context + "." + field + " : type incorrect (attendu: " + type_names.get(expected_type, "inconnu") + ")")

# ============================================================================
# VALIDATION BATCH
# ============================================================================

static func validate_all_abilities(abilities: Dictionary) -> Dictionary:
	"""Valide toutes les capacités et retourne un rapport"""
	
	var report = {
		"total": abilities.size(),
		"valid": 0,
		"invalid": 0,
		"warnings": 0,
		"errors": []
	}
	
	for ability_id in abilities:
		var result = validate_ability(abilities[ability_id], ability_id)
		
		if result.valid:
			report.valid += 1
		else:
			report.invalid += 1
			report.errors.append({
				"id": ability_id,
				"errors": result.errors
			})
		
		report.warnings += result.warnings.size()
	
	return report

static func validate_all_enemies(enemies: Dictionary) -> Dictionary:
	"""Valide tous les ennemis"""
	
	var report = {
		"total": enemies.size(),
		"valid": 0,
		"invalid": 0,
		"warnings": 0,
		"errors": []
	}
	
	for enemy_id in enemies:
		var result = validate_enemy(enemies[enemy_id], enemy_id)
		
		if result.valid:
			report.valid += 1
		else:
			report.invalid += 1
			report.errors.append({
				"id": enemy_id,
				"errors": result.errors
			})
		
		report.warnings += result.warnings.size()
	
	return report

static func validate_all_items(items: Dictionary) -> Dictionary:
	"""Valide tous les items"""
	
	var report = {
		"total": items.size(),
		"valid": 0,
		"invalid": 0,
		"warnings": 0,
		"errors": []
	}
	
	for item_id in items:
		var result = validate_item(items[item_id], item_id)
		
		if result.valid:
			report.valid += 1
		else:
			report.invalid += 1
			report.errors.append({
				"id": item_id,
				"errors": result.errors
			})
		
		report.warnings += result.warnings.size()
	
	return report
