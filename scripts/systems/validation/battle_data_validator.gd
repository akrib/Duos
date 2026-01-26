extends Validator
class_name BattleDataValidator
## Validateur spécialisé pour les données de combat

func _init() -> void:
	# Règles pour les unités
	var rule_name = ValidationRule.new("name", TYPE_STRING, true)
	add_rule(rule_name)
	
	var rule_hp = ValidationRule.new("hp", TYPE_INT, true)
	rule_hp.min_value = 1
	rule_hp.max_value = 9999
	add_rule(rule_hp)
	
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
			var unit_result = validate(battle_data.player_units[i])
			if not unit_result.is_valid:
				for error in unit_result.errors:
					result.add_error("player_units[%d]: %s" % [i, error])
	
	# Valider enemy_units
	if not battle_data.has("enemy_units"):
		result.add_error("enemy_units manquant")
	elif battle_data.enemy_units.is_empty():
		result.add_error("enemy_units vide")
	else:
		for i in range(battle_data.enemy_units.size()):
			var unit_result = validate(battle_data.enemy_units[i])
			if not unit_result.is_valid:
				for error in unit_result.errors:
					result.add_error("enemy_units[%d]: %s" % [i, error])
	
	return result