extends Node3D
## BattleUnit3D - Unité de combat avec sprite billboard
## ✅ VERSION OPTIMISÉE : Respiration dynamique + GlobalLogger

class_name BattleUnit3D

# ============================================================================
# ENUMS
# ============================================================================

enum TorusState {
	CAN_ACT_AND_MOVE,   # Vert
	CAN_ACT_ONLY,        # Jaune
	CAN_MOVE_ONLY,       # Bleu
	CANNOT_ACT,          # Gris
	SELECTED,            # Rouge
	ENEMY_TURN           # Gris (pendant tour ennemi)
}

# ============================================================================
# SIGNAUX
# ============================================================================

signal died()
signal health_changed(new_hp: int, max_hp: int)
signal selected_changed(is_selected: bool)
signal status_effect_applied(effect_name: String)
signal status_effect_removed(effect_name: String)

# ============================================================================
# CONFIGURATION VISUELLE
# ============================================================================

const TILE_SIZE_DEFAULT: float = 1.0
const SPRITE_HEIGHT_DEFAULT: float = 0.2
const SHADOW_OPACITY: float = 0.3
const HP_BAR_WIDTH_RATIO: float = 0.8
const HP_BAR_HEIGHT_OFFSET: float = 0.6

# Couleurs du torus
const TORUS_COLORS: Dictionary = {
	TorusState.CAN_ACT_AND_MOVE: Color.GREEN,
	TorusState.CAN_ACT_ONLY: Color.YELLOW,
	TorusState.CAN_MOVE_ONLY: Color.CYAN,
	TorusState.CANNOT_ACT: Color.GRAY,
	TorusState.SELECTED: Color.RED,
	TorusState.ENEMY_TURN: Color.GRAY
}

# Respiration
const BREATH_INTENSITY: float = 0.05  # ±10%
const BREATH_DURATION_MIN: float = 2.5
const BREATH_DURATION_MAX: float = 3.5
const BREATH_DELAY_MAX: float = 2.0

# Vitesse de respiration selon HP
const BREATH_SPEED_HEALTHY: float = 1.0    # HP > 60%
const BREATH_SPEED_WOUNDED: float = 1.5    # HP 30-60%
const BREATH_SPEED_CRITICAL: float = 2.5   # HP < 30%

# ============================================================================
# PROPRIÉTÉS
# ============================================================================

var tile_size: float = TILE_SIZE_DEFAULT
var sprite_height: float = SPRITE_HEIGHT_DEFAULT

# Identité
var unit_name: String = "Unit"
var is_player_unit: bool = false
var unit_id: String = ""

# Stats
var max_hp: int = 100
var current_hp: int = 100
var attack_power: int = 20
var defense_power: int = 10
var movement_range: int = 5
var attack_range: int = 1

# État
var movement_used: bool = false
var action_used: bool = false
var has_acted_this_turn: bool = false
var grid_position: Vector2i = Vector2i(0, 0)

# Capacités & Effets
var abilities: Array[String] = []
var status_effects: Dictionary = {}

# Apparence
var unit_color: Color = Color.BLUE
var is_selected: bool = false
var current_torus_state: TorusState = TorusState.CAN_ACT_AND_MOVE

# Sprite externe
var sprite_path: String = "res://asset/unit/unit.png"
var sprite_frame: int = 20
var sprite_hframes: int = 7
var sprite_vframes: int = 3

# Anneaux équipés
var equipped_materialization_ring: String = "mat_basic_line"
var equipped_channeling_ring: String = "chan_neutral"

# Progression
var level: int = 1
var xp: int = 0

# ============================================================================
# RÉFÉRENCES VISUELLES 3D
# ============================================================================

var sprite_3d: Sprite3D
var hp_bar_container: Node3D
var hp_bar_3d: MeshInstance3D
var hp_bar_bg: MeshInstance3D
var team_indicator: MeshInstance3D
var selection_indicator: MeshInstance3D
var shadow_sprite: Sprite3D

# Cache de materials (optimisation)
var torus_material: StandardMaterial3D
var hp_bar_material: StandardMaterial3D

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	if unit_id == "":
		unit_id = unit_name + "_" + str(Time.get_ticks_msec())
	
	_create_visuals_3d()
	_update_hp_bar()
	
	GlobalLogger.debug("BATTLE_UNIT", "Unité %s initialisée (ID: %s)" % [unit_name, unit_id])

