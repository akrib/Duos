# scripts/systems/validation/data_validation_module.gd
extends Node
class_name DataValidationModule

## 🔍 MODULE DE VALIDATION : Valide les données au démarrage
## Vérifie l'intégrité des fichiers JSON (rings, mana, units)

# ============================================================================
# SIGNAUX
# ============================================================================

signal validation_started()
signal validation_completed(report: ValidationReport)
signal critical_error(error_message: String)

# ============================================================================
# STRUCTURES
# ============================================================================

class ValidationReport:
	var is_valid: bool = true
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var validated_files: Array[String] = []
	
	func add_error(error: String) -> void:
		is_valid = false
		errors.append(error)
	
	func add_warning(warning: String) -> void:
		warnings.append(warning)
	
	func add_validated_file(file_path: String) -> void:
		validated_files.append(file_path)

# ============================================================================
# CONFIGURATION
# ============================================================================

const DATA_PATHS = {
	"rings": "res://data/ring/rings.json",
	"mana_effects": "res://data/mana/mana_effects.json",
	"units": "res://data/team/available_units.json"
}

# Champs requis pour chaque type de donnée
const REQUIRED_FIELDS = {
	"materialization_ring": ["ring_id", "ring_name", "attack_shape", "base_range"],
	"channeling_ring": ["ring_id", "ring_name", "mana_effect_id"],
	"mana_effect": ["effect_id", "mana_type"],
	"unit": ["id", "name", "stats"]
}

# ============================================================================
# DONNÉES
# ============================================================================

var json_loader: JSONDataLoader = null
var last_report: ValidationReport = null

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	json_loader = JSONDataLoader.new()
	print("[DataValidation] ✅ Module initialisé")

# ============================================================================
# VALIDATION GLOBALE
# ============================================================================

func validate_all_data() -> ValidationReport:
	"""
	Valide toutes les données critiques du jeu
	
	@return ValidationReport avec résultats
	"""
	
	validation_started.emit()
	
	var report = ValidationReport.new()
	
	print("[DataValidation] 🔍 Début de la validation...")
	
	# Valider rings
	_validate_rings_file(report)
	
	# Valider mana effects
	_validate_mana_effects_file(report)
	
	# Valider units
	_validate_units_file(report)
	
	# Stocker et émettre
	last_report = report
	validation_completed.emit(report)
	
	# Afficher résumé
	_print_validation_summary(report)
	
	# Bloquer si erreurs critiques
	if not report.is_valid:
		critical_error.emit("Validation échouée - Voir les logs")
	
	return report

# ============================================================================
# VALIDATION RINGS
# ============================================================================

func _validate_rings_file(report: ValidationReport) -> void:
	"""Valide le fichier rings.json"""
	
	var file_path = DATA_PATHS.rings
	
	if not FileAccess.file_exists(file_path):
		report.add_error("Fichier rings.json manquant: " + file_path)
		return
	
	var data = json_loader.load_json_file(file_path, false)
	
	if typeof(data) != TYPE_DICTIONARY:
		report.add_error("rings.json: Format invalide (attendu Dictionary)")
		return
	
	# Valider anneaux de matérialisation
	if data.has("materialization_rings"):
		var errors = validate_rings(data.materialization_rings, "materialization_ring")
		for error in errors:
			report.add_error("Materialization Ring: " + error)
	else:
		report.add_warning("Aucun anneau de matérialisation défini")
	
	# Valider anneaux de canalisation
	if data.has("channeling_rings"):
		var errors = validate_rings(data.channeling_rings, "channeling_ring")
		for error in errors:
			report.add_error("Channeling Ring: " + error)
	else:
		report.add_warning("Aucun anneau de canalisation défini")
	
	if report.errors.is_empty():
		report.add_validated_file(file_path)

# ============================================================================
# VALIDATION MANA EFFECTS
# ============================================================================

func _validate_mana_effects_file(report: ValidationReport) -> void:
	"""Valide le fichier mana_effects.json"""
	
	var file_path = DATA_PATHS.mana_effects
	
	if not FileAccess.file_exists(file_path):
		report.add_error("Fichier mana_effects.json manquant: " + file_path)
		return
	
	var data = json_loader.load_json_file(file_path, false)
	
	if typeof(data) != TYPE_DICTIONARY:
		report.add_error("mana_effects.json: Format invalide")
		return
	
	if not data.has("effects") or typeof(data.effects) != TYPE_ARRAY:
		report.add_error("mana_effects.json: Clé 'effects' manquante ou invalide")
		return
	
	var errors = validate_mana_effects(data.effects)
	for error in errors:
		report.add_error("Mana Effect: " + error)
	
	if report.errors.is_empty():
		report.add_validated_file(file_path)

