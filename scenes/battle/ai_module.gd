extends Node
## AIModule - Intelligence artificielle pour les ennemis
## Prise de décision, évaluation, exécution des actions

class_name AIModule

# ============================================================================
# SIGNAUX
# ============================================================================

signal ai_turn_started()
signal ai_turn_completed()
signal ai_action_taken(unit: BattleUnit, action: String)

# ============================================================================
# RÉFÉRENCES
# ============================================================================

var terrain: TerrainModule
var unit_manager: UnitManager
var movement_module: MovementModule
var action_module: ActionModule

# ============================================================================
# CONFIGURATION
# ============================================================================

enum AIBehavior {
	AGGRESSIVE,   # Attaque le plus proche
	DEFENSIVE,    # Protège une position
	BALANCED,     # Mix des deux
	SUPPORT       # Soutien et soins
}

var default_behavior: AIBehavior = AIBehavior.AGGRESSIVE

# ============================================================================
# EXÉCUTION
# ============================================================================

func execute_enemy_turn() -> void:
	"""Exécute le tour de toutes les unités ennemies"""
	
	ai_turn_started.emit()
	
	var enemies = unit_manager.get_alive_enemy_units()
	
	print("[AIModule] === Tour IA (", enemies.size(), " unités) ===")
	
	# Trier par priorité (plus proches des alliés d'abord)
	enemies.sort_custom(_sort_by_priority)
	
	# Exécuter chaque unité
	for enemy in enemies:
		await _execute_unit_turn(enemy)
		await get_tree().create_timer(0.5).timeout
	
	ai_turn_completed.emit()
	print("[AIModule] === Fin du tour IA ===")

func _execute_unit_turn(unit: BattleUnit) -> void:
	"""Exécute le tour d'une unité ennemie"""
	
	if not unit.is_alive():
		return
	
	print("[AIModule] ", unit.unit_name, " joue")
	
	# 1. Trouver la meilleure action
	var decision = evaluate_unit_action(unit)
	
	# 2. Exécuter le mouvement si pertinent
	if decision.has("move_to") and unit.can_move():
		var target_pos = decision.move_to
		if movement_module.can_move_to(unit, target_pos):
			await movement_module.move_unit(unit, target_pos)
			unit.movement_used = true
	
	# 3. Exécuter l'action
	if decision.has("action") and unit.can_act():
		await _execute_ai_action(unit, decision)
		unit.action_used = true

# ============================================================================
# ÉVALUATION
# ============================================================================

func evaluate_unit_action(unit: BattleUnit) -> Dictionary:
	"""
	Détermine la meilleure action pour une unité
	
	Retourne:
	{
		"action": "attack" | "ability" | "wait",
		"target": BattleUnit,
		"move_to": Vector2i,
		"score": float
	}
	"""
	
	var best_decision: Dictionary = {"action": "wait", "score": 0.0}
	
	# 1. Trouver la meilleure cible
	var target = find_best_attack_target(unit)
	
	if not target:
		# Pas de cible, se déplacer vers les ennemis
		var move_pos = find_best_movement(unit)
		return {"action": "wait", "move_to": move_pos, "score": 10.0}
	
	# 2. Vérifier si on peut attaquer directement
	if action_module.can_attack(unit, target):
		best_decision = {
			"action": "attack",
			"target": target,
			"score": 100.0
		}
	else:
		# 3. Se déplacer pour attaquer
		var move_pos = find_position_to_attack(unit, target)
		if move_pos != unit.grid_position:
			best_decision = {
				"action": "attack",
				"target": target,
				"move_to": move_pos,
				"score": 80.0
			}
	
	return best_decision

func find_best_attack_target(unit: BattleUnit) -> BattleUnit:
	"""Trouve la meilleure cible à attaquer"""
	
	var player_units = unit_manager.get_alive_player_units()
	
	if player_units.is_empty():
		return null
	
	var best_target: BattleUnit = null
	var best_score: float = -INF
	
	for target in player_units:
		var score = _evaluate_target(unit, target)
		
		if score > best_score:
			best_score = score
			best_target = target
	
	return best_target

