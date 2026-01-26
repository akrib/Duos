# scripts/core/battle_data_manager.gd
extends Node
## BattleDataManager - Gestionnaire centralisé des données de combat
## Autoload dédié au stockage et à la validation des données de bataille
## 
## Responsabilités :
## - Stocker les données du combat actuel
## - Valider la structure des données
## - Fournir un accès thread-safe
## - Nettoyer après usage

# ============================================================================
# SIGNAUX
# ============================================================================

signal battle_data_stored(battle_id: String)
signal battle_data_cleared()
signal battle_data_invalid(errors: Array)

# ============================================================================
# DONNÉES
# ============================================================================

var _current_battle_data: Dictionary = {}
var _is_data_valid: bool = false
var _battle_id: String = ""

# ============================================================================
# STOCKAGE
# ============================================================================

## Stocke les données d'un combat
func set_battle_data(data: Dictionary) -> bool:
	"""
	Stocke les données de combat après validation
	
	@param data : Dictionnaire contenant les données de combat
	@return true si stockage réussi, false si données invalides
	"""
	
	# Validation
	var validation_result = _validate_battle_data(data)
	
	if not validation_result.valid:
		push_error("[BattleDataManager] ❌ Données invalides : ", validation_result.errors)
		battle_data_invalid.emit(validation_result.errors)
		return false
	
	# Stockage
	_current_battle_data = data.duplicate(true)
	_is_data_valid = true
	_battle_id = data.get("battle_id", "unknown_" + str(Time.get_unix_time_from_system()))
	
	print("[BattleDataManager] ✅ Données stockées : ", _battle_id)
	battle_data_stored.emit(_battle_id)
	
	return true

## Récupère les données du combat actuel
func get_battle_data() -> Dictionary:
	"""
	Retourne les données du combat actuel
	
	@return Dictionary avec les données, ou {} si aucune donnée valide
	"""
	
	if not _is_data_valid:
		push_warning("[BattleDataManager] ⚠️ Aucune donnée de combat valide")
		return {}
	
	print("[BattleDataManager] 📦 Récupération des données : ", _battle_id)
	return _current_battle_data.duplicate(true)

## Vérifie si des données sont disponibles
func has_battle_data() -> bool:
	"""Vérifie si des données de combat valides sont stockées"""
	return _is_data_valid and not _current_battle_data.is_empty()

## Récupère l'ID du combat actuel
func get_battle_id() -> String:
	"""Retourne l'ID du combat actuel"""
	return _battle_id

# ============================================================================
# NETTOYAGE
# ============================================================================

## Efface les données du combat actuel
func clear_battle_data() -> void:
	"""
	Nettoie les données de combat
	Appelé automatiquement après la bataille
	"""
	
	if _is_data_valid:
		print("[BattleDataManager] 🧹 Nettoyage des données : ", _battle_id)
	
	_current_battle_data.clear()
	_is_data_valid = false
	_battle_id = ""
	
	battle_data_cleared.emit()

## Efface les données de manière forcée (emergency)
func force_clear() -> void:
	"""Nettoyage forcé en cas d'erreur critique"""
	push_warning("[BattleDataManager] ⚠️ Nettoyage forcé des données")
	clear_battle_data()

# ============================================================================
# VALIDATION
# ============================================================================

## Valide la structure des données de combat
func _validate_battle_data(data: Dictionary) -> Dictionary:
	"""
	Valide que les données de combat ont la structure attendue
	
	@param data : Données à valider
	@return Dictionary avec {valid: bool, errors: Array}
	"""
	
	var errors: Array = []
	
	# Vérifier les champs obligatoires
	var required_fields = ["player_units", "enemy_units"]
	
	for field in required_fields:
		if not data.has(field):
			errors.append("Champ manquant : " + field)
	
	# Vérifier que les unités ne sont pas vides
	if data.has("player_units") and data.player_units is Array:
		if data.player_units.is_empty():
			errors.append("player_units est vide")
	else:
		errors.append("player_units n'est pas un Array")
	
	if data.has("enemy_units") and data.enemy_units is Array:
		if data.enemy_units.is_empty():
			errors.append("enemy_units est vide")
	else:
		errors.append("enemy_units n'est pas un Array")
	
	# Valider chaque unité joueur
	if data.has("player_units"):
		for i in range(data.player_units.size()):
			var unit = data.player_units[i]
			var unit_errors = _validate_unit_data(unit, "player_units[" + str(i) + "]")
			errors.append_array(unit_errors)
	
	# Valider chaque unité ennemie
	if data.has("enemy_units"):
		for i in range(data.enemy_units.size()):
			var unit = data.enemy_units[i]
			var unit_errors = _validate_unit_data(unit, "enemy_units[" + str(i) + "]")
			errors.append_array(unit_errors)
	
	return {
		"valid": errors.is_empty(),
		"errors": errors
	}

## Valide les données d'une unité
func _validate_unit_data(unit: Dictionary, context: String) -> Array:
	"""
	Valide qu'une unité a les champs nécessaires
	
	@param unit : Données de l'unité
	@param context : Contexte pour les erreurs (ex: "player_units[0]")
	@return Array d'erreurs
	"""
	
	var errors: Array = []
	
	# Champs obligatoires pour une unité
	var required_fields = ["name", "position", "stats"]
	
	for field in required_fields:
		if not unit.has(field):
			errors.append(context + " : champ manquant '" + field + "'")
	
	# Valider la position
	if unit.has("position"):
		var pos = unit.position
		if not (pos is Vector2i):
			errors.append(context + " : position n'est pas un Vector2i")
	
	# Valider les stats
	if unit.has("stats"):
		var stats = unit.stats
		var required_stats = ["hp", "attack", "defense", "movement"]
		
		for stat in required_stats:
			if not stats.has(stat):
				errors.append(context + " : stat manquante '" + stat + "'")
	
	return errors

# ============================================================================
# DEBUG
# ============================================================================

## Affiche les données actuelles (debug)
func debug_print_data() -> void:
	"""Affiche les données de combat pour debug"""
	
	if not _is_data_valid:
		print("[BattleDataManager] 🐛 Aucune donnée à afficher")
		return
	
	print("\n=== BattleDataManager DEBUG ===")
	print("Battle ID : ", _battle_id)
	print("Player Units : ", _current_battle_data.get("player_units", []).size())
	print("Enemy Units : ", _current_battle_data.get("enemy_units", []).size())
	print("Terrain : ", _current_battle_data.get("terrain", "N/A"))
	print("================================\n")

## Retourne les statistiques du combat actuel
func get_battle_stats() -> Dictionary:
	"""Retourne des statistiques sur le combat actuel"""
	
	if not _is_data_valid:
		return {}
	
	return {
		"battle_id": _battle_id,
		"player_unit_count": _current_battle_data.get("player_units", []).size(),
		"enemy_unit_count": _current_battle_data.get("enemy_units", []).size(),
		"has_objectives": _current_battle_data.has("objectives"),
		"has_scenario": _current_battle_data.has("scenario"),
		"terrain_type": _current_battle_data.get("terrain", "unknown")
	}

# ============================================================================
# NETTOYAGE AUTOMATIQUE
# ============================================================================

func _ready() -> void:
	# Connexion au signal de fin de combat pour nettoyage auto
	EventBus.safe_connect("battle_ended", _on_battle_ended)
	print("[BattleDataManager] ✅ Initialisé")

func _on_battle_ended(_results: Dictionary) -> void:
	"""Nettoyage automatique après la fin du combat"""
	clear_battle_data()

func _exit_tree() -> void:
	"""Nettoyage à la fermeture"""
	EventBus.disconnect_all(self)
