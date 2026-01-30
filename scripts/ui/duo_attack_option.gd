extends PanelContainer
## DuoAttackOption - Représente une option d'attaque en duo
## Affiche une case coupée en deux : Mana (gauche) + Arme (droite)

class_name DuoAttackOption

# ============================================================================
# SIGNAUX
# ============================================================================

signal option_selected(mana_ring_id: String, weapon_ring_id: String)
signal option_hovered()

# ============================================================================
# RÉFÉRENCES UI
# ============================================================================

@onready var button: Button = $Button
@onready var mana_panel: PanelContainer = $Button/HBoxContainer/ManaPanel
#@ontml:parameter>
@onready var mana_icon: TextureRect = $Button/HBoxContainer/ManaPanel/MarginContainer/VBoxContainer/ManaIcon
@onready var mana_label: Label = $Button/HBoxContainer/ManaPanel/MarginContainer/VBoxContainer/ManaLabel

@onready var weapon_panel: PanelContainer = $Button/HBoxContainer/WeaponPanel
@onready var weapon_icon: TextureRect = $Button/HBoxContainer/WeaponPanel/MarginContainer/VBoxContainer/WeaponIcon
@onready var weapon_label: Label = $Button/HBoxContainer/WeaponPanel/MarginContainer/VBoxContainer/WeaponLabel

# ============================================================================
# DONNÉES
# ============================================================================

var mana_ring_id: String = ""
var weapon_ring_id: String = ""
var mana_ring_data: Dictionary = {}
var weapon_ring_data: Dictionary = {}

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	if button:
		button.pressed.connect(_on_button_pressed)
		button.mouse_entered.connect(_on_button_hovered)

# ============================================================================
# CONFIGURATION
# ============================================================================

func setup(mana_data: Dictionary, weapon_data: Dictionary) -> void:
	"""
	Configure l'option avec les données des anneaux
	
	mana_data = {
		"ring_id": "chan_fire",
		"ring_name": "Anneau de Feu",
		"icon": "res://path/to/icon.png" (optionnel)
	}
	weapon_data = {
		"ring_id": "mat_basic_line",
		"ring_name": "Lame Basique",
		"icon": "res://path/to/icon.png" (optionnel)
	}
	"""
	
	mana_ring_data = mana_data
	weapon_ring_data = weapon_data
	
	mana_ring_id = mana_data.get("ring_id", "")
	weapon_ring_id = weapon_data.get("ring_id", "")
	
	# Configurer le panneau Mana
	_setup_mana_panel()
	
	# Configurer le panneau Arme
	_setup_weapon_panel()

func _setup_mana_panel() -> void:
	"""Configure le panneau de gauche (Mana)"""
	
	# ✅ VÉRIFICATION : S'assurer que les nœuds existent
	if not mana_icon or not mana_label:
		push_warning("[DuoAttackOption] Nœuds mana non trouvés")
		return
	
	var mana_name = mana_ring_data.get("ring_name", "Mana")
	var mana_icon_path = mana_ring_data.get("icon", "")
	
	# Icône ou texte
	if mana_icon_path != "" and ResourceLoader.exists(mana_icon_path):
		var texture = load(mana_icon_path)
		if texture is Texture2D:
			mana_icon.texture = texture
			mana_icon.visible = true
			mana_label.visible = false
		else:
			_fallback_mana_text(mana_name)
	else:
		_fallback_mana_text(mana_name)

func _setup_weapon_panel() -> void:
	"""Configure le panneau de droite (Arme)"""
	
	# ✅ VÉRIFICATION : S'assurer que les nœuds existent
	if not weapon_icon or not weapon_label:
		push_warning("[DuoAttackOption] Nœuds weapon non trouvés")
		return
	
	var weapon_name = weapon_ring_data.get("ring_name", "Arme")
	var weapon_icon_path = weapon_ring_data.get("icon", "")
	
	# Icône ou texte
	if weapon_icon_path != "" and ResourceLoader.exists(weapon_icon_path):
		var texture = load(weapon_icon_path)
		if texture is Texture2D:
			weapon_icon.texture = texture
			weapon_icon.visible = true
			weapon_label.visible = false
		else:
			_fallback_weapon_text(weapon_name)
	else:
		_fallback_weapon_text(weapon_name)

func _fallback_mana_text(name: String) -> void:
	"""Affiche le nom en texte si pas d'icône"""
	if not mana_icon or not mana_label:
		return
	
	mana_icon.visible = false
	mana_label.visible = true
	mana_label.text = name

func _fallback_weapon_text(name: String) -> void:
	"""Affiche le nom en texte si pas d'icône"""
	if not weapon_icon or not weapon_label:
		return
	
	weapon_icon.visible = false
	weapon_label.visible = true
	weapon_label.text = name
# ============================================================================
# CALLBACKS
# ============================================================================

func _on_button_pressed() -> void:
	option_selected.emit(mana_ring_id, weapon_ring_id)

func _on_button_hovered() -> void:
	option_hovered.emit()

# ============================================================================
# STYLE
# ============================================================================

func set_hover_style(is_hovered: bool) -> void:
	"""Change le style au survol"""
	if is_hovered:
		modulate = Color(1.2, 1.2, 1.2)
	else:
		modulate = Color.WHITE