func _evaluate_target(attacker: BattleUnit, target: BattleUnit) -> float:
	"""Évalue l'intérêt d'attaquer une cible"""
	
	var score = 0.0
	
	# Distance (plus proche = mieux)
	var distance = terrain.get_distance(attacker.grid_position, target.grid_position)
	score += (20.0 - distance) * 10.0
	
	# HP bas = priorité
	var hp_percent = target.get_hp_percentage()
	score += (1.0 - hp_percent) * 100.0
	
	# Unités faibles en défense
	score += (50.0 - target.defense_power) * 2.0
	
	return score

func find_best_movement(unit: BattleUnit) -> Vector2i:
	"""Trouve la meilleure position où se déplacer"""
	
	var player_units = unit_manager.get_alive_player_units()
	
	if player_units.is_empty():
		return unit.grid_position
	
	# Trouver l'ennemi le plus proche
	var closest_enemy: BattleUnit = null
	var closest_distance: int = 999999
	
	for player_unit in player_units:
		var dist = terrain.get_distance(unit.grid_position, player_unit.grid_position)
		if dist < closest_distance:
			closest_distance = dist
			closest_enemy = player_unit
	
	if not closest_enemy:
		return unit.grid_position
	
	# Trouver la position qui nous rapproche le plus
	return find_position_to_attack(unit, closest_enemy)

func find_position_to_attack(attacker: BattleUnit, target: BattleUnit) -> Vector2i:
	"""Trouve la meilleure position pour attaquer une cible"""
	
	var reachable = movement_module.calculate_reachable_positions(attacker)
	
	if reachable.is_empty():
		return attacker.grid_position
	
	var best_pos: Vector2i = attacker.grid_position
	var best_distance: int = 999999
	
	for pos in reachable:
		var distance = terrain.get_distance(pos, target.grid_position)
		
		# Si on peut attaquer depuis cette position
		if distance <= attacker.attack_range:
			return pos
		
		# Sinon, garder la plus proche
		if distance < best_distance:
			best_distance = distance
			best_pos = pos
	
	return best_pos

# ============================================================================
# EXÉCUTION DES ACTIONS
# ============================================================================

func _execute_ai_action(unit: BattleUnit, decision: Dictionary) -> void:
	"""Exécute l'action décidée par l'IA"""
	
	match decision.get("action", "wait"):
		"attack":
			var target = decision.get("target")
			if target and action_module.can_attack(unit, target):
				await action_module.execute_attack(unit, target)
				ai_action_taken.emit(unit, "attack")
		
		"ability":
			var ability = decision.get("ability", "")
			var targets = decision.get("targets", [])
			if ability != "":
				await action_module.use_ability(unit, ability, targets)
				ai_action_taken.emit(unit, "ability")
		
		"wait":
			ai_action_taken.emit(unit, "wait")

# ============================================================================
# UTILITAIRES
# ============================================================================

func _sort_by_priority(a: BattleUnit, b: BattleUnit) -> bool:
	"""Trie les unités par priorité (distance aux alliés)"""
	
	var player_units = unit_manager.get_alive_player_units()
	
	if player_units.is_empty():
		return false
	
	# Calculer la distance minimale vers un allié pour chaque unité
	var dist_a = _min_distance_to_players(a, player_units)
	var dist_b = _min_distance_to_players(b, player_units)
	
	return dist_a < dist_b

func _min_distance_to_players(unit: BattleUnit, players: Array) -> int:
	"""Retourne la distance minimale vers les unités joueur"""
	
	var min_dist = 999999
	
	for player in players:
		var dist = terrain.get_distance(unit.grid_position, player.grid_position)
		if dist < min_dist:
			min_dist = dist
	
	return min_dist

# ============================================================================
# DEBUG
# ============================================================================

func set_behavior(behavior: AIBehavior) -> void:
	"""Change le comportement de l'IA"""
	
	default_behavior = behavior
	print("[AIModule] Comportement changé: ", AIBehavior.keys()[behavior])