extends Validator
class_name BattleDataValidator
## Validateur spécialisé pour les données de combat

func _init() -> void:
	# Règles pour les unités
	var rule_name = ValidationRule.new("name", TYPE_STRING, true)
	add_rule(rule_name)

	# ✅ CORRECTION : Accepter TYPE_INT car les HP sont des entiers dans le jeu
	var rule_current_hp = ValidationRule.new("current_hp", TYPE_INT, true)
	rule_current_hp.min_value = 1  # ← Aussi en int
	rule_current_hp.max_value = 9999
	add_rule(rule_current_hp)
	
	var rule_max_hp = ValidationRule.new("max_hp", TYPE_INT, true)
	rule_max_hp.min_value = 1  # ← Aussi en int
	rule_max_hp.max_value = 9999
	add_rule(rule_max_hp)

	var rule_position = ValidationRule.new("position", TYPE_VECTOR2I, true)
	add_rule(rule_position)

func validate_battle_data(battle_data: Dictionary) -> ValidationResult:
	var result = ValidationResult.new()
	
	# Valider player_units
	if not battle_data.has("player_units"):
		result.add_error("player_units manquant")
	elif battle_data.player_units.is_empty():
		result.add_error("player_units vide")
	else:
		for i in range(battle_data.player_units.size()):
			# ✅ Normaliser les données avant validation
			var unit_data = _normalize_unit_data(battle_data.player_units[i])
			var unit_result = validate(unit_data)
			if not unit_result.is_valid:
				for error in unit_result.errors:
					result.add_error("player_units[%d]: %s" % [i, error])
			else:
				# ✅ Remplacer les données normalisées dans l'original
				battle_data.player_units[i] = unit_data
	
	# Valider enemy_units
	if not battle_data.has("enemy_units"):
		result.add_error("enemy_units manquant")
	elif battle_data.enemy_units.is_empty():
		result.add_error("enemy_units vide")
	else:
		for i in range(battle_data.enemy_units.size()):
			var unit_data = _normalize_unit_data(battle_data.enemy_units[i])
			var unit_result = validate(unit_data)
			if not unit_result.is_valid:
				for error in unit_result.errors:
					result.add_error("enemy_units[%d]: %s" % [i, error])
			else:
				# ✅ Remplacer les données normalisées dans l'original
				battle_data.enemy_units[i] = unit_data
	
	return result

## ✅ Convertit les float en int pour les valeurs numériques
func _normalize_unit_data(unit_data: Dictionary) -> Dictionary:
	"""
	Convertit les valeurs numériques float → int
	Car Godot parse tous les nombres JSON en float
	"""
	var normalized = unit_data.duplicate()
	
	# Convertir les HP
	if normalized.has("current_hp") and typeof(normalized.current_hp) == TYPE_FLOAT:
		normalized.current_hp = int(normalized.current_hp)
	
	if normalized.has("max_hp") and typeof(normalized.max_hp) == TYPE_FLOAT:
		normalized.max_hp = int(normalized.max_hp)
	
	# Convertir les stats si présentes
	if normalized.has("stats") and typeof(normalized.stats) == TYPE_DICTIONARY:
		var stats = normalized.stats
		for key in ["attack", "defense", "speed", "range"]:
			if stats.has(key) and typeof(stats[key]) == TYPE_FLOAT:
				stats[key] = int(stats[key])
	
	return normalized
