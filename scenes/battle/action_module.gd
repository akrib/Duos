extends Node
## ActionModule - Gère toutes les actions de combat
## Attaques, capacités spéciales, calcul de dégâts

class_name ActionModule

# ============================================================================
# SIGNAUX
# ============================================================================

signal action_executed(attacker: BattleUnit, target: BattleUnit, action_type: String)
signal damage_dealt(target: BattleUnit, damage: int)
signal ability_used(unit: BattleUnit, ability_name: String)

# ============================================================================
# RÉFÉRENCES
# ============================================================================

var unit_manager: UnitManager
var terrain: TerrainModule

# ============================================================================
# VISUELS DE PORTÉE
# ============================================================================

var attack_range_indicators: Array[ColorRect] = []

const ATTACK_RANGE_COLOR: Color = Color(1.0, 0.3, 0.3, 0.4)

# ============================================================================
# AFFICHAGE DE PORTÉE D'ATTAQUE
# ============================================================================

func show_action_range(unit: BattleUnit) -> void:
	"""Affiche la portée d'attaque d'une unité"""
	
	hide_ranges()
	
	var positions = get_attack_positions(unit)
	
	for pos in positions:
		var indicator = _create_indicator(pos)
		attack_range_indicators.append(indicator)
		terrain.add_child(indicator)

func hide_ranges() -> void:
	"""Masque les indicateurs"""
	
	for indicator in attack_range_indicators:
		indicator.queue_free()
	attack_range_indicators.clear()

func _create_indicator(grid_pos: Vector2i) -> ColorRect:
	"""Crée un indicateur visuel"""
	
	var rect = ColorRect.new()
	rect.position = Vector2(grid_pos.x * terrain.tile_size, grid_pos.y * terrain.tile_size)
	rect.size = Vector2(terrain.tile_size, terrain.tile_size)
	rect.color = ATTACK_RANGE_COLOR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = 1
	
	return rect

# ============================================================================
# VALIDATION
# ============================================================================

func can_attack(attacker: BattleUnit, target: BattleUnit) -> bool:
	"""Vérifie si une attaque est possible"""
	
	if not attacker.can_act():
		return false
	
	if not target.is_alive():
		return false
	
	# Vérifier que c'est un ennemi
	if attacker.is_player_unit == target.is_player_unit:
		return false
	
	# Vérifier la portée
	var distance = terrain.get_distance(attacker.grid_position, target.grid_position)
	return distance <= attacker.attack_range

func get_attack_positions(unit: BattleUnit) -> Array[Vector2i]:
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

func execute_attack(attacker: BattleUnit, target: BattleUnit) -> void:
	"""Exécute une attaque standard"""
	
	if not can_attack(attacker, target):
		return
	
	print("[ActionModule] ", attacker.unit_name, " attaque ", target.unit_name)
	
	# Animation d'attaque
	await _animate_attack(attacker, target)
	
	# Calculer les dégâts
	var damage = calculate_damage(attacker, target)
	
	# Appliquer les dégâts
	target.take_damage(damage)
	
	damage_dealt.emit(target, damage)
	action_executed.emit(attacker, target, "attack")
	
	# Enregistrer dans EventBus
	EventBus.attack(attacker, target, damage)

func calculate_damage(attacker: BattleUnit, target: BattleUnit) -> int:
	"""Calcule les dégâts d'une attaque"""
	
	# Dégâts de base
	var base_damage = attacker.attack_power
	
	# Bonus de terrain du défenseur
	var terrain_defense = terrain.get_defense_bonus(target.grid_position)
	
	# Défense totale
	var total_defense = target.defense_power + (terrain_defense * 0.1)
	
	# Calcul final (minimum 1 dégât)
	var damage = max(1, int(base_damage - total_defense))
	
	# Variance aléatoire (90% à 110%)
	damage = int(damage * randf_range(0.9, 1.1))
	
	return damage

# ============================================================================
# CAPACITÉS SPÉCIALES
# ============================================================================

func use_ability(unit: BattleUnit, ability_name: String, targets: Array) -> void:
	"""Utilise une capacité spéciale"""
	
	if not unit.can_act():
		return
	
	if ability_name not in unit.abilities:
		push_warning("[ActionModule] Capacité inconnue: ", ability_name)
		return
	
	print("[ActionModule] ", unit.unit_name, " utilise ", ability_name)
	
	# Exécuter selon le type de capacité
	match ability_name:
		"Heal":
			await _execute_heal(unit, targets)
		"Shield Bash":
			await _execute_shield_bash(unit, targets)
		"Multi-Shot":
			await _execute_multi_shot(unit, targets)
		"Defend":
			await _execute_defend(unit)
		_:
			push_warning("[ActionModule] Capacité non implémentée: ", ability_name)
	
	ability_used.emit(unit, ability_name)

func _execute_heal(caster: BattleUnit, targets: Array) -> void:
	"""Capacité: Soin"""
	
	for target in targets:
		if target is BattleUnit:
			target.heal(30)
			await get_tree().create_timer(0.3).timeout

func _execute_shield_bash(attacker: BattleUnit, targets: Array) -> void:
	"""Capacité: Coup de bouclier (dégâts + stun)"""
	
	for target in targets:
		if target is BattleUnit:
			await _animate_attack(attacker, target)
			var damage = calculate_damage(attacker, target)
			target.take_damage(damage)
			target.add_status_effect("Stunned", 1)
			await get_tree().create_timer(0.3).timeout

func _execute_multi_shot(attacker: BattleUnit, targets: Array) -> void:
	"""Capacité: Tir multiple"""
	
	for target in targets:
		if target is BattleUnit:
			await _animate_attack(attacker, target)
			var damage = int(calculate_damage(attacker, target) * 0.7)  # 70% des dégâts
			target.take_damage(damage)
			await get_tree().create_timer(0.2).timeout

func _execute_defend(unit: BattleUnit) -> void:
	"""Capacité: Défense (augmente la défense temporairement)"""
	
	unit.add_status_effect("Defending", 1)
	unit.defense_power += 10

# ============================================================================
# ANIMATIONS
# ============================================================================

func _animate_attack(attacker: BattleUnit, target: BattleUnit) -> void:
	"""Anime une attaque"""
	
	var original_pos = attacker.position
	var target_pos = target.position
	var direction = (target_pos - original_pos).normalized()
	var attack_distance = 20.0
	
	# Mouvement vers la cible
	var tween = attacker.create_tween()
	tween.tween_property(attacker, "position", original_pos + direction * attack_distance, 0.1)
	tween.tween_property(attacker, "position", original_pos, 0.1)
	await tween.finished

# ============================================================================
# NETTOYAGE
# ============================================================================

func clear() -> void:
	"""Nettoie le module"""
	
	hide_ranges()
	print("[ActionModule] Nettoyé")