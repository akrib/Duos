extends Node2D
## BattleUnit - Représente une unité individuelle en combat
## Visuel avec ColorRect, stats, état, etc.

class_name BattleUnit

# ============================================================================
# SIGNAUX
# ============================================================================

signal died()
signal health_changed(new_hp: int, max_hp: int)
signal selected_changed(is_selected: bool)
signal status_effect_applied(effect_name: String)
signal status_effect_removed(effect_name: String)

# ============================================================================
# CONFIGURATION
# ============================================================================

var tile_size: int = 48

# ============================================================================
# IDENTITÉ
# ============================================================================

var unit_name: String = "Unit"
var is_player_unit: bool = false
var unit_id: String = ""  # Généré automatiquement

# ============================================================================
# STATS
# ============================================================================

var max_hp: int = 100
var current_hp: int = 100
var attack_power: int = 20
var defense_power: int = 10
var movement_range: int = 5
var attack_range: int = 1

# ============================================================================
# ÉTAT DU TOUR
# ============================================================================

var movement_used: bool = false
var action_used: bool = false
var has_acted_this_turn: bool = false

# ============================================================================
# POSITION
# ============================================================================

var grid_position: Vector2i = Vector2i(0, 0)

# ============================================================================
# CAPACITÉS & EFFETS
# ============================================================================

var abilities: Array[String] = []
var status_effects: Dictionary = {}  # effect_name -> turns_remaining

# ============================================================================
# APPARENCE
# ============================================================================

var unit_color: Color = Color.BLUE
var is_selected: bool = false

# Visuels
var body_rect: ColorRect
var hp_bar: ColorRect
var hp_bar_bg: ColorRect
var selection_indicator: ColorRect
var name_label: Label

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	# Générer un ID unique
	if unit_id == "":
		unit_id = unit_name + "_" + str(Time.get_ticks_msec())
	
	# Créer les visuels
	_create_visuals()
	
	# Mettre à jour l'affichage
	_update_hp_bar()

func _create_visuals() -> void:
	"""Crée tous les éléments visuels de l'unité"""
	
	# Corps principal (ColorRect)
	body_rect = ColorRect.new()
	body_rect.size = Vector2(tile_size - 4, tile_size - 4)
	body_rect.position = Vector2(2, 2)
	body_rect.color = unit_color
	add_child(body_rect)
	
	# Bordure plus foncée
	var border = ColorRect.new()
	border.size = body_rect.size - Vector2(4, 4)
	border.position = Vector2(2, 2)
	border.color = unit_color.darkened(0.3)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_rect.add_child(border)
	
	# Indicateur de sélection (caché par défaut)
	selection_indicator = ColorRect.new()
	selection_indicator.size = Vector2(tile_size, tile_size)
	selection_indicator.position = Vector2(0, 0)
	selection_indicator.color = Color(1, 1, 0, 0.3)
	selection_indicator.visible = false
	selection_indicator.z_index = -1
	selection_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(selection_indicator)
	
	# Barre de HP (fond)
	hp_bar_bg = ColorRect.new()
	hp_bar_bg.size = Vector2(tile_size - 8, 4)
	hp_bar_bg.position = Vector2(4, tile_size - 8)
	hp_bar_bg.color = Color(0.2, 0.2, 0.2)
	hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_bar_bg)
	
	# Barre de HP (foreground)
	hp_bar = ColorRect.new()
	hp_bar.size = Vector2(tile_size - 8, 4)
	hp_bar.position = Vector2(0, 0)
	hp_bar.color = Color(0, 1, 0)
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_bg.add_child(hp_bar)
	
	# Label du nom
	name_label = Label.new()
	name_label.text = unit_name
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.modulate = Color(1, 1, 1)
	name_label.position = Vector2(4, -16)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)
	
	# Indicateur joueur/ennemi
	var team_indicator = ColorRect.new()
	team_indicator.size = Vector2(8, 8)
	team_indicator.position = Vector2(tile_size - 10, 2)
	team_indicator.color = Color(0, 1, 0) if is_player_unit else Color(1, 0, 0)
	team_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(team_indicator)

# ============================================================================
# SANTÉ
# ============================================================================

func take_damage(damage: int) -> int:
	"""Inflige des dégâts à l'unité"""
	
	# Calculer les dégâts après défense
	var actual_damage = max(1, damage - defense_power)
	
	current_hp = max(0, current_hp - actual_damage)
	_update_hp_bar()
	
	health_changed.emit(current_hp, max_hp)
	
	print("[", unit_name, "] Prend ", actual_damage, " dégâts (HP: ", current_hp, "/", max_hp, ")")
	
	# Animation de dégâts
	_animate_damage()
	
	# Vérifier la mort
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
	
	print("[", unit_name, "] Soigné de ", actual_heal, " HP (HP: ", current_hp, "/", max_hp, ")")
	
	# Animation de soin
	_animate_heal()
	
	return actual_heal

