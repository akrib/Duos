extends PanelContainer
## CharacterMiniCard - Mini-fiche d'un personnage pour le menu de duo
## Affiche portrait, nom, classe et stats principales

class_name CharacterMiniCard

# ============================================================================
# RÉFÉRENCES UI
# ============================================================================

@onready var portrait: TextureRect = $MarginContainer/VBoxContainer/Portrait
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var class_label: Label = $MarginContainer/VBoxContainer/ClassLabel
@onready var hp_label: Label = $MarginContainer/VBoxContainer/StatsGrid/HPValue
@onready var atk_label: Label = $MarginContainer/VBoxContainer/StatsGrid/ATKValue
@onready var def_label: Label = $MarginContainer/VBoxContainer/StatsGrid/DEFValue

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var card_width: int = 180
@export var portrait_size: Vector2 = Vector2(80, 80)

# ============================================================================
# DONNÉES
# ============================================================================

var unit_data: Dictionary = {}

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	custom_minimum_size = Vector2(card_width, 0)
	if portrait:
		portrait.custom_minimum_size = portrait_size

# ============================================================================
# SETUP
# ============================================================================

func setup_from_unit(unit: BattleUnit3D) -> void:
	"""Configure la carte à partir d'une unité de combat"""
	
	if not is_inside_tree():
		await ready
	
	# Nom
	if name_label:
		name_label.text = unit.unit_name
	
	# Classe (si disponible via metadata ou autre)
	if class_label:
		var unit_class = unit.get_meta("unit_class", "Guerrier")
		class_label.text = unit_class
	
	# Stats
	if hp_label:
		hp_label.text = "%d/%d" % [unit.current_hp, unit.max_hp]
		_colorize_hp(unit.current_hp, unit.max_hp)
	
	if atk_label:
		atk_label.text = str(unit.attack_power)
	
	if def_label:
		def_label.text = str(unit.defense_power)
	
	# Portrait (si existe)
	_set_portrait_from_unit(unit)

func setup_from_data(data: Dictionary) -> void:
	"""Configure la carte à partir d'un dictionnaire de données"""
	
	unit_data = data
	
	if not is_inside_tree():
		await ready
	
	# Nom
	if name_label:
		name_label.text = data.get("name", "Unknown")
	
	# Classe
	if class_label:
		class_label.text = data.get("class", "Guerrier")
	
	# Stats
	var stats = data.get("stats", {})
	
	if hp_label:
		var current_hp = data.get("current_hp", stats.get("hp", 100))
		var max_hp = stats.get("hp", 100)
		hp_label.text = "%d/%d" % [current_hp, max_hp]
		_colorize_hp(current_hp, max_hp)
	
	if atk_label:
		atk_label.text = str(stats.get("attack", 0))
	
	if def_label:
		def_label.text = str(stats.get("defense", 0))
	
	# Portrait
	var portrait_path = data.get("portrait", "")
	if portrait_path != "":
		_set_portrait(portrait_path)

# ============================================================================
# HELPERS
# ============================================================================

func _set_portrait_from_unit(unit: BattleUnit3D) -> void:
	"""Essaye de charger le portrait depuis les métadonnées de l'unité"""
	
	if not portrait:
		return
	
	# Chercher dans les métadonnées
	if unit.has_meta("portrait"):
		var portrait_path = unit.get_meta("portrait")
		_set_portrait(portrait_path)
	else:
		# Fallback : Couleur de l'unité
		var color_rect = ColorRect.new()
		color_rect.color = unit.get_meta("color", Color.WHITE)
		# TODO: Utiliser un sprite par défaut

func _set_portrait(path: String) -> void:
	"""Charge une texture de portrait"""
	
	if not portrait or path == "":
		return
	
	if ResourceLoader.exists(path):
		var texture = load(path)
		if texture is Texture2D:
			portrait.texture = texture

func _colorize_hp(current: int, maximum: int) -> void:
	"""Colorie le label HP selon le pourcentage"""
	
	if not hp_label:
		return
	
	var percent = float(current) / float(maximum)
	
	if percent > 0.7:
		hp_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))  # Vert
	elif percent > 0.3:
		hp_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5))  # Jaune
	else:
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))  # Rouge

# ============================================================================
# CLEAR
# ============================================================================

func clear() -> void:
	"""Réinitialise la carte"""
	
	if name_label:
		name_label.text = "---"
	if class_label:
		class_label.text = "---"
	if hp_label:
		hp_label.text = "--/--"
	if atk_label:
		atk_label.text = "--"
	if def_label:
		def_label.text = "--"
	if portrait:
		portrait.texture = null
