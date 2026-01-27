extends Node3D
## BattleUnit3D - Unité de combat avec sprite billboard
## Version corrigée : cercle horizontal, team indicator enfant de HP bar, barre de vie verte

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
var hp_bar_container: Node3D  # Container pour billboard
var hp_bar_3d: MeshInstance3D
var hp_bar_bg: MeshInstance3D
var team_indicator: MeshInstance3D  # ← Maintenant enfant de hp_bar_container
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
	shadow_sprite.pixel_size = 0.02
	shadow_sprite.rotation.x = -PI / 2  # Horizontal au sol
	shadow_sprite.position.y = 0.05
	shadow_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow_sprite)
	
	# 2. SPRITE PRINCIPAL (Billboard)
	sprite_3d = Sprite3D.new()
	sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite_3d.texture = _create_unit_texture()
	sprite_3d.pixel_size = 0.01
	sprite_3d.position.y = sprite_height
	sprite_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sprite_3d)
	
	# 3. INDICATEUR DE SÉLECTION (anneau au sol - HORIZONTAL)
	selection_indicator = _create_selection_ring()
	selection_indicator.visible = false
	add_child(selection_indicator)
	
	# 4. BARRE DE HP avec TEAM INDICATOR (au-dessus du sprite - BILLBOARD)
	_create_hp_bar_with_team_indicator()
	
	# 5. COLLISION POUR LE RAYCASTING
	_create_collision()
	
	# Forcer la visibilité
	visible = true
	show()
	
	for child in get_children():
		if child is VisualInstance3D:
			child.visible = true
			child.show()
	
	print("[BattleUnit3D] 👁️ Visuals created for ", unit_name)

func _create_unit_texture() -> ImageTexture:
	"""Crée une texture simple pour le sprite de l'unité"""
	var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Dessiner un cercle coloré
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
	"""Crée un anneau de sélection au sol - HORIZONTAL"""
	var mesh_instance = MeshInstance3D.new()
	
	# Utiliser un TorusMesh pour l'anneau
	var torus = TorusMesh.new()
	torus.inner_radius = tile_size * 0.35
	torus.outer_radius = tile_size * 0.45
	torus.rings = 24
	torus.ring_segments = 48
	
	mesh_instance.mesh = torus
	
	# ✅ CORRECTION : Rotation pour mettre l'anneau horizontal au sol
	# Le TorusMesh est vertical par défaut (axe Y), on le tourne de -90° sur X
	#mesh_instance.rotation_degrees.x = -90  # Horizontal au sol
	mesh_instance.rotation_degrees.y = -90  # Horizontal au sol
	#mesh_instance.rotation_degrees.z = -90  # Horizontal au sol
	mesh_instance.position.y = -0.4 # Légèrement au-dessus du sol
	
	# Matériau émissif jaune
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	material.emission_enabled = true
	material.emission = Color.YELLOW * 0.8
	material.emission_energy_multiplier = 2.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# PAS D'OMBRES
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	mesh_instance.set_surface_override_material(0, material)
	
	return mesh_instance

func _create_hp_bar_with_team_indicator() -> void:
	"""Crée une barre de HP avec team indicator comme enfant"""
	
	# Container qui va faire le billboard
	hp_bar_container = Node3D.new()
	hp_bar_container.position = Vector3(0, sprite_height + 0.6, 0)
	hp_bar_container.top_level = false
	add_child(hp_bar_container)
	
	# ========== FOND DE LA BARRE (gris foncé) ==========
	hp_bar_bg = MeshInstance3D.new()
	var bg_box = BoxMesh.new()
	bg_box.size = Vector3(tile_size * 0.8, 0.08, 0.02)
	hp_bar_bg.mesh = bg_box
	
	var bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0.2, 0.2, 0.2)
	bg_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	bg_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED  # ✅ AJOUTÉ
	hp_bar_bg.set_surface_override_material(0, bg_material)
	hp_bar_bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hp_bar_container.add_child(hp_bar_bg)
	
	# ========== BARRE DE HP AVANT-PLAN (verte) ==========
	hp_bar_3d = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(tile_size * 0.8, 0.06, 0.04)  # ✅ Plus épais en Z
	hp_bar_3d.mesh = box
	
	# ✅ CORRECTION : Position devant le fond
	hp_bar_3d.position.z = 0.03  # Devant le fond
	
	# ✅ CORRECTION : Material vert avec rendering_mode approprié
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GREEN
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED  # ✅ AJOUTÉ
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	material.no_depth_test = false  # ✅ AJOUTÉ
	hp_bar_3d.set_surface_override_material(0, material)
	hp_bar_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# ✅ CRITIQUE : Render priority pour garantir l'ordre
	hp_bar_3d.sorting_offset = 0.1  # ✅ AJOUTÉ : Priorité de rendu
	
	hp_bar_container.add_child(hp_bar_3d)
	
	# ========== TEAM INDICATOR ==========
	team_indicator = MeshInstance3D.new()
	var indicator_box = BoxMesh.new()
	indicator_box.size = Vector3(0.12, 0.12, 0.04)  # ✅ Plus épais
	team_indicator.mesh = indicator_box
	
	var bar_width = tile_size * 0.8
	var bar_height = 0.08
	team_indicator.position = Vector3(
		bar_width / 2 + 0.08,
		-bar_height / 2,
		0.03  # ✅ Même Z que la barre verte
	)
	
	var team_material = StandardMaterial3D.new()
	team_material.albedo_color = Color.GREEN if is_player_unit else Color.RED
	team_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	team_material.emission_enabled = true
	team_material.emission = team_material.albedo_color * 0.5
	team_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	team_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED  # ✅ AJOUTÉ
	team_indicator.set_surface_override_material(0, team_material)
	team_indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	hp_bar_container.add_child(team_indicator)
	