func die() -> void:
	"""L'unité meurt"""
	
	print("[", unit_name, "] est mort")
	
	# Animation de mort
	_animate_death()
	
	died.emit()

func is_alive() -> bool:
	"""Vérifie si l'unité est vivante"""
	
	return current_hp > 0

func get_hp_percentage() -> float:
	"""Retourne le pourcentage de HP"""
	
	return float(current_hp) / float(max_hp)

# ============================================================================
# ACTIONS & ÉTAT
# ============================================================================

func can_move() -> bool:
	"""Vérifie si l'unité peut se déplacer"""
	
	return is_alive() and not movement_used

func can_act() -> bool:
	"""Vérifie si l'unité peut agir (attaquer, etc.)"""
	
	return is_alive() and not action_used

func can_do_anything() -> bool:
	"""Vérifie si l'unité peut faire quoi que ce soit"""
	
	return can_move() or can_act()

func reset_for_new_turn() -> void:
	"""Réinitialise l'unité pour un nouveau tour"""
	
	movement_used = false
	action_used = false
	has_acted_this_turn = false
	
	# Traiter les effets de statut
	_process_status_effects()
	
	# Mise à jour visuelle
	_update_visuals()

func _process_status_effects() -> void:
	"""Traite les effets de statut (durée, etc.)"""
	
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
	"""Ajoute un effet de statut"""
	
	status_effects[effect_name] = duration
	status_effect_applied.emit(effect_name)
	
	print("[", unit_name, "] Effet ajouté: ", effect_name, " (", duration, " tours)")

func remove_status_effect(effect_name: String) -> void:
	"""Retire un effet de statut"""
	
	if status_effects.has(effect_name):
		status_effects.erase(effect_name)
		status_effect_removed.emit(effect_name)
		
		print("[", unit_name, "] Effet retiré: ", effect_name)

func has_status_effect(effect_name: String) -> bool:
	"""Vérifie si l'unité a un effet de statut"""
	
	return status_effects.has(effect_name)

# ============================================================================
# SÉLECTION
# ============================================================================

func set_selected(selected: bool) -> void:
	"""Change l'état de sélection"""
	
	is_selected = selected
	selection_indicator.visible = selected
	selected_changed.emit(selected)

# ============================================================================
# VISUELS & ANIMATIONS
# ============================================================================

func _update_hp_bar() -> void:
	"""Met à jour la barre de HP"""
	
	var hp_percent = get_hp_percentage()
	hp_bar.size.x = (tile_size - 8) * hp_percent
	
	# Changer la couleur selon le pourcentage
	if hp_percent > 0.6:
		hp_bar.color = Color(0, 1, 0)  # Vert
	elif hp_percent > 0.3:
		hp_bar.color = Color(1, 1, 0)  # Jaune
	else:
		hp_bar.color = Color(1, 0, 0)  # Rouge

func _update_visuals() -> void:
	"""Met à jour tous les visuels"""
	
	# Assombrir si l'unité ne peut plus agir
	if not can_do_anything():
		body_rect.modulate = Color(0.6, 0.6, 0.6)
	else:
		body_rect.modulate = Color(1, 1, 1)

func _animate_damage() -> void:
	"""Animation de dégâts"""
	
	var tween = create_tween()
	tween.tween_property(body_rect, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(body_rect, "modulate", Color(1, 1, 1), 0.1)

func _animate_heal() -> void:
	"""Animation de soin"""
	
	var tween = create_tween()
	tween.tween_property(body_rect, "modulate", Color(0.3, 1, 0.3), 0.1)
	tween.tween_property(body_rect, "modulate", Color(1, 1, 1), 0.1)

func _animate_death() -> void:
	"""Animation de mort"""
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.5)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

# ============================================================================
# DONNÉES
# ============================================================================

func get_unit_data() -> Dictionary:
	"""Retourne les données complètes de l'unité"""
	
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

func get_combat_stats() -> Dictionary:
	"""Retourne uniquement les stats de combat"""
	
	return {
		"attack": attack_power,
		"defense": defense_power,
		"hp": current_hp,
		"max_hp": max_hp
	}

# ============================================================================
# DEBUG
# ============================================================================

func print_status() -> void:
	"""Affiche le statut de l'unité (debug)"""
	
	print("\n=== ", unit_name, " ===")
	print("Position: ", grid_position)
	print("HP: ", current_hp, "/", max_hp, " (", int(get_hp_percentage() * 100), "%)")
	print("Attack: ", attack_power, " | Defense: ", defense_power)
	print("Movement: ", movement_range, " | Range: ", attack_range)
	print("Can Move: ", can_move(), " | Can Act: ", can_act())
	print("Status Effects: ", status_effects)
	print("==============\n")
