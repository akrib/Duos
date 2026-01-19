extends Node3D
## UnitManager3D - Gère toutes les unités du combat en 3D

class_name UnitManager3D

# ============================================================================
# SIGNAUX
# ============================================================================

signal unit_spawned(unit: BattleUnit3D)
signal unit_died(unit: BattleUnit3D)
signal unit_moved(unit: BattleUnit3D, from: Vector2i, to: Vector2i)

# ============================================================================
# CONFIGURATION
# ============================================================================

var tile_size: float = 1.0
var terrain: TerrainModule3D

# ============================================================================
# DONNÉES
# ============================================================================

var all_units: Array[BattleUnit3D] = []
var player_units: Array[BattleUnit3D] = []
var enemy_units: Array[BattleUnit3D] = []
var unit_grid: Dictionary = {}  # Vector2i -> BattleUnit3D

# ============================================================================
# SPAWNING
# ============================================================================

func spawn_unit(unit_data: Dictionary, is_player: bool) -> BattleUnit3D:
	"""Spawne une unité 3D sur le terrain"""
	
	var unit = BattleUnit3D.new()
	
	# Configuration
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
	
	# Capacités
	unit.abilities = unit_data.get("abilities", [])
	
	# Position
	var spawn_pos = unit_data.get("position", Vector2i(0, 0))
	unit.grid_position = spawn_pos
	unit.position = _grid_to_world_3d(spawn_pos)
	
	# Ajouter à la scène
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
	print("[UnitManager3D] Unité spawnée: ", unit.unit_name, " à ", spawn_pos)
	
	return unit

# ============================================================================
# GETTERS
# ============================================================================

func get_unit_at(grid_pos: Vector2i) -> BattleUnit3D:
	return unit_grid.get(grid_pos, null)

func get_all_units() -> Array[BattleUnit3D]:
	return all_units.duplicate()

func get_player_units() -> Array[BattleUnit3D]:
	return player_units.duplicate()

func get_enemy_units() -> Array[BattleUnit3D]:
	return enemy_units.duplicate()

func get_alive_player_units() -> Array[BattleUnit3D]:
	return player_units.filter(func(u): return u.is_alive())

func get_alive_enemy_units() -> Array[BattleUnit3D]:
	return enemy_units.filter(func(u): return u.is_alive())

func is_position_occupied(grid_pos: Vector2i) -> bool:
	return unit_grid.has(grid_pos)

# ============================================================================
# MOUVEMENT 3D
# ============================================================================

func move_unit(unit: BattleUnit3D, new_pos: Vector2i) -> void:
	"""Déplace une unité vers une nouvelle position"""
	
	var old_pos = unit.grid_position
	
	# Retirer de l'ancienne position
	unit_grid.erase(old_pos)
	
	# Mettre à jour la position
	unit.grid_position = new_pos
	unit.position = _grid_to_world_3d(new_pos)
	
	# Ajouter à la nouvelle position
	unit_grid[new_pos] = unit
	
	unit_moved.emit(unit, old_pos, new_pos)

# ============================================================================
# TOURS
# ============================================================================

func reset_player_units() -> void:
	for unit in player_units:
		if unit.is_alive():
			unit.reset_for_new_turn()

func reset_enemy_units() -> void:
	for unit in enemy_units:
		if unit.is_alive():
			unit.reset_for_new_turn()

# ============================================================================
# MORT & SUPPRESSION
# ============================================================================

func _on_unit_died(unit: BattleUnit3D) -> void:
	unit_grid.erase(unit.grid_position)
	all_units.erase(unit)
	player_units.erase(unit)
	enemy_units.erase(unit)
	
	unit_died.emit(unit)
	print("[UnitManager3D] Unité morte: ", unit.unit_name)

func remove_unit(unit: BattleUnit3D) -> void:
	if unit in all_units:
		unit_grid.erase(unit.grid_position)
		all_units.erase(unit)
		player_units.erase(unit)
		enemy_units.erase(unit)
		unit.queue_free()

func clear_all_units() -> void:
	for unit in all_units.duplicate():
		remove_unit(unit)
	unit_grid.clear()
	print("[UnitManager3D] Toutes les unités supprimées")

# ============================================================================
# UTILITAIRES 3D
# ============================================================================

func _grid_to_world_3d(grid_pos: Vector2i) -> Vector3:
	"""Convertit une position grille en position monde 3D"""
	if terrain:
		var world_2d = terrain.grid_to_world(grid_pos)
		return Vector3(world_2d.x, 0, world_2d.y)
	
	# Fallback si pas de terrain
	var offset_x = (20 - 1) * tile_size / 2.0
	var offset_z = (15 - 1) * tile_size / 2.0
	return Vector3(
		grid_pos.x * tile_size - offset_x,
		0,
		grid_pos.y * tile_size - offset_z
	)
