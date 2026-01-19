extends Node2D
## TerrainModule - Gère le terrain, la grille et les tuiles
## Module indépendant et interchangeable

class_name TerrainModule

# ============================================================================
# SIGNAUX
# ============================================================================

signal generation_complete()
signal tile_changed(grid_pos: Vector2i, tile_type: int)

# ============================================================================
# ENUMS
# ============================================================================

enum TileType {
	GRASS,       # Plaine - Movement cost: 1
	FOREST,      # Forêt - Movement cost: 2, Defense: +10
	MOUNTAIN,    # Montagne - Movement cost: 3, Defense: +20
	WATER,       # Eau - Movement cost: INF (infranchissable)
	ROAD,        # Route - Movement cost: 0.5
	WALL,        # Mur - Movement cost: INF
	BRIDGE,      # Pont - Movement cost: 1
	CASTLE,      # Château - Movement cost: 1, Defense: +30
}

# ============================================================================
# CONFIGURATION
# ============================================================================

var tile_size: int = 48
var grid_width: int = 20
var grid_height: int = 15

# Coûts de mouvement par type de tuile
const MOVEMENT_COSTS: Dictionary = {
	TileType.GRASS: 1.0,
	TileType.FOREST: 2.0,
	TileType.MOUNTAIN: 3.0,
	TileType.WATER: INF,
	TileType.ROAD: 0.5,
	TileType.WALL: INF,
	TileType.BRIDGE: 1.0,
	TileType.CASTLE: 1.0,
}

# Bonus de défense par type de tuile
const DEFENSE_BONUS: Dictionary = {
	TileType.GRASS: 0,
	TileType.FOREST: 10,
	TileType.MOUNTAIN: 20,
	TileType.WATER: 0,
	TileType.ROAD: 0,
	TileType.WALL: 0,
	TileType.BRIDGE: 0,
	TileType.CASTLE: 30,
}

# Couleurs des tuiles (pour ColorRect)
const TILE_COLORS: Dictionary = {
	TileType.GRASS: Color(0.2, 0.7, 0.2),      # Vert
	TileType.FOREST: Color(0.1, 0.5, 0.1),     # Vert foncé
	TileType.MOUNTAIN: Color(0.5, 0.5, 0.5),   # Gris
	TileType.WATER: Color(0.2, 0.4, 0.8),      # Bleu
	TileType.ROAD: Color(0.6, 0.5, 0.4),       # Marron clair
	TileType.WALL: Color(0.3, 0.3, 0.3),       # Gris foncé
	TileType.BRIDGE: Color(0.5, 0.4, 0.3),     # Marron
	TileType.CASTLE: Color(0.7, 0.7, 0.8),     # Gris clair
}

# ============================================================================
# DONNÉES
# ============================================================================

var grid: Array[Array] = []  # Array 2D de TileType
var tile_visuals: Array[Array] = []  # Array 2D de ColorRect

# ============================================================================
# PRESETS
# ============================================================================

const PRESETS: Dictionary = {
	"plains": {
		"base": TileType.GRASS,
		"features": [
			{"type": TileType.FOREST, "density": 0.1},
			{"type": TileType.ROAD, "density": 0.05}
		]
	},
	"forest": {
		"base": TileType.FOREST,
		"features": [
			{"type": TileType.GRASS, "density": 0.2},
			{"type": TileType.MOUNTAIN, "density": 0.05}
		]
	},
	"castle": {
		"base": TileType.GRASS,
		"features": [
			{"type": TileType.CASTLE, "positions": [Vector2i(10, 7)]},
			{"type": TileType.WALL, "density": 0.15},
			{"type": TileType.ROAD, "density": 0.1}
		]
	},
	"mountain": {
		"base": TileType.MOUNTAIN,
		"features": [
			{"type": TileType.GRASS, "density": 0.15},
			{"type": TileType.FOREST, "density": 0.1},
			{"type": TileType.ROAD, "density": 0.05}
		]
	}
}

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	_initialize_grid()
	print("[TerrainModule] Initialisé (", grid_width, "x", grid_height, ")")

func _initialize_grid() -> void:
	"""Initialise la grille vide"""
	
	grid.clear()
	tile_visuals.clear()
	
	# Créer la grille de données
	for y in range(grid_height):
		var row: Array[int] = []
		var visual_row: Array = []
		
		for x in range(grid_width):
			row.append(TileType.GRASS)
			visual_row.append(null)
		
		grid.append(row)
		tile_visuals.append(visual_row)

