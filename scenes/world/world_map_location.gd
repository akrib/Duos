# scenes/world/world_map_location.gd
extends Node2D
## WorldMapLocation - Représente un point d'intérêt sur la carte
## Gère l'affichage, l'interaction et le menu d'actions

class_name WorldMapLocation

signal clicked(location: WorldMapLocation)
signal hovered(location: WorldMapLocation)
signal unhovered(location: WorldMapLocation)

# ============================================================================
# PROPRIÉTÉS
# ============================================================================

var location_id: String = ""
var location_name: String = ""
var location_data: Dictionary = {}
var is_unlocked: bool = false
var is_hovered: bool = false

# Visuel
var sprite: Sprite2D
var label: Label
var area: Area2D

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	# ✅ CORRECTION: Ne rien faire si déjà créé dans setup()
	if not sprite:
		_create_visuals()

func setup(data: Dictionary) -> void:
	"""Configure la location avec ses données"""
	
	location_data = data
	location_id = data.get("id", "")
	location_name = data.get("name", "")
	
	# Position
	if data.has("position"):
		var pos = data.position
		if typeof(pos) == TYPE_VECTOR2I:
			position = Vector2(pos.x, pos.y)
		else:
			position = Vector2(pos.get("x", 0), pos.get("y", 0))
	
	# Déverrouillage
	is_unlocked = true  # Sera géré par la world_map
	
	# ✅ CORRECTION: Créer les visuels AVANT de les mettre à jour
	if not sprite:
		_create_visuals()
	
	_update_visuals()

func _create_visuals() -> void:
	"""Crée les éléments visuels"""
	
	# Sprite principal
	sprite = Sprite2D.new()
	sprite.centered = true
	add_child(sprite)
	
	# Label avec le nom
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-50, 50)
	label.custom_minimum_size = Vector2(100, 0)
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)
	
	# Zone de collision pour le clic
	area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 32
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	
	# Signaux
	area.input_event.connect(_on_area_input_event)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)

func _update_visuals() -> void:
	"""Met à jour l'apparence selon l'état"""
	
	# ✅ PROTECTION: Vérifier que les visuels existent
	if not sprite or not label or not area:
		push_warning("[WorldMapLocation] Visuels non initialisés pour: ", location_name)
		return
	
	# Texture
	var icon_path = location_data.get("icon", "res://icon.svg")
	if ResourceLoader.exists(icon_path):
		sprite.texture = load(icon_path)
	
	# Scale
	var scale_value = location_data.get("scale", 1.0)
	sprite.scale = Vector2(scale_value, scale_value)
	
	# Couleur
	if location_data.has("color"):
		var c = location_data.color
		sprite.modulate = Color(c.get("r", 1), c.get("g", 1), c.get("b", 1), c.get("a", 1))
	
	# Nom
	label.text = location_name
	
	# Visibilité selon déverrouillage
	visible = is_unlocked
	
	# Effet hover
	if is_hovered:
		sprite.scale *= 1.1
		label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		label.add_theme_color_override("font_color", Color.WHITE)

func set_unlocked(unlocked: bool) -> void:
	"""Définit si la location est déverrouillée"""
	is_unlocked = unlocked
	_update_visuals()

# ============================================================================
# EVENTS
# ============================================================================

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_unlocked:
			clicked.emit(self)

func _on_mouse_entered() -> void:
	if is_unlocked:
		is_hovered = true
		_update_visuals()
		hovered.emit(self)

func _on_mouse_exited() -> void:
	is_hovered = false
	_update_visuals()
	unhovered.emit(self)

# ============================================================================
# GETTERS
# ============================================================================

func get_location_id() -> String:
	return location_id

func get_location_name() -> String:
	return location_name

func get_connections() -> Array:
	return location_data.get("connections", [])
