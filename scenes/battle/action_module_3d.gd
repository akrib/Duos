extends Node
## ActionModule3D - Gère toutes les actions de combat en 3D

class_name ActionModule3D

signal action_executed(attacker: BattleUnit3D, target: BattleUnit3D, action_type: String)
signal damage_dealt(target: BattleUnit3D, damage: int)

var unit_manager: UnitManager3D
var terrain: TerrainModule3D

const ATTACK_COLOR: Color = Color(1.0, 0.3, 0.3, 0.5)

# ============================================================================
# VALIDATION
# ============================================================================

func can_attack(attacker: BattleUnit3D, target: BattleUnit3D) -> bool:
	if not attacker.can_act():
		return false
	if not target.is_alive():
		return false
	if attacker.is_player_unit == target.is_player_unit:
		return false
	
	var distance = terrain.get_distance(attacker.grid_position, target.grid_position)
	return distance <= attacker.attack_range

func get_attack_positions(unit: BattleUnit3D) -> Array[Vector2i]:
	"""Retourne toutes les positions attaquables"""
	var positions: Array[Vector2i] = []
	var range = unit.attack_range
	
	for dy in range(-range, range + 1):
		for dx in range(-range, range + 1):
			if dx == 0 and dy == 0:
				continue
			
			var manhattan = abs(dx) + abs(dy)
			if manhattan > range:
				continue
			
			var pos = unit.grid_position + Vector2i(dx, dy)
			if terrain.is_in_bounds(pos):
				positions.append(pos)
	
	return positions

# ============================================================================
# ACTIONS DE COMBAT
# ============================================================================

func execute_attack(attacker: BattleUnit3D, target: BattleUnit3D) -> void:
	if not can_attack(attacker, target):
		return
	
	print("[ActionModule3D] ", attacker.unit_name, " attaque ", target.unit_name)
	
	await _animate_attack_3d(attacker, target)
	
	var damage = calculate_damage(attacker, target)
	target.take_damage(damage)
	
	# ✅ NOUVEAU : Spawner le nombre de dégâts
	_spawn_damage_number(target, damage)
	
	damage_dealt.emit(target, damage)
	action_executed.emit(attacker, target, "attack")
	
	EventBus.attack(attacker, target, damage)

# ✅ NOUVELLE FONCTION
func _spawn_damage_number(target: BattleUnit3D, damage: int) -> void:
	"""Crée un nombre de dégâts animé au-dessus de la cible"""
	var damage_number = preload("res://scenes/battle/damage_number.gd").new()
	
	# Position de spawn : au-dessus de l'unité
	var spawn_pos = target.global_position + Vector3(0, 2.0, 0)
	
	# Offset aléatoire pour éviter superposition
	var random_offset = Vector3(
		randf_range(-0.5, 0.5),
		0,
		randf_range(-0.5, 0.5)
	)
	
	damage_number.setup(damage, spawn_pos, random_offset)
	
	# Ajouter à la scène
	target.get_parent().add_child(damage_number)

func calculate_damage(attacker: BattleUnit3D, target: BattleUnit3D) -> int:
	var base_damage = attacker.attack_power
	var terrain_defense = terrain.get_defense_bonus(target.grid_position)
	var total_defense = target.defense_power + (terrain_defense * 0.1)
	var damage = max(1, int(base_damage - total_defense))
	damage = int(damage * randf_range(0.9, 1.1))
	
	return damage

# ============================================================================
# ANIMATIONS 3D
# ============================================================================

func _animate_attack_3d(attacker: BattleUnit3D, target: BattleUnit3D) -> void:
	"""Anime une attaque en 3D"""
	var original_pos = attacker.position
	var target_pos = target.position
	var direction = (target_pos - original_pos).normalized()
	var attack_distance = 0.5
	
	var tween = attacker.create_tween()
	tween.tween_property(attacker, "position", original_pos + direction * attack_distance, 0.1)
	tween.tween_property(attacker, "position", original_pos, 0.1)
	await tween.finished