# ============================================================================
# CRÉATION DES VISUELS 3D
# ============================================================================

func _create_visuals_3d() -> void:
	"""Crée tous les éléments visuels 3D de l'unité"""
	
	# 1. OMBRE AU SOL
	shadow_sprite = Sprite3D.new()
	shadow_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	shadow_sprite.texture = _create_circle_texture(64, Color(0, 0, 0, SHADOW_OPACITY))
	shadow_sprite.pixel_size = 0.02
	shadow_sprite.rotation.x = -PI / 2
	shadow_sprite.position.y = 0.05
	shadow_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow_sprite)
	
	# 2. SPRITE PRINCIPAL (Billboard)
	sprite_3d = Sprite3D.new()
	sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite_3d.pixel_size = 0.04
	sprite_3d.position.y = sprite_height
	sprite_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_load_sprite_texture()
	add_child(sprite_3d)
	
	# 3. INDICATEUR DE SÉLECTION (torus)
	selection_indicator = _create_selection_ring()
	selection_indicator.visible = true
	add_child(selection_indicator)
	
	# 4. BARRE DE HP + TEAM INDICATOR
	_create_hp_bar_with_team_indicator()
	
	# 5. COLLISION RAYCASTING
	_create_collision()
	
	# Forcer visibilité
	visible = true
	show()
	
	# 6. DÉMARRER RESPIRATION
	_start_breathing_animation()
	
	GlobalLogger.debug("BATTLE_UNIT", "Visuels créés pour %s" % unit_name)

func _load_sprite_texture() -> void:
	"""Charge le sprite externe ou utilise le fallback"""
	
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		var external_texture = load(sprite_path) as Texture2D
		
		if external_texture:
			sprite_3d.texture = external_texture
			sprite_3d.hframes = sprite_hframes
			sprite_3d.vframes = sprite_vframes
			sprite_3d.frame = sprite_frame
			GlobalLogger.info("BATTLE_UNIT", "Sprite externe chargé : %s (frame %d)" % [sprite_path, sprite_frame])
			return
	
	# Fallback
	sprite_3d.texture = _create_unit_texture()
	sprite_3d.hframes = 1
	sprite_3d.vframes = 1
	sprite_3d.frame = 0
	GlobalLogger.warning("BATTLE_UNIT", "Sprite fallback utilisé pour %s" % unit_name)

func _create_unit_texture() -> ImageTexture:
	"""Crée une texture simple (FALLBACK)"""
	var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	for y in range(128):
		for x in range(128):
			var dx = x - 64
			var dy = y - 64
			var dist = sqrt(dx*dx + dy*dy)
			
			if dist < 50:
				var alpha = 1.0 - (dist / 50.0) * 0.3
				image.set_pixel(x, y, Color(unit_color.r, unit_color.g, unit_color.b, alpha))
			
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
	"""Crée l'anneau de sélection (torus)"""
	var mesh_instance = MeshInstance3D.new()
	
	var torus = TorusMesh.new()
	torus.inner_radius = tile_size * 0.35
	torus.outer_radius = tile_size * 0.45
	torus.rings = 24
	torus.ring_segments = 48
	
	mesh_instance.mesh = torus
	mesh_instance.rotation_degrees.y = -90
	mesh_instance.position.y = -0.4
	
	# Material avec cache
	torus_material = StandardMaterial3D.new()
	torus_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	torus_material.emission_enabled = true
	torus_material.emission_energy_multiplier = 2.0
	
	mesh_instance.set_surface_override_material(0, torus_material)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	return mesh_instance