# ============================================================================
# CHARGEMENT
# ============================================================================

func load_preset(preset_name: String) -> void:
	"""Charge un terrain prédéfini"""
	
	if not PRESETS.has(preset_name):
		push_error("[TerrainModule] Preset introuvable: ", preset_name)
		return
	
	var preset = PRESETS[preset_name]
	_generate_from_preset(preset)
	_create_visuals()
	
	print("[TerrainModule] Preset chargé: ", preset_name)
	
	# ✅ Émettre le signal au prochain frame pour que le await ait le temps de s'installer
#	await get_tree().process_frame
#	generation_complete.emit()

func load_custom(terrain_data: Dictionary) -> void:
	"""Charge un terrain personnalisé"""
	
	if terrain_data.has("grid"):
		# Charger directement depuis une grille prédéfinie
		_load_from_grid(terrain_data.grid)
	elif terrain_data.has("base") and terrain_data.has("features"):
		# Générer depuis un preset personnalisé
		_generate_from_preset(terrain_data)
	else:
		push_error("[TerrainModule] Format de terrain invalide")
		return
	
	_create_visuals()
	generation_complete.emit()
	print("[TerrainModule] Terrain personnalisé chargé")

func _generate_from_preset(preset: Dictionary) -> void:
	"""Génère le terrain depuis un preset"""
	
	# 1. Remplir avec le type de base
	var base_type = preset.get("base", TileType.GRASS)
	for y in range(grid_height):
		for x in range(grid_width):
			grid[y][x] = base_type
	
	# 2. Ajouter les features
	for feature in preset.get("features", []):
		_add_feature(feature)

func _add_feature(feature: Dictionary) -> void:
	"""Ajoute une feature au terrain"""
	
	var tile_type = feature.get("type", TileType.GRASS)
	
	# Si des positions spécifiques sont données
	if feature.has("positions"):
		for pos in feature.positions:
			if _is_valid_position(pos):
				grid[pos.y][pos.x] = tile_type
		return
	
	# Sinon, placement aléatoire selon la densité
	var density = feature.get("density", 0.1)
	for y in range(grid_height):
		for x in range(grid_width):
			if randf() < density:
				grid[y][x] = tile_type

func _load_from_grid(grid_data: Array) -> void:
	"""Charge depuis une grille prédéfinie"""
	
	for y in range(min(grid_height, grid_data.size())):
		for x in range(min(grid_width, grid_data[y].size())):
			grid[y][x] = grid_data[y][x]

# ============================================================================
# VISUELS
# ============================================================================

func _create_visuals() -> void:
	"""Crée les visuels (ColorRect) pour chaque tuile"""
	
	# Nettoyer les anciens visuels
	for child in get_children():
		child.queue_free()
	
	# Créer les nouveaux
	for y in range(grid_height):
		for x in range(grid_width):
			var tile_rect = _create_tile_visual(Vector2i(x, y))
			tile_visuals[y][x] = tile_rect
			add_child(tile_rect)

func _create_tile_visual(grid_pos: Vector2i) -> ColorRect:
	"""Crée le visuel d'une tuile"""
	
	var rect = ColorRect.new()
	var tile_type = grid[grid_pos.y][grid_pos.x]
	
	# Position et taille
	rect.position = Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)
	rect.size = Vector2(tile_size, tile_size)
	
	# Couleur
	rect.color = TILE_COLORS.get(tile_type, Color.WHITE)
	
	# Bordure
	var border = ColorRect.new()
	border.position = Vector2(1, 1)
	border.size = rect.size - Vector2(2, 2)
	border.color = rect.color.darkened(0.2)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.add_child(border)
	
	# Label de debug (optionnel)
	if OS.is_debug_build():
		var label = Label.new()
		label.text = str(grid_pos.x) + "," + str(grid_pos.y)
		label.add_theme_font_size_override("font_size", 10)
		label.modulate = Color(0, 0, 0, 0.5)
		label.position = Vector2(2, 2)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.add_child(label)
	
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	return rect

func update_tile_visual(grid_pos: Vector2i) -> void:
	"""Met à jour le visuel d'une tuile"""
	
	if not _is_valid_position(grid_pos):
		return
	
	var old_visual = tile_visuals[grid_pos.y][grid_pos.x]
	if old_visual:
		old_visual.queue_free()
	
	var new_visual = _create_tile_visual(grid_pos)
	tile_visuals[grid_pos.y][grid_pos.x] = new_visual
	add_child(new_visual)

