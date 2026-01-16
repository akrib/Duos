extends Node
class_name DuoSystemModule

signal duo_formed(unit_a: BattleUnit, unit_b: BattleUnit)
signal duo_broken(unit_a: BattleUnit, unit_b: BattleUnit)

var active_duos: Array[Array] = []  # [[unit_a, unit_b], ...]

func check_duo_formation(unit: BattleUnit, unit_manager: UnitManager) -> void:
	# Vérifie si un duo peut se former
	pass

func get_duo_bonus(duo: Array) -> Dictionary:
	# Retourne les bonus du duo
	return {}

func execute_duo_action(duo: Array, action: String) -> void:
	# Exécute une action en duo
	pass