func _create_hp_bar_with_team_indicator() -> void:
	"""Crée la barre de HP avec indicateur d'équipe"""
	
	hp_bar_container = Node3D.new()
	hp_bar_container.position = Vector3(0, sprite_height + HP_BAR_HEIGHT_OFFSET, 0)
	hp_bar_container.top_level = false
	add_child(hp_bar_container)
	
	# FOND DE LA BARRE
	hp_bar_bg = MeshInstance3D.new()
	var bg_box = BoxMesh.new()
	bg_box.size = Vector3(tile_size * HP_BAR_WIDTH_RATIO, 0.08, 0.02)
	hp_bar_bg.mesh = bg_box
	
	var bg_material = StandardMaterial3D.new()
	bg_material.albedo_color = Color(0.2, 0.2, 0.2)
	bg_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	bg_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	hp_bar_bg.set_surface_override_material(0, bg_material)
	hp_bar_bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hp_bar_container.add_child(hp_bar_bg)
	
	# BARRE DE HP AVANT-PLAN
	hp_bar_3d = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(tile_size * HP_BAR_WIDTH_RATIO, 0.06, 0.04)
	hp_bar_3d.mesh = box
	hp_bar_3d.position.z = 0.03
	
	# Material avec cache
	hp_bar_material = StandardMaterial3D.new()
	hp_bar_material.albedo_color = Color.GREEN
	hp_bar_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hp_bar_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	hp_bar_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	hp_bar_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	hp_bar_material.no_depth_test = false
	hp_bar_3d.set_surface_override_material(0, hp_bar_material)
	hp_bar_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hp_bar_3d.sorting_offset = 0.1
	hp_bar_container.add_child(hp_bar_3d)
	
	# TEAM INDICATOR
	team_indicator = MeshInstance3D.new()
	var indicator_box = BoxMesh.new()
	indicator_box.size = Vector3(0.12, 0.12, 0.04)
	team_indicator.mesh = indicator_box
	
	var bar_width = tile_size * HP_BAR_WIDTH_RATIO
	team_indicator.position = Vector3(bar_width / 2 + 0.08, -0.04, 0.03)
	
	var team_material = StandardMaterial3D.new()
	team_material.albedo_color = Color.GREEN if is_player_unit else Color.RED
	team_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	team_material.emission_enabled = true
	team_material.emission = team_material.albedo_color * 0.5
	team_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	team_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	team_indicator.set_surface_override_material(0, team_material)
	team_indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hp_bar_container.add_child(team_indicator)

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
	
	area.set_meta("unit", self)
	area.collision_layer = 2
	area.collision_mask = 0

# ============================================================================
# ANIMATION DE RESPIRATION
# ============================================================================

