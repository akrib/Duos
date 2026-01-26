extends Node
class_name Validator
## Validateur générique de données avec règles configurables

class ValidationRule:
	var field_name: String
	var type: int  # TYPE_INT, TYPE_STRING, etc.
	var required: bool = true
	var min_value: Variant = null
	var max_value: Variant = null
	var allowed_values: Array = []
	var custom_validator: Callable = Callable()
	
	func _init(p_field: String, p_type: int, p_required: bool = true):
		field_name = p_field
		type = p_type
		required = p_required

class ValidationResult:
	var is_valid: bool = true
	var errors: Array[String] = []
	
	func add_error(error: String) -> void:
		is_valid = false
		errors.append(error)

var rules: Array[ValidationRule] = []

func add_rule(rule: ValidationRule) -> void:
	rules.append(rule)

func validate(data: Dictionary) -> ValidationResult:
	var result = ValidationResult.new()
	
	for rule in rules:
		_validate_field(data, rule, result)
	
	return result

func _validate_field(data: Dictionary, rule: ValidationRule, result: ValidationResult) -> void:
	# Champ requis
	if rule.required and not data.has(rule.field_name):
		result.add_error("Champ requis manquant : " + rule.field_name)
		return
	
	if not data.has(rule.field_name):
		return  # Champ optionnel absent → OK
	
	var value = data[rule.field_name]
	
	# Vérifier le type
	if typeof(value) != rule.type:
		result.add_error("%s : type invalide (attendu %s, reçu %s)" % [rule.field_name, type_string(rule.type), type_string(typeof(value))])
		return
	
	# Valeurs min/max
	if rule.min_value != null and value < rule.min_value:
		result.add_error("%s : valeur trop petite (min: %s)" % [rule.field_name, rule.min_value])
	
	if rule.max_value != null and value > rule.max_value:
		result.add_error("%s : valeur trop grande (max: %s)" % [rule.field_name, rule.max_value])
	
	# Valeurs autorisées
	if not rule.allowed_values.is_empty() and value not in rule.allowed_values:
		result.add_error("%s : valeur non autorisée (autorisées: %s)" % [rule.field_name, rule.allowed_values])
	
	# Validateur custom
	if rule.custom_validator.is_valid():
		var custom_result = rule.custom_validator.call(value)
		if not custom_result:
			result.add_error("%s : échec de la validation personnalisée" % rule.field_name)