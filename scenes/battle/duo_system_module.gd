extends Node
class_name DuoSystemModule

signal duo_formed(unit_a: BattleUnit3D, unit_b: BattleUnit3D)
signal duo_broken(unit_a: BattleUnit3D, unit_b: BattleUnit3D)

var active_duos: Array[Array] = []  # [[unit_a, unit_b], ...]

func check_duo_formation(unit: BattleUnit3D, unit_manager: UnitManager3D) -> void:
	# Vérifie si un duo peut se former
	pass

func get_duo_bonus(duo: Array) -> Dictionary:
	# Retourne les bonus du duo
	return {}

func execute_duo_action(duo: Array, action: String) -> void:
	# Exécute une action en duo
	pass