func _start_breathing_animation() -> void:
	"""Démarre une animation de respiration fluide et désynchronisée"""
	
	if not sprite_3d:
		return
	
	# Attendre un délai aléatoire pour désynchroniser
	await get_tree().create_timer(randf_range(0.0, BREATH_DELAY_MAX)).timeout
	
	# ========== CONFIGURATION ==========
	
	# Vitesse basée sur les HP
	var hp_percent = get_hp_percentage()
	var breath_speed_multiplier: float
	
	if hp_percent > 0.6:
		breath_speed_multiplier = BREATH_SPEED_HEALTHY
	elif hp_percent > 0.3:
		breath_speed_multiplier = BREATH_SPEED_WOUNDED
	else:
		breath_speed_multiplier = BREATH_SPEED_CRITICAL
	
	# Durée de base
	var base_breath_duration = randf_range(BREATH_DURATION_MIN, BREATH_DURATION_MAX)
	var breath_duration = base_breath_duration / breath_speed_multiplier
	
	# ========== CHOIX ALÉATOIRE : HAUTEUR OU LARGEUR ==========
	
	var is_height_breathing = randf() < 0.5
	
	var scale_min = 1.0 - BREATH_INTENSITY
	var scale_max = 1.0 + BREATH_INTENSITY
	
	# Position de base du sprite
	var base_position_y = sprite_3d.position.y
	set_meta("breathing_base_y", base_position_y)
	
	# ========== CRÉER L'ANIMATION ==========
	
	var tween = sprite_3d.create_tween()
	tween.set_loops()
	
	if is_height_breathing:
		# **RESPIRATION EN HAUTEUR**
		GlobalLogger.debug("BATTLE_UNIT", "%s respire en HAUTEUR (vitesse x%.1f)" % [unit_name, breath_speed_multiplier])
		
		# Inspiration : scale.y 1.0 → 1.1
		tween.tween_method(
			_set_height_scale_keep_bottom,
			1.0,
			scale_max,
			breath_duration / 3.0
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		
		# Expiration : scale.y 1.1 → 0.9
		tween.tween_method(
			_set_height_scale_keep_bottom,
			scale_max,
			scale_min,
			breath_duration / 3.0
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		
		# Retour neutre : scale.y 0.9 → 1.0
		tween.tween_method(
			_set_height_scale_keep_bottom,
			scale_min,
			1.0,
			breath_duration / 3.0
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	else:
		# **RESPIRATION EN LARGEUR**
		GlobalLogger.debug("BATTLE_UNIT", "%s respire en LARGEUR (vitesse x%.1f)" % [unit_name, breath_speed_multiplier])
		
		# Inspiration : scale.x 1.0 → 1.1
		tween.tween_property(
			sprite_3d,
			"scale:x",
			scale_max,
			breath_duration / 3.0
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		
		# Expiration : scale.x 1.1 → 0.9
		tween.tween_property(
			sprite_3d,
			"scale:x",
			scale_min,
			breath_duration / 3.0
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		
		# Retour neutre : scale.x 0.9 → 1.0
		tween.tween_property(
			sprite_3d,
			"scale:x",
			1.0,
			breath_duration / 3.0
		).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	# Stocker la référence
	set_meta("breathing_tween", tween)

func _set_height_scale_keep_bottom(new_scale_y: float) -> void:
	"""Modifie le scale.y du sprite en gardant le bas du sprite au même endroit"""
	
	if not sprite_3d:
		return
	
	# Récupérer la position de base
	var base_y = get_meta("breathing_base_y", sprite_height)
	
	# Calculer le décalage nécessaire pour garder le bas fixe
	var sprite_visual_height = 1.0
	var delta_y = (new_scale_y - 1.0) * sprite_visual_height / 2.0
	
	# Appliquer le scale et ajuster la position
	sprite_3d.scale.y = new_scale_y
	sprite_3d.position.y = base_y + delta_y

# ============================================================================
# PROCESS & BILLBOARD
# ============================================================================

func _process(_delta: float) -> void:
	"""Faire tourner la barre HP vers la caméra (billboard manuel)"""
	
	if not hp_bar_container:
		return
	
	var camera = get_viewport().get_camera_3d()
	if camera:
		hp_bar_container.global_transform.basis = camera.global_transform.basis

# ============================================================================
# TORUS (INDICATEUR DE SÉLECTION)
# ============================================================================

func update_torus_state(is_current_turn: bool) -> void:
	"""Met à jour l'état visuel du torus"""
	
	if not selection_indicator:
		return
	
	# Déterminer l'état
	if is_selected:
		current_torus_state = TorusState.SELECTED
	elif not is_current_turn:
		current_torus_state = TorusState.ENEMY_TURN
	elif not can_move() and not can_act():
		current_torus_state = TorusState.CANNOT_ACT
	elif can_act() and not can_move():
		current_torus_state = TorusState.CAN_ACT_ONLY
	elif can_move() and not can_act():
		current_torus_state = TorusState.CAN_MOVE_ONLY
	else:
		current_torus_state = TorusState.CAN_ACT_AND_MOVE
	
	# Appliquer la couleur
	_apply_torus_color()

func _apply_torus_color() -> void:
	"""Applique la couleur du torus selon l'état (utilise le cache)"""
	
	if not torus_material:
		return
	
	var color = TORUS_COLORS.get(current_torus_state, Color.WHITE)
	
	torus_material.albedo_color = color
	torus_material.emission = color * 0.8

func set_selected(selected: bool) -> void:
	"""Change l'état de sélection"""
	is_selected = selected
	update_torus_state(true)
	selected_changed.emit(selected)

# ============================================================================
# SANTÉ
# ============================================================================

func take_damage(damage: int) -> int:
	"""Inflige des dégâts à l'unité"""
	var actual_damage = max(1, damage - defense_power)
	current_hp = max(0, current_hp - actual_damage)
	_update_hp_bar()
	
	health_changed.emit(current_hp, max_hp)
	GlobalLogger.info("BATTLE_UNIT", "%s prend %d dégâts (HP: %d/%d)" % [unit_name, actual_damage, current_hp, max_hp])
	
	_animate_damage()
	
	if current_hp <= 0:
		die()
	
	return actual_damage

func heal(amount: int) -> int:
	"""Soigne l'unité"""
	var old_hp = current_hp
	current_hp = min(max_hp, current_hp + amount)
	var actual_heal = current_hp - old_hp
	
	_update_hp_bar()
	health_changed.emit(current_hp, max_hp)
	
	GlobalLogger.info("BATTLE_UNIT", "%s soigné de %d HP" % [unit_name, actual_heal])
	_animate_heal()
	
	return actual_heal

func die() -> void:
	"""Tue l'unité"""
	GlobalLogger.info("BATTLE_UNIT", "%s est mort" % unit_name)
	_animate_death()
	died.emit()

func is_alive() -> bool:
	return current_hp > 0

func get_hp_percentage() -> float:
	if max_hp <= 0:
		return 0.0
	return float(current_hp) / float(max_hp)

# ============================================================================
# BARRE DE HP
# ============================================================================

func _update_hp_bar() -> void:
	"""Met à jour la barre de HP 3D (utilise le cache de material)"""
	
	if not hp_bar_3d or not hp_bar_3d.mesh or not hp_bar_material:
		return
	
	if max_hp <= 0:
		GlobalLogger.warning("BATTLE_UNIT", "max_hp invalide pour %s" % unit_name)
		return
	
	var hp_percent = get_hp_percentage()
	
	# Redimensionner la barre
	var bar_max_width = tile_size * HP_BAR_WIDTH_RATIO
	var box_mesh = hp_bar_3d.mesh as BoxMesh
	
	if box_mesh:
		var current_width = bar_max_width * hp_percent
		box_mesh.size.x = current_width
		
		var offset = (bar_max_width - current_width) / 2.0
		hp_bar_3d.position.x = -offset
	
	# Couleur selon HP
	if hp_percent > 0.6:
		hp_bar_material.albedo_color = Color.GREEN
	elif hp_percent > 0.3:
		hp_bar_material.albedo_color = Color.YELLOW
	else:
		hp_bar_material.albedo_color = Color.RED

# ============================================================================
# ACTIONS & ÉTAT
# ============================================================================

func can_move() -> bool:
	return is_alive() and not movement_used

func can_act() -> bool:
	return is_alive() and not action_used

func can_do_anything() -> bool:
	return can_move() or can_act()

func reset_for_new_turn() -> void:
	"""Réinitialise l'unité pour un nouveau tour"""
	movement_used = false
	action_used = false
	has_acted_this_turn = false
	_process_status_effects()
	update_torus_state(true)

func _process_status_effects() -> void:
	"""Décrémente les effets de statut"""
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
	GlobalLogger.info("BATTLE_UNIT", "%s : effet ajouté : %s" % [unit_name, effect_name])

func remove_status_effect(effect_name: String) -> void:
	if status_effects.has(effect_name):
		status_effects.erase(effect_name)
		status_effect_removed.emit(effect_name)
		GlobalLogger.info("BATTLE_UNIT", "%s : effet retiré : %s" % [unit_name, effect_name])

func has_status_effect(effect_name: String) -> bool:
	return status_effects.has(effect_name)

# ============================================================================
# ANIMATIONS
# ============================================================================

func _animate_damage() -> void:
	"""Animation flash rouge"""
	var tween = create_tween()
	tween.tween_property(sprite_3d, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(sprite_3d, "modulate", Color(1, 1, 1), 0.1)

func _animate_heal() -> void:
	"""Animation flash vert"""
	var tween = create_tween()
	tween.tween_property(sprite_3d, "modulate", Color(0.3, 1, 0.3), 0.1)
	tween.tween_property(sprite_3d, "modulate", Color(1, 1, 1), 0.1)

func _animate_death() -> void:
	"""Animation de mort"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	if sprite_3d:
		tween.tween_property(sprite_3d, "modulate:a", 0.0, 0.5)
	
	if hp_bar_container:
		tween.tween_property(hp_bar_container, "scale", Vector3.ZERO, 0.5)
	
	if selection_indicator:
		tween.tween_property(selection_indicator, "scale", Vector3.ZERO, 0.3)
	
	tween.tween_property(self, "scale", Vector3(0.5, 0.5, 0.5), 0.5)
	
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

# ============================================================================
# DONNÉES
# ============================================================================

func get_unit_data() -> Dictionary:
	"""Retourne les données de l'unité"""
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
	
	# Stats
	var temp_max_hp = 100
	var temp_current_hp = -1
	
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
	
	if data.has("max_hp"):
		temp_max_hp = data.max_hp
	
	if data.has("hp"):
		temp_current_hp = data.hp
	
	max_hp = temp_max_hp
	current_hp = temp_current_hp if temp_current_hp >= 0 else max_hp
	current_hp = min(current_hp, max_hp)
	
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
	
	# Sprite personnalisé
	if data.has("sprite_path"):
		sprite_path = data.sprite_path
	if data.has("sprite_frame"):
		sprite_frame = data.sprite_frame
	if data.has("sprite_hframes"):
		sprite_hframes = data.sprite_hframes
	if data.has("sprite_vframes"):
		sprite_vframes = data.sprite_vframes
	
	# Anneaux équipés
	if data.has("materialization_ring"):
		equipped_materialization_ring = data.materialization_ring
	if data.has("channeling_ring"):
		equipped_channeling_ring = data.channeling_ring
	
	# Apparence
	if data.has("color"):
		unit_color = data.color
	else:
		unit_color = Color(0.2, 0.2, 0.8) if is_player_unit else Color(0.8, 0.2, 0.2)
	
	level = data.get("level", 1)
	xp = data.get("xp", 0)
	
	GlobalLogger.info("BATTLE_UNIT", "Unité initialisée : %s (ID: %s)" % [unit_name, unit_id])
	GlobalLogger.debug("BATTLE_UNIT", "  → HP: %d/%d (%.1f%%)" % [current_hp, max_hp, get_hp_percentage() * 100])
	GlobalLogger.debug("BATTLE_UNIT", "  → Anneaux: %s + %s" % [equipped_materialization_ring, equipped_channeling_ring])

func award_xp(amount: int) -> void:
	"""Donne de l'XP à l'unité"""
	if not is_player_unit:
		return
	
	xp += amount
	GlobalLogger.info("BATTLE_UNIT", "%s : +%d XP (Total: %d)" % [unit_name, amount, xp])
	TeamManager.add_xp(unit_id, amount)

# ============================================================================
# NETTOYAGE
# ============================================================================

func _exit_tree() -> void:
	"""Nettoie les tweens en cours"""
	
	# Arrêter le tween de respiration
	if has_meta("breathing_tween"):
		var tween = get_meta("breathing_tween") as Tween
		if tween and tween.is_valid():
			tween.kill()
	
	# Arrêter le tween de clignotement
	if has_meta("blink_tween"):
		var tween = get_meta("blink_tween") as Tween
		if tween and tween.is_valid():
			tween.kill()
	
	GlobalLogger.debug("BATTLE_UNIT", "Unité %s nettoyée" % unit_name)


func show_duo_aura(is_enemy_duo: bool = false) -> void:
	"""Affiche une aura temporaire pour indiquer participation à un duo"""
	
	if not sprite_3d:
		return
	
	# Créer un sprite d'aura temporaire
	var aura = Sprite3D.new()
	aura.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	aura.texture = _create_aura_texture(is_enemy_duo)
	aura.pixel_size = 0.05
	aura.position.y = sprite_height
	aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	aura.modulate.a = 0.0
	aura.name = "DuoAura"
	
	add_child(aura)
	
	# Animation de l'aura
	var tween = aura.create_tween()
	tween.set_loops()
	
	# Fade in
	tween.tween_property(aura, "modulate:a", 0.8, 0.3)
	# Pulse
	tween.tween_property(aura, "scale", Vector3(1.2, 1.2, 1.2), 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(aura, "scale", Vector3(1.0, 1.0, 1.0), 0.5).set_ease(Tween.EASE_IN_OUT)
	
	# Stocker la référence pour suppression
	set_meta("duo_aura", aura)
	set_meta("duo_aura_tween", tween)

func hide_duo_aura() -> void:
	"""Supprime l'aura de duo"""
	
	if has_meta("duo_aura"):
		var aura = get_meta("duo_aura") as Sprite3D
		
		if aura and is_instance_valid(aura):
			var fade_tween = aura.create_tween()
			fade_tween.tween_property(aura, "modulate:a", 0.0, 0.3)
			fade_tween.tween_callback(aura.queue_free)
		
		remove_meta("duo_aura")
	
	if has_meta("duo_aura_tween"):
		var tween = get_meta("duo_aura_tween") as Tween
		if tween and tween.is_valid():
			tween.kill()
		remove_meta("duo_aura_tween")

func _create_aura_texture(is_enemy: bool) -> ImageTexture:
	"""Crée une texture d'aura circulaire"""
	
	var size = 256
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = size / 2
	var color = Color(1.0, 0.2, 0.2, 1.0) if is_enemy else Color(0.2, 0.6, 1.0, 1.0)
	
	for y in range(size):
		for x in range(size):
			var dx = x - center
			var dy = y - center
			var dist = sqrt(dx*dx + dy*dy)
			
			# Anneau avec dégradé
			if dist > center * 0.6 and dist < center:
				var alpha = 1.0 - (dist - center * 0.6) / (center * 0.4)
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	return ImageTexture.create_from_image(image)
