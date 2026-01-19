extends Node3D
## BattleUnit3D - Unité de combat avec sprite billboard
## Version 3D utilisant Sprite3D qui fait toujours face à la caméra

class_name BattleUnit3D

# ============================================================================
# SIGNAUX (identiques à la version 2D)
# ============================================================================

signal died()
signal health_changed(new_hp: int, max_hp: int)
signal selected_changed(is_selected: bool)
signal status_effect_applied(effect_name: String)
signal status_effect_removed(effect_name: String)

# ============================================================================
# CONFIGURATION
# ============================================================================

var tile_size: float = 1.0
var sprite_height: float = 1.0  # Hauteur du sprite au-dessus du sol

# ============================================================================
# IDENTITÉ
# ============================================================================

var unit_name: String = "Unit"
var is_player_unit: bool = false
var unit_id: String = ""

# ============================================================================
# STATS (identiques)
# ============================================================================

var max_hp: int = 100
var current_hp: int = 100
var attack_power: int = 20
var defense_power: int = 10
var movement_range: int = 5
var attack_range: int = 1

# ============================================================================
# ÉTAT
# ============================================================================

var movement_used: bool = false
var action_used: bool = false
var has_acted_this_turn: bool = false
var grid_position: Vector2i = Vector2i(0, 0)

# ============================================================================
# CAPACITÉS & EFFETS
# ============================================================================

var abilities: Array[String] = []
var status_effects: Dictionary = {}

# ============================================================================
# APPARENCE
# ============================================================================

var unit_color: Color = Color.BLUE
var is_selected: bool = false

# Visuels 3D
var sprite_3d: Sprite3D
var hp_bar_3d: MeshInstance3D
var selection_indicator: MeshInstance3D
var shadow_sprite: Sprite3D

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	if unit_id == "":
		unit_id = unit_name + "_" + str(Time.get_ticks_msec())
	
	_create_visuals_3d()
	_update_hp_bar()

func _create_visuals_3d() -> void:
	"""Crée tous les éléments visuels 3D de l'unité"""
	
	# 1. OMBRE AU SOL (Sprite3D horizontal)
	shadow_sprite = Sprite3D.new()
	shadow_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	shadow_sprite.texture = _create_circle_texture(64, Color(0, 0, 0, 0.3))
	shadow_sprite.pixel_size = 0.01
	shadow_sprite.rotation.x = -PI / 2  # Horizontal
	shadow_sprite.position.y = 0.05
	add_child(shadow_sprite)
	
	# 2. SPRITE PRINCIPAL (Billboard)
	sprite_3d = Sprite3D.new()
	sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite_3d.texture = _create_unit_texture()
	sprite_3d.pixel_size = 0.005
	sprite_3d.position.y = sprite_height
	add_child(sprite_3d)
	
	# 3. INDICATEUR DE SÉLECTION (anneau au sol)
	selection_indicator = _create_selection_ring()
	selection_indicator.visible = false
	add_child(selection_indicator)
	
	# 4. BARRE DE HP (au-dessus du sprite)
	hp_bar_3d = _create_hp_bar_3d()
	add_child(hp_bar_3d)
	
	# 5. INDICATEUR D'ÉQUIPE (petit cube)
	var team_indicator = _create_team_indicator()
	add_child(team_indicator)
	
	# 6. COLLISION POUR LE RAYCASTING
	_create_collision()

func _create_unit_texture() -> ImageTexture:
	"""Crée une texture simple pour le sprite de l'unité"""
	var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Dessiner un cercle coloré (représentation simple)
	for y in range(128):
		for x in range(128):
			var dx = x - 64
			var dy = y - 64
			var dist = sqrt(dx*dx + dy*dy)
			
			if dist < 50:
				var alpha = 1.0 - (dist / 50.0) * 0.3
				image.set_pixel(x, y, Color(unit_color.r, unit_color.g, unit_color.b, alpha))
			
			# Contour plus foncé
			if dist > 45 and dist < 50:
				image.set_pixel(x, y, unit_color.darkened(0.5))
	
	return ImageTexture.create_from_image(image)

