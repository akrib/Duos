extends Node
## MovementModule - Gère le déplacement des unités avec pathfinding A*
## Module indépendant et interchangeable

class_name MovementModule

# ============================================================================
# SIGNAUX
# ============================================================================

signal movement_started(unit: BattleUnit)
signal movement_completed(unit: BattleUnit, path: Array)
signal range_shown(positions: Array)
signal range_hidden()

# ============================================================================
# RÉFÉRENCES
# ============================================================================

var terrain: TerrainModule
var unit_manager: UnitManager

# ============================================================================
# VISUELS DE PORTÉE
# ============================================================================

var range_indicators: Array[ColorRect] = []
var path_indicators: Array[ColorRect] = []

# ============================================================================
# CONFIGURATION
# ============================================================================

const RANGE_COLOR: Color = Color(0.3, 0.6, 1.0, 0.3)
const PATH_COLOR: Color = Color(0.2, 0.8, 0.3, 0.5)
const MOVEMENT_SPEED: float = 300.0  # pixels/sec

# ============================================================================
# AFFICHAGE DE PORTÉE
# ============================================================================

func show_movement_range(unit: BattleUnit) -> void:
	"""Affiche les cases accessibles pour une unité"""
	
	hide_ranges()
	
	var reachable = calculate_reachable_positions(unit)
	
	for pos in reachable:
		var indicator = _create_range_indicator(pos, RANGE_COLOR)
		range_indicators.append(indicator)
		terrain.add_child(indicator)
	
	range_shown.emit(reachable)

func show_path_preview(unit: BattleUnit, target: Vector2i) -> void:
	"""Affiche un aperçu du chemin vers une cible"""
	
	# Masquer l'ancien aperçu
	_clear_path_indicators()
	
	# Calculer le chemin
	var path = calculate_path(unit.grid_position, target, unit.movement_range)
	
	if path.is_empty():
		return
	
	# Afficher les indicateurs de chemin
	for pos in path:
		if pos != unit.grid_position:  # Ne pas afficher sur la position actuelle
			var indicator = _create_range_indicator(pos, PATH_COLOR)
			path_indicators.append(indicator)
			terrain.add_child(indicator)

func hide_ranges() -> void:
	"""Masque tous les indicateurs de portée"""
	
	_clear_range_indicators()
	_clear_path_indicators()
	range_hidden.emit()

func _create_range_indicator(grid_pos: Vector2i, color: Color) -> ColorRect:
	"""Crée un indicateur visuel pour une case"""
	
	var rect = ColorRect.new()
	rect.position = Vector2(grid_pos.x * terrain.tile_size, grid_pos.y * terrain.tile_size)
	rect.size = Vector2(terrain.tile_size, terrain.tile_size)
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = 1
	
	return rect

func _clear_range_indicators() -> void:
	"""Nettoie les indicateurs de portée"""
	
	for indicator in range_indicators:
		indicator.queue_free()
	range_indicators.clear()

func _clear_path_indicators() -> void:
	"""Nettoie les indicateurs de chemin"""
	
	for indicator in path_indicators:
		indicator.queue_free()
	path_indicators.clear()

# ============================================================================
# VALIDATION
# ============================================================================

func can_move_to(unit: BattleUnit, target: Vector2i) -> bool:
	"""Vérifie si une unité peut se déplacer vers une position"""
	
	# Vérifier que l'unité peut encore bouger
	if not unit.can_move():
		return false
	
	# Vérifier que la position est dans les limites
	if not terrain.is_in_bounds(target):
		return false
	
	# Vérifier que la case est marchable
	if not terrain.is_walkable(target):
		return false
	
	# Vérifier qu'il n'y a pas d'unité
	if unit_manager.is_position_occupied(target):
		return false
	
	# Vérifier que c'est dans la portée
	var path = calculate_path(unit.grid_position, target, unit.movement_range)
	return not path.is_empty()

# ============================================================================
# MOUVEMENT
# ============================================================================

func move_unit(unit: BattleUnit, target: Vector2i) -> void:
	"""Déplace une unité vers une position avec animation"""
	
	if not can_move_to(unit, target):
		push_warning("[MovementModule] Mouvement invalide")
		return
	
	# Calculer le chemin
	var path = calculate_path(unit.grid_position, target, unit.movement_range)
	
	if path.is_empty():
		return
	
	movement_started.emit(unit)
	
	# Animer le déplacement
	await _animate_movement(unit, path)
	
	# Mettre à jour la position
	unit_manager.move_unit(unit, target)
	
	# Masquer les indicateurs
	hide_ranges()
	
	movement_completed.emit(unit, path)
	
	print("[MovementModule] ", unit.unit_name, " déplacé de ", unit.grid_position, " à ", target)

func _animate_movement(unit: BattleUnit, path: Array) -> void:
	"""Anime le déplacement le long d'un chemin"""
	
	for i in range(1, path.size()):
		var next_pos = path[i]
		var world_pos = Vector2(next_pos.x * terrain.tile_size, next_pos.y * terrain.tile_size)
		
		var distance = unit.position.distance_to(world_pos)
		var duration = distance / MOVEMENT_SPEED
		
		var tween = unit.create_tween()
		tween.tween_property(unit, "position", world_pos, duration).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		
		# Petite pause entre chaque case
		await unit.get_tree().create_timer(0.05).timeout

