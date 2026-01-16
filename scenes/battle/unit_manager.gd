extends Node2D
## UnitManager - Gère toutes les unités du combat
## Spawning, tracking, mort, etc.

class_name UnitManager

# ============================================================================
# SIGNAUX
# ============================================================================

signal unit_spawned(unit: BattleUnit)
signal unit_died(unit: BattleUnit)
signal unit_moved(unit: BattleUnit, from: Vector2i, to: Vector2i)

# ============================================================================
# CONFIGURATION
# ============================================================================

var tile_size: int = 48

# ============================================================================
# DONNÉES
# ============================================================================

var all_units: Array[BattleUnit] = []
var player_units: Array[BattleUnit] = []
var enemy_units: Array[BattleUnit] = []
var unit_grid: Dictionary = {}  # Vector2i -> BattleUnit

# ============================================================================
# SPAWNING
# ============================================================================

func spawn_unit(unit_data: Dictionary, is_player: bool) -> BattleUnit:
	"""
	Spawne une unité sur le terrain
	
	Format unit_data:
	{
		"name": "Knight",
		"position": Vector2i(5, 3),
		"stats": {
			"hp": 100,
			"attack": 20,
			"defense": 15,
			"movement": 5,
			"range": 1
		},
		"color": Color(0.2, 0.2, 0.8),  # Optionnel
		"abilities": ["Shield Bash", "Charge"]  # Optionnel
	}
	"""
	
	var unit = BattleUnit.new()
	
	# Configuration de base
	unit.unit_name = unit_data.get("name", "Unit")
	unit.is_player_unit = is_player
	unit.tile_size = tile_size
	
	# Stats
	var stats = unit_data.get("stats", {})
	unit.max_hp = stats.get("hp", 100)
	unit.current_hp = unit.max_hp
	unit.attack_power = stats.get("attack", 20)
	unit.defense_power = stats.get("defense", 10)
	unit.movement_range = stats.get("movement", 5)
	unit.attack_range = stats.get("range", 1)
	
	# Apparence
	if unit_data.has("color"):
		unit.unit_color = unit_data.color
	else:
		unit.unit_color = Color(0.2, 0.2, 0.8) if is_player else Color(0.8, 0.2, 0.2)
	
	# Capacités spéciales
	unit.abilities = unit_data.get("abilities", [])
	
	# Position
	var spawn_pos = unit_data.get("position", Vector2i(0, 0))
	unit.grid_position = spawn_pos
	unit.position = _grid_to_world(spawn_pos)
	
	# Ajouter à la scène et aux listes
	add_child(unit)
	all_units.append(unit)
	
	if is_player:
		player_units.append(unit)
	else:
		enemy_units.append(unit)
	
	unit_grid[spawn_pos] = unit
	
	# Connexions
	unit.died.connect(_on_unit_died.bind(unit))
	
	unit_spawned.emit(unit)
	print("[UnitManager] Unité spawnée: ", unit.unit_name, " à ", spawn_pos)
	
	return unit

# ============================================================================
# GETTERS
# ============================================================================

func get_unit_at(grid_pos: Vector2i) -> BattleUnit:
	"""Retourne l'unité à une position donnée"""
	
	return unit_grid.get(grid_pos, null)

func get_all_units() -> Array[BattleUnit]:
	"""Retourne toutes les unités"""
	
	return all_units.duplicate()

func get_player_units() -> Array[BattleUnit]:
	"""Retourne toutes les unités joueur"""
	
	return player_units.duplicate()

func get_enemy_units() -> Array[BattleUnit]:
	"""Retourne toutes les unités ennemies"""
	
	return enemy_units.duplicate()

func get_alive_player_units() -> Array[BattleUnit]:
	"""Retourne les unités joueur vivantes"""
	
	return player_units.filter(func(u): return u.is_alive())

func get_alive_enemy_units() -> Array[BattleUnit]:
	"""Retourne les unités ennemies vivantes"""
	
	return enemy_units.filter(func(u): return u.is_alive())