# ============================================================================
# GETTERS
# ============================================================================

func get_tile_type(grid_pos: Vector2i) -> int:
	"""Retourne le type de tuile à une position"""
	
	if not _is_valid_position(grid_pos):
		return TileType.WALL
	
	return grid[grid_pos.y][grid_pos.x]

func get_movement_cost(grid_pos: Vector2i) -> float:
	"""Retourne le coût de mouvement d'une tuile"""
	
	var tile_type = get_tile_type(grid_pos)
	return MOVEMENT_COSTS.get(tile_type, 1.0)

func get_defense_bonus(grid_pos: Vector2i) -> int:
	"""Retourne le bonus de défense d'une tuile"""
	
	var tile_type = get_tile_type(grid_pos)
	return DEFENSE_BONUS.get(tile_type, 0)

func is_walkable(grid_pos: Vector2i) -> bool:
	"""Vérifie si une tuile est franchissable"""
	
	return get_movement_cost(grid_pos) < INF

func is_in_bounds(grid_pos: Vector2i) -> bool:
	"""Vérifie si une position est dans les limites"""
	
	return grid_pos.x >= 0 and grid_pos.x < grid_width and \
		   grid_pos.y >= 0 and grid_pos.y < grid_height

# ============================================================================
# SETTERS
# ============================================================================

func set_tile_type(grid_pos: Vector2i, tile_type: int) -> void:
	"""Change le type d'une tuile"""
	
	if not _is_valid_position(grid_pos):
		return
	
	grid[grid_pos.y][grid_pos.x] = tile_type
	update_tile_visual(grid_pos)
	tile_changed.emit(grid_pos, tile_type)

# ============================================================================
# PATHFINDING HELPERS
# ============================================================================

func get_neighbors(grid_pos: Vector2i) -> Array[Vector2i]:
	"""Retourne les cases adjacentes valides (4 directions)"""
	
	var neighbors: Array[Vector2i] = []
	var directions = [
		Vector2i(1, 0),   # Droite
		Vector2i(-1, 0),  # Gauche
		Vector2i(0, 1),   # Bas
		Vector2i(0, -1)   # Haut
	]
	
	for dir in directions:
		var neighbor = grid_pos + dir
		if is_in_bounds(neighbor):
			neighbors.append(neighbor)
	
	return neighbors

func get_all_neighbors(grid_pos: Vector2i) -> Array[Vector2i]:
	"""Retourne toutes les cases adjacentes (8 directions)"""
	
	var neighbors: Array[Vector2i] = []
	
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			
			var neighbor = grid_pos + Vector2i(dx, dy)
			if is_in_bounds(neighbor):
				neighbors.append(neighbor)
	
	return neighbors

func get_distance(from: Vector2i, to: Vector2i) -> int:
	"""Retourne la distance Manhattan entre deux positions"""
	
	return abs(to.x - from.x) + abs(to.y - from.y)

# ============================================================================
# UTILITAIRES
# ============================================================================

func _is_valid_position(grid_pos: Vector2i) -> bool:
	"""Vérifie si une position est valide"""
	
	return is_in_bounds(grid_pos)

func get_random_walkable_position() -> Vector2i:
	"""Retourne une position marchable aléatoire"""
	
	for attempt in range(100):
		var pos = Vector2i(randi() % grid_width, randi() % grid_height)
		if is_walkable(pos):
			return pos
	
	# Fallback
	return Vector2i(0, 0)

func clear() -> void:
	"""Nettoie le terrain"""
	
	for child in get_children():
		child.queue_free()
	
	_initialize_grid()
	print("[TerrainModule] Terrain nettoyé")

# ============================================================================
# DEBUG
# ============================================================================

func print_grid() -> void:
	"""Affiche la grille dans la console (debug)"""
	
	print("\n=== TERRAIN GRID ===")
	for y in range(grid_height):
		var line = ""
		for x in range(grid_width):
			var tile = grid[y][x]
			match tile:
				TileType.GRASS: line += "."
				TileType.FOREST: line += "T"
				TileType.MOUNTAIN: line += "^"
				TileType.WATER: line += "~"
				TileType.ROAD: line += "="
				TileType.WALL: line += "#"
				TileType.BRIDGE: line += "-"
				TileType.CASTLE: line += "C"
				_: line += "?"
		print(line)
	print("====================\n")