# ============================================================================
# VALIDATION UNITS
# ============================================================================

func _validate_units_file(report: ValidationReport) -> void:
	"""Valide le fichier des unités disponibles"""
	
	var file_path = DATA_PATHS.units
	
	if not FileAccess.file_exists(file_path):
		report.add_warning("Fichier available_units.json manquant (optionnel)")
		return
	
	var data = json_loader.load_json_file(file_path, false)
	
	if typeof(data) != TYPE_DICTIONARY:
		report.add_error("available_units.json: Format invalide")
		return
	
	var errors = validate_units(data)
	for error in errors:
		report.add_error("Unit: " + error)
	
	if report.errors.is_empty():
		report.add_validated_file(file_path)

# ============================================================================
# VALIDATEURS SPÉCIFIQUES
# ============================================================================

func validate_rings(rings: Array, ring_type: String) -> Array[String]:
	"""Valide un tableau d'anneaux"""
	
	var errors: Array[String] = []
	var required = REQUIRED_FIELDS.get(ring_type, [])
	
	for i in range(rings.size()):
		var ring = rings[i]
		
		if typeof(ring) != TYPE_DICTIONARY:
			errors.append("[%d] Type invalide (attendu Dictionary)" % i)
			continue
		
		# Vérifier champs requis
		for field in required:
			if not ring.has(field):
				errors.append("[%d] Champ requis manquant: %s" % [i, field])
		
		# Vérifications spécifiques
		if ring_type == "materialization_ring":
			if ring.has("attack_shape"):
				var valid_shapes = ["line", "cone", "circle", "cross", "area"]
				if ring.attack_shape not in valid_shapes:
					errors.append("[%d] attack_shape invalide: %s" % [i, ring.attack_shape])
	
	return errors

func validate_mana_effects(effects: Array) -> Array[String]:
	"""Valide un tableau d'effets de mana"""
	
	var errors: Array[String] = []
	var required = REQUIRED_FIELDS.mana_effect
	
	for i in range(effects.size()):
		var effect = effects[i]
		
		if typeof(effect) != TYPE_DICTIONARY:
			errors.append("[%d] Type invalide" % i)
			continue
		
		# Vérifier champs requis
		for field in required:
			if not effect.has(field):
				errors.append("[%d] Champ requis manquant: %s" % [i, field])
		
		# Vérifier mana_type valide
		if effect.has("mana_type"):
			var valid_types = ["FIRE", "ICE", "LIGHTNING", "HOLY", "DARK", "NATURE"]
			if effect.mana_type not in valid_types:
				errors.append("[%d] mana_type invalide: %s" % [i, effect.mana_type])
	
	return errors

func validate_units(units_dict: Dictionary) -> Array[String]:
	"""Valide un dictionnaire d'unités"""
	
	var errors: Array[String] = []
	var required = REQUIRED_FIELDS.unit
	
	for unit_id in units_dict:
		var unit = units_dict[unit_id]
		
		if typeof(unit) != TYPE_DICTIONARY:
			errors.append("[%s] Type invalide" % unit_id)
			continue
		
		# Vérifier champs requis
		for field in required:
			if not unit.has(field):
				errors.append("[%s] Champ requis manquant: %s" % [unit_id, field])
	
	return errors

# ============================================================================
# HELPERS
# ============================================================================

func is_data_valid() -> bool:
	"""Vérifie si les dernières données validées sont valides"""
	return last_report != null and last_report.is_valid

func get_errors() -> Array[String]:
	"""Retourne les erreurs de la dernière validation"""
	if last_report:
		return last_report.errors
	return []

func get_warnings() -> Array[String]:
	"""Retourne les avertissements de la dernière validation"""
	if last_report:
		return last_report.warnings
	return []

func _print_validation_summary(report: ValidationReport) -> void:
	"""Affiche un résumé de la validation"""
	
	print("\n╔═══════════════════════════════════════╗")
	print("║   RAPPORT DE VALIDATION DES DONNÉES   ║")
	print("╚═══════════════════════════════════════╝")
	
	if report.is_valid:
		print("✅ VALIDATION RÉUSSIE")
	else:
		print("❌ VALIDATION ÉCHOUÉE")
	
	print("\n📁 Fichiers validés: ", report.validated_files.size())
	for file in report.validated_files:
		print("  ✓ ", file)
	
	if not report.errors.is_empty():
		print("\n❌ Erreurs (", report.errors.size(), "):")
		for error in report.errors:
			print("  • ", error)
	
	if not report.warnings.is_empty():
		print("\n⚠️  Avertissements (", report.warnings.size(), "):")
		for warning in report.warnings:
			print("  • ", warning)
	
	print("\n═══════════════════════════════════════\n")