func get_units_in_range(center: Vector2i, range: int) -> Array[BattleUnit]:
	"""Retourne toutes les unités dans un rayon donné"""
	
	var units_in_range: Array[BattleUnit] = []
	
	for unit in all_units:
		if not unit.is_alive():
			continue
		
		var distance = abs(unit.grid_position.x - center.x) + abs(unit.grid_position.y - center.y)
		if distance <= range:
			units_in_range.append(unit)
	
	return units_in_range

func get_enemies_of(unit: BattleUnit) -> Array[BattleUnit]:
	"""Retourne les ennemis d'une unité"""
	
	if unit.is_player_unit:
		return get_alive_enemy_units()
	else:
		return get_alive_player_units()

# ============================================================================
# MOUVEMENT
# ============================================================================

func move_unit(unit: BattleUnit, new_pos: Vector2i) -> void:
	"""Déplace une unité vers une nouvelle position"""
	
	var old_pos = unit.grid_position
	
	# Retirer de l'ancienne position
	unit_grid.erase(old_pos)
	
	# Mettre à jour la position
	unit.grid_position = new_pos
	unit.position = _grid_to_world(new_pos)
	
	# Ajouter à la nouvelle position
	unit_grid[new_pos] = unit
	
	unit_moved.emit(unit, old_pos, new_pos)

func is_position_occupied(grid_pos: Vector2i) -> bool:
	"""Vérifie si une position est occupée"""
	
	return unit_grid.has(grid_pos)

# ============================================================================
# GESTION DES TOURS
# ============================================================================

func reset_player_units() -> void:
	"""Réinitialise toutes les unités joueur pour un nouveau tour"""
	
	for unit in player_units:
		if unit.is_alive():
			unit.reset_for_new_turn()

func reset_enemy_units() -> void:
	"""Réinitialise toutes les unités ennemies pour un nouveau tour"""
	
	for unit in enemy_units:
		if unit.is_alive():
			unit.reset_for_new_turn()

func reset_all_units() -> void:
	"""Réinitialise toutes les unités"""
	
	reset_player_units()
	reset_enemy_units()

# ============================================================================
# MORT ET SUPPRESSION
# ============================================================================

func _on_unit_died(unit: BattleUnit) -> void:
	"""Callback quand une unité meurt"""
	
	# Retirer de la grille
	unit_grid.erase(unit.grid_position)
	
	# Retirer des listes
	all_units.erase(unit)
	player_units.erase(unit)
	enemy_units.erase(unit)
	
	unit_died.emit(unit)
	print("[UnitManager] Unité morte: ", unit.unit_name)

func remove_unit(unit: BattleUnit) -> void:
	"""Supprime complètement une unité"""
	
	if unit in all_units:
		unit_grid.erase(unit.grid_position)
		all_units.erase(unit)
		player_units.erase(unit)
		enemy_units.erase(unit)
		unit.queue_free()

func clear_all_units() -> void:
	"""Supprime toutes les unités"""
	
	for unit in all_units.duplicate():
		remove_unit(unit)
	
	unit_grid.clear()
	print("[UnitManager] Toutes les unités supprimées")

# ============================================================================
# UTILITAIRES
# ============================================================================

func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	"""Convertit une position grille en position monde"""
	
	return Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)

func get_unit_count() -> Dictionary:
	"""Retourne le nombre d'unités"""
	
	return {
		"total": all_units.size(),
		"player": player_units.size(),
		"enemy": enemy_units.size(),
		"player_alive": get_alive_player_units().size(),
		"enemy_alive": get_alive_enemy_units().size()
	}

# ============================================================================
# DEBUG
# ============================================================================

func print_units() -> void:
	"""Affiche toutes les unités (debug)"""
	
	print("\n=== UNITÉS ===")
	print("Joueur (", player_units.size(), "):")
	for unit in player_units:
		var status = "ALIVE" if unit.is_alive() else "DEAD"
		print("  - ", unit.unit_name, " [", status, "] HP:", unit.current_hp, "/", unit.max_hp, " @", unit.grid_position)
	
	print("\nEnnemis (", enemy_units.size(), "):")
	for unit in enemy_units:
		var status = "ALIVE" if unit.is_alive() else "DEAD"
		print("  - ", unit.unit_name, " [", status, "] HP:", unit.current_hp, "/", unit.max_hp, " @", unit.grid_position)
	print("==============\n")
