extends Node2D
## BarkSystem - Système de messages courts flottants
## Affiche des messages brefs au-dessus des personnages

class_name BarkSystem

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var default_duration: float = 2.0
@export var fade_in_duration: float = 0.2
@export var fade_out_duration: float = 0.3
@export var float_distance: float = 30.0
@export var max_active_barks: int = 10

# ============================================================================
# ÉTAT
# ============================================================================

var active_barks: Array[BarkLabel] = []
var bark_label_scene: PackedScene = null

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	# Charger la scène de BarkLabel (ou créer dynamiquement)
	_setup_bark_scene()
	
	print("[BarkSystem] Initialisé")

func _setup_bark_scene() -> void:
	"""Prépare la scène de bark"""
	
	# Vérifier si la scène existe
	if ResourceLoader.exists("res://scenes/ui/bark_label.tscn"):
		bark_label_scene = load("res://scenes/ui/bark_label.tscn")
	else:
		# Créer dynamiquement si la scène n'existe pas
		print("[BarkSystem] Scène bark_label.tscn introuvable, création dynamique")

# ============================================================================
# AFFICHAGE DE BARKS
# ============================================================================

func show_bark(speaker: String, text: String, world_position: Vector2, duration: float = 0.0) -> void:
	"""Affiche un bark au-dessus d'une position"""
	
	# Nettoyer les barks trop nombreux
	_cleanup_old_barks()
	
	# Créer le bark
	var bark: BarkLabel = null
	
	if bark_label_scene:
		bark = bark_label_scene.instantiate()
	else:
		bark = _create_bark_dynamically()
	
	if not bark:
		push_error("[BarkSystem] Impossible de créer un bark")
		return
	
	# Configuration
	bark.speaker = speaker
	bark.text = text
	bark.position = world_position
	bark.duration = duration if duration > 0 else default_duration
	
	# Ajouter à la scène
	add_child(bark)
	active_barks.append(bark)
	
	# Animation
	_animate_bark(bark)
	
	# Auto-destruction
	var bark_duration = bark.duration + fade_in_duration + fade_out_duration
	get_tree().create_timer(bark_duration).timeout.connect(
		func(): _remove_bark(bark)
	)

func show_bark_3d(speaker: String, text: String, world_position_3d: Vector3, camera: Camera3D, duration: float = 0.0) -> void:
	"""Affiche un bark en 3D (projette en 2D)"""
	
	if not camera:
		push_warning("[BarkSystem] Caméra non fournie pour bark 3D")
		return
	
	var screen_pos = camera.unproject_position(world_position_3d)
	show_bark(speaker, text, screen_pos, duration)

# ============================================================================
# CRÉATION DYNAMIQUE
# ============================================================================

func _create_bark_dynamically() -> BarkLabel:
	"""Crée un BarkLabel dynamiquement"""
	
	var bark = BarkLabel.new()
	return bark

# ============================================================================
# ANIMATION
# ============================================================================

func _animate_bark(bark: BarkLabel) -> void:
	"""Anime l'apparition et la disparition du bark"""
	
	bark.modulate.a = 0.0
	var start_y = bark.position.y
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in
	tween.tween_property(bark, "modulate:a", 1.0, fade_in_duration)
	
	# Float up
	tween.tween_property(
		bark,
		"position:y",
		start_y - float_distance,
		bark.duration + fade_in_duration + fade_out_duration
	).set_ease(Tween.EASE_OUT)
	
	# Wait
	tween.set_parallel(false)
	tween.tween_interval(bark.duration)
	
	# Fade out
	tween.tween_property(bark, "modulate:a", 0.0, fade_out_duration)

# ============================================================================
# NETTOYAGE
# ============================================================================

func _cleanup_old_barks() -> void:
	"""Nettoie les barks trop nombreux"""
	
	while active_barks.size() >= max_active_barks:
		var oldest = active_barks.pop_front()
		if oldest and is_instance_valid(oldest):
			oldest.queue_free()

func _remove_bark(bark: BarkLabel) -> void:
	"""Retire un bark"""
	
	active_barks.erase(bark)
	
	if bark and is_instance_valid(bark):
		bark.queue_free()

func clear_all_barks() -> void:
	"""Efface tous les barks actifs"""
	
	for bark in active_barks:
		if bark and is_instance_valid(bark):
			bark.queue_free()
	
	active_barks.clear()