func _create_circle_texture(size: int, color: Color) -> ImageTexture:
	"""Crée une texture circulaire"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = size / 2
	for y in range(size):
		for x in range(size):
			var dx = x - center
			var dy = y - center
			var dist = sqrt(dx*dx + dy*dy)
			
			if dist < center:
				var alpha = color.a * (1.0 - dist / center)
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	return ImageTexture.create_from_image(image)

func _create_selection_ring() -> MeshInstance3D:
	"""Crée un anneau de sélection au sol"""
	var mesh_instance = MeshInstance3D.new()
	
	# Utiliser un TorusMesh pour l'anneau
	var torus = TorusMesh.new()
	torus.inner_radius = tile_size * 0.4
	torus.outer_radius = tile_size * 0.5
	torus.rings = 16
	torus.ring_segments = 32
	
	mesh_instance.mesh = torus
	mesh_instance.rotation.x = PI / 2  # Horizontal
	mesh_instance.position.y = 0.1
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	material.emission_enabled = true
	material.emission = Color.YELLOW * 0.5
	mesh_instance.set_surface_override_material(0, material)
	
	return mesh_instance

func _create_hp_bar_3d() -> MeshInstance3D:
	"""Crée une barre de HP 3D au-dessus du sprite"""
	var mesh_instance = MeshInstance3D.new()
	
	var box = BoxMesh.new()
	box.size = Vector3(tile_size * 0.8, 0.05, 0.1)
	mesh_instance.mesh = box
	
	mesh_instance.position = Vector3(0, sprite_height + 0.6, 0)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GREEN
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.set_surface_override_material(0, material)
	
	# Rendre le billboard pour que la barre soit toujours visible
	mesh_instance.top_level = false
	
	return mesh_instance

func _create_team_indicator() -> MeshInstance3D:
	"""Crée un petit cube indicateur d'équipe"""
	var mesh_instance = MeshInstance3D.new()
	
	var box = BoxMesh.new()
	box.size = Vector3(0.15, 0.15, 0.15)
	mesh_instance.mesh = box
	
	mesh_instance.position = Vector3(tile_size * 0.35, sprite_height + 0.3, 0)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GREEN if is_player_unit else Color.RED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.set_surface_override_material(0, material)
	
	return mesh_instance

func _create_collision() -> void:
	"""Crée une collision pour le raycasting"""
	var area = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	
	var shape = CylinderShape3D.new()
	shape.radius = tile_size * 0.4
	shape.height = sprite_height * 2
	collision_shape.shape = shape
	collision_shape.position.y = sprite_height
	
	area.add_child(collision_shape)
	add_child(area)
	
	# Métadonnées pour l'identification
	area.set_meta("unit", self)
	area.collision_layer = 2  # Layer 2 pour les unités
	area.collision_mask = 0

# ============================================================================
# SANTÉ (identique à la version 2D)
# ============================================================================

func take_damage(damage: int) -> int:
	var actual_damage = max(1, damage - defense_power)
	current_hp = max(0, current_hp - actual_damage)
	_update_hp_bar()
	
	health_changed.emit(current_hp, max_hp)
	print("[", unit_name, "] Prend ", actual_damage, " dégâts (HP: ", current_hp, "/", max_hp, ")")
	
	_animate_damage()
	
	if current_hp <= 0:
		die()
	
	return actual_damage

func heal(amount: int) -> int:
	var old_hp = current_hp
	current_hp = min(max_hp, current_hp + amount)
	var actual_heal = current_hp - old_hp
	
	_update_hp_bar()
	health_changed.emit(current_hp, max_hp)
	
	print("[", unit_name, "] Soigné de ", actual_heal, " HP")
	_animate_heal()
	
	return actual_heal

func die() -> void:
	print("[", unit_name, "] est mort")
	_animate_death()
	died.emit()

func is_alive() -> bool:
	return current_hp > 0

func get_hp_percentage() -> float:
	return float(current_hp) / float(max_hp)

# ============================================================================
# ACTIONS & ÉTAT (identiques)
# ============================================================================

func can_move() -> bool:
	return is_alive() and not movement_used

func can_act() -> bool:
	return is_alive() and not action_used

func can_do_anything() -> bool:
	return can_move() or can_act()

func reset_for_new_turn() -> void:
	movement_used = false
	action_used = false
	has_acted_this_turn = false
	_process_status_effects()
	_update_visuals()

func _process_status_effects() -> void:
	var effects_to_remove: Array[String] = []
	
	for effect_name in status_effects:
		status_effects[effect_name] -= 1
		if status_effects[effect_name] <= 0:
			effects_to_remove.append(effect_name)
	
	for effect_name in effects_to_remove:
		remove_status_effect(effect_name)

# ============================================================================
# EFFETS DE STATUT
# ============================================================================

func add_status_effect(effect_name: String, duration: int) -> void:
	status_effects[effect_name] = duration
	status_effect_applied.emit(effect_name)
	print("[", unit_name, "] Effet ajouté: ", effect_name)

func remove_status_effect(effect_name: String) -> void:
	if status_effects.has(effect_name):
		status_effects.erase(effect_name)
		status_effect_removed.emit(effect_name)
		print("[", unit_name, "] Effet retiré: ", effect_name)

func has_status_effect(effect_name: String) -> bool:
	return status_effects.has(effect_name)

# ============================================================================
# SÉLECTION
# ============================================================================

func set_selected(selected: bool) -> void:
	is_selected = selected
	selection_indicator.visible = selected
	selected_changed.emit(selected)

# ============================================================================
# VISUELS & ANIMATIONS 3D
# ============================================================================

func _update_hp_bar() -> void:
	"""Met à jour la barre de HP 3D"""
	if not hp_bar_3d:
		return
	
	var hp_percent = get_hp_percentage()
	
	# Redimensionner la barre
	var box_mesh = hp_bar_3d.mesh as BoxMesh
	if box_mesh:
		box_mesh.size.x = tile_size * 0.8 * hp_percent
	
	# Déplacer pour garder aligné à gauche
	hp_bar_3d.position.x = -(tile_size * 0.8 * (1.0 - hp_percent)) / 2.0
	
	# Changer la couleur
	var material = hp_bar_3d.get_surface_override_material(0) as StandardMaterial3D
	if material:
		if hp_percent > 0.6:
			material.albedo_color = Color.GREEN
		elif hp_percent > 0.3:
			material.albedo_color = Color.YELLOW
		else:
			material.albedo_color = Color.RED

func _update_visuals() -> void:
	"""Met à jour tous les visuels"""
	if not can_do_anything():
		sprite_3d.modulate = Color(0.6, 0.6, 0.6)
	else:
		sprite_3d.modulate = Color(1, 1, 1)

func _animate_damage() -> void:
	"""Animation de dégâts"""
	var tween = create_tween()
	tween.tween_property(sprite_3d, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(sprite_3d, "modulate", Color(1, 1, 1), 0.1)

func _animate_heal() -> void:
	"""Animation de soin"""
	var tween = create_tween()
	tween.tween_property(sprite_3d, "modulate", Color(0.3, 1, 0.3), 0.1)
	tween.tween_property(sprite_3d, "modulate", Color(1, 1, 1), 0.1)

func _animate_death() -> void:
	"""Animation de mort"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "scale", Vector3(0.5, 0.5, 0.5), 0.5)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

# ============================================================================
# DONNÉES (identiques)
# ============================================================================

func get_unit_data() -> Dictionary:
	return {
		"id": unit_id,
		"name": unit_name,
		"is_player": is_player_unit,
		"position": grid_position,
		"hp": current_hp,
		"max_hp": max_hp,
		"attack": attack_power,
		"defense": defense_power,
		"movement": movement_range,
		"range": attack_range,
		"abilities": abilities.duplicate(),
		"status_effects": status_effects.duplicate(),
		"can_move": can_move(),
		"can_act": can_act()
	}
