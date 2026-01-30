extends Button
## DuoAttackOption - Bouton unique pour sélectionner une combinaison Mana + Arme

class_name DuoAttackOption

signal option_selected(mana_ring_id: String, weapon_ring_id: String)
signal option_hovered()

@onready var mana_name_label: Label = $HBoxContainer/ManaSection/ManaName
@onready var weapon_name_label: Label = $HBoxContainer/WeaponSection/WeaponName

var mana_ring_id: String = ""
var weapon_ring_id: String = ""

func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)

func setup(mana_data: Dictionary, weapon_data: Dictionary) -> void:
	"""Configure le bouton avec les données de mana et d'arme"""
	
	# Stocker les IDs
	mana_ring_id = mana_data.get("ring_id", "")
	weapon_ring_id = weapon_data.get("ring_id", "")
	
	# Afficher les noms
	mana_name_label.text = mana_data.get("ring_name", "Inconnu")
	weapon_name_label.text = weapon_data.get("ring_name", "Inconnu")
	
	# Debug
	print("[DuoAttackOption] Setup - Mana: ", mana_name_label.text, " | Arme: ", weapon_name_label.text)

func _on_pressed() -> void:
	"""Émis quand le bouton est cliqué"""
	option_selected.emit(mana_ring_id, weapon_ring_id)
	print("[DuoAttackOption] Sélectionné : ", mana_ring_id, " + ", weapon_ring_id)

func _on_mouse_entered() -> void:
	"""Émis au survol"""
	option_hovered.emit()