func _process(_delta: float) -> void:
	"""Faire tourner la barre HP vers la caméra"""
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	# ✅ CORRECTION : Copier la rotation de la caméra au lieu de look_at
	if hp_bar_container:
		# Billboard pur : copier la rotation globale de la caméra
		var cam_basis = camera.global_transform.basis
		hp_bar_container.global_transform.basis = cam_basis

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
	if not hp_bar_3d or not hp_bar_3d.mesh:
		return
	
	# ✅ CORRECTION : Vérifier que max_hp > 0 pour éviter division par zéro
	if max_hp <= 0:
		push_warning("[BattleUnit3D] max_hp invalide pour ", unit_name)
		return
	
	var hp_percent = get_hp_percentage()
	
	# ✅ CORRECTION : S'assurer que tile_size est valide
	var bar_max_width = tile_size * 0.8
	if bar_max_width <= 0:
		bar_max_width = 0.8  # Fallback
	
	# Redimensionner correctement
	var box_mesh = hp_bar_3d.mesh as BoxMesh
	if box_mesh:
		var current_width = bar_max_width * hp_percent
		box_mesh.size.x = current_width
		
		# Ancrer à gauche
		var offset = (bar_max_width - current_width) / 2.0
		hp_bar_3d.position.x = -offset
	
	# Changer la couleur selon le % de HP
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

# ============================================================================
# INITIALISATION DEPUIS DONNÉES
# ============================================================================
func initialize_unit(data: Dictionary) -> void:
	"""Initialise l'unité à partir d'un dictionnaire de données"""
	
	# Identité
	if data.has("name"):
		unit_name = data.name
	if data.has("id"):
		unit_id = data.id
	elif unit_id == "":
		unit_id = unit_name + "_" + str(Time.get_ticks_msec())
	
	if data.has("is_player"):
		is_player_unit = data.is_player
	
	# Position
	if data.has("position"):
		grid_position = data.position
	
	# ✅ CORRECTION : Initialiser les stats dans le bon ordre
	var temp_max_hp = 100  # Valeur par défaut
	var temp_current_hp = -1  # Sentinelle pour savoir si explicitement défini
	
	# Stats depuis le bloc "stats"
	if data.has("stats"):
		var stats = data.stats
		if stats.has("hp"):
			temp_max_hp = stats.hp
		if stats.has("attack"):
			attack_power = stats.attack
		if stats.has("defense"):
			defense_power = stats.defense
		if stats.has("movement"):
			movement_range = stats.movement
		if stats.has("range"):
			attack_range = stats.range
	
	# Stats directes (écrasent les stats du bloc si présentes)
	if data.has("max_hp"):
		temp_max_hp = data.max_hp
	
	if data.has("hp"):
		temp_current_hp = data.hp
	
	# ✅ CORRECTION : Appliquer les HP de façon cohérente
	max_hp = temp_max_hp
	
	if temp_current_hp >= 0:
		# HP explicitement défini dans les données
		current_hp = temp_current_hp
	else:
		# Pas de HP spécifié → commencer au maximum
		current_hp = max_hp
	
	# Sécurité : s'assurer que current_hp ne dépasse jamais max_hp
	current_hp = min(current_hp, max_hp)
	
	# Stats directes restantes
	if data.has("attack"):
		attack_power = data.attack
	if data.has("defense"):
		defense_power = data.defense
	if data.has("movement"):
		movement_range = data.movement
	if data.has("range"):
		attack_range = data.range
	
	# Capacités
	if data.has("abilities"):
		abilities.clear()
		var abilities_array = data.abilities
		if abilities_array is Array:
			for ability in abilities_array:
				if ability is String:
					abilities.append(ability)
	
	# Effets de statut
	if data.has("status_effects"):
		status_effects.clear()
		var effects = data.status_effects
		if effects is Dictionary:
			for effect_name in effects:
				status_effects[effect_name] = effects[effect_name]
	
	# Apparence
	if data.has("color"):
		unit_color = data.color
	else:
		# Couleur par défaut selon l'équipe
		unit_color = Color(0.2, 0.2, 0.8) if is_player_unit else Color(0.8, 0.2, 0.2)
	
	# ✅ CORRECTION : Log de debug pour vérifier les HP
	print("[BattleUnit3D] Unité initialisée: ", unit_name, " (", unit_id, ")")
	print("  → HP: ", current_hp, "/", max_hp, " (", get_hp_percentage() * 100, "%)")