# ============================================================================
# PATHFINDING - CALCUL DE PORTÉE
# ============================================================================

func calculate_reachable_positions(unit: BattleUnit) -> Array[Vector2i]:
	"""Calcule toutes les positions accessibles depuis la position d'une unité"""
	
	var start = unit.grid_position
	var max_movement = unit.movement_range
	
	var reachable: Array[Vector2i] = []
	var visited: Dictionary = {start: 0}  # position -> cost_used
	var frontier: Array = [start]
	
	while not frontier.is_empty():
		var current = frontier.pop_front()
		var current_cost = visited[current]
		
		# Explorer les voisins
		for neighbor in terrain.get_neighbors(current):
			# Vérifier que c'est marchable
			if not terrain.is_walkable(neighbor):
				continue
			
			# Calculer le coût
			var move_cost = terrain.get_movement_cost(neighbor)
			var new_cost = current_cost + move_cost
			
			# Si on dépasse la portée, ignorer
			if new_cost > max_movement:
				continue
			
			# Si déjà visité avec un meilleur coût, ignorer
			if visited.has(neighbor) and visited[neighbor] <= new_cost:
				continue
			
			# Vérifier qu'il n'y a pas d'unité (sauf si c'est notre position de départ)
			if neighbor != start and unit_manager.is_position_occupied(neighbor):
				continue
			
			# Ajouter à la liste
			visited[neighbor] = new_cost
			frontier.append(neighbor)
	
	# Retourner toutes les positions accessibles (sauf le départ)
	for pos in visited.keys():
		if pos != start:
			reachable.append(pos)
	
	return reachable

# ============================================================================
# PATHFINDING - A*
# ============================================================================

func calculate_path(from: Vector2i, to: Vector2i, max_movement: float) -> Array:
	"""Calcule le chemin optimal de from à to avec pathfinding A*"""
	
	# Si même position
	if from == to:
		return [from]
	
	# Structures A*
	var open_set: Array[Vector2i] = [from]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {from: 0.0}
	var f_score: Dictionary = {from: _heuristic(from, to)}
	
	while not open_set.is_empty():
		# Trouver le nœud avec le plus petit f_score
		var current = _get_lowest_f_score(open_set, f_score)
		
		# Si on a atteint la destination
		if current == to:
			return _reconstruct_path(came_from, current)
		
		open_set.erase(current)
		
		# Explorer les voisins
		for neighbor in terrain.get_neighbors(current):
			# Ignorer si non marchable
			if not terrain.is_walkable(neighbor):
				continue
			
			# Ignorer si occupé (sauf si c'est la destination)
			if neighbor != to and unit_manager.is_position_occupied(neighbor):
				continue
			
			# Calculer le nouveau g_score
			var move_cost = terrain.get_movement_cost(neighbor)
			var tentative_g_score = g_score[current] + move_cost
			
			# Si on dépasse le mouvement max, ignorer (sauf si c'est la destination)
			if neighbor != to and tentative_g_score > max_movement:
				continue
			
			# Si on a trouvé un meilleur chemin
			if not g_score.has(neighbor) or tentative_g_score < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + _heuristic(neighbor, to)
				
				if neighbor not in open_set:
					open_set.append(neighbor)
	
	# Aucun chemin trouvé
	return []

func _heuristic(from: Vector2i, to: Vector2i) -> float:
	"""Heuristique (distance Manhattan)"""
	
	return abs(to.x - from.x) + abs(to.y - from.y)

func _get_lowest_f_score(open_set: Array, f_score: Dictionary) -> Vector2i:
	"""Trouve le nœud avec le plus petit f_score dans open_set"""
	
	var lowest = open_set[0]
	var lowest_score = f_score.get(lowest, INF)
	
	for node in open_set:
		var score = f_score.get(node, INF)
		if score < lowest_score:
			lowest = node
			lowest_score = score
	
	return lowest

func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array:
	"""Reconstruit le chemin depuis came_from"""
	
	var path: Array[Vector2i] = [current]
	
	while came_from.has(current):
		current = came_from[current]
		path.insert(0, current)
	
	return path

# ============================================================================
# CALCULS UTILITAIRES
# ============================================================================

func get_movement_cost_for_path(path: Array) -> float:
	"""Calcule le coût total d'un chemin"""
	
	var total_cost = 0.0
	
	for pos in path:
		if typeof(pos) == TYPE_VECTOR2I:
			total_cost += terrain.get_movement_cost(pos)
	
	return total_cost

func get_path_length(path: Array) -> int:
	"""Retourne la longueur d'un chemin"""
	
	return path.size() - 1  # -1 car la position de départ ne compte pas

# ============================================================================
# NETTOYAGE
# ============================================================================

func clear() -> void:
	"""Nettoie tous les indicateurs"""
	
	hide_ranges()
	print("[MovementModule] Nettoyé")

# ============================================================================
# DEBUG
# ============================================================================

func print_path(path: Array) -> void:
	"""Affiche un chemin dans la console (debug)"""
	
	print("\n=== CHEMIN ===")
	print("Longueur: ", get_path_length(path))
	print("Coût: ", get_movement_cost_for_path(path))
	print("Positions: ", path)
	print("==============\n")