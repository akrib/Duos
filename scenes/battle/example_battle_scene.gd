extends Node2D
## Exemple de scène de combat utilisant le système de chargement découplé

class_name BattleScene

# Références aux nœuds
@onready var grid: TileMap = $Grid
@onready var ui_panel: Control = $UIPanel
@onready var end_turn_button: Button = $UIPanel/EndTurnButton
@onready var retreat_button: Button = $UIPanel/RetreatButton

# État du combat
var active_duos: Array[Array] = []  # Array de [unit_a, unit_b]
var current_turn: int = 0
var battle_data: Dictionary = {}

# Statistiques du combat
var battle_stats: Dictionary = {
	"total_attacks": 0,
	"total_damage": 0,
	"duos_formed": 0,
	"duos_broken": 0,
	"mvp_duo": [],
}

func _ready() -> void:
	# S'abonner aux événements globaux
	_connect_to_event_bus()
	
	# Initialiser le combat
	_initialize_battle()

## Auto-connexion des signaux UI
func _get_signal_connections() -> Array:
	if not is_node_ready():
		return []
	
	return [
		{
			"source": end_turn_button,
			"signal_name": "pressed",
			"target": self,
			"method": "_on_end_turn_pressed"
		},
		{
			"source": retreat_button,
			"signal_name": "pressed",
			"target": self,
			"method": "_on_retreat_pressed"
		},
	]

func _connect_to_event_bus() -> void:
	"""Connexion aux événements globaux"""
	EventBus.safe_connect("duo_formed", _on_duo_formed)
	EventBus.safe_connect("duo_broken", _on_duo_broken)
	EventBus.safe_connect("unit_died", _on_unit_died)
	EventBus.safe_connect("divine_points_gained", _on_divine_points_gained)

func _initialize_battle() -> void:
	"""Initialisation du combat"""
	print("[Battle] Initialisation...")
	
	# Récupérer les données de combat depuis l'EventBus ou GameManager
	# (À implémenter selon votre logique)
	
	# Notifier le début du combat
	battle_data = {
		"battle_id": "battle_" + str(Time.get_unix_time_from_system()),
		"location": "Northern Plains",
		"difficulty": "normal",
	}
	
	EventBus.start_battle(battle_data)

# ============================================================================
# LOGIQUE DE COMBAT - DUOS
# ============================================================================

func form_duo(unit_a: Node, unit_b: Node) -> bool:
	"""Forme un duo entre deux unités"""
	
	# Vérifier l'adjacence
	if not _are_units_adjacent(unit_a, unit_b):
		EventBus.notify("Les unités doivent être adjacentes pour former un duo", "warning")
		return false
	
	# Créer le duo
	var duo = [unit_a, unit_b]
	active_duos.append(duo)
	
	# Mise à jour des statistiques
	battle_stats.duos_formed += 1
	
	# Notifier le système global
	EventBus.form_duo(unit_a, unit_b)
	
	# Points divins (Stabilité via coopération)
	EventBus.add_divine_points("Astraeon", 1)
	
	print("[Battle] Duo formé : ", unit_a.name, " + ", unit_b.name)
	return true

func break_duo(duo: Array) -> void:
	"""Casse un duo (repositionnement, attaque, etc.)"""
	if not active_duos.has(duo):
		return
	
	active_duos.erase(duo)
	battle_stats.duos_broken += 1
	
	var unit_a = duo[0]
	var unit_b = duo[1]
	
	# Notifier
	EventBus.break_duo(unit_a, unit_b)
	
	print("[Battle] Duo cassé : ", unit_a.name, " + ", unit_b.name)

func execute_duo_attack(duo: Array, target: Node) -> void:
	"""Exécute une attaque en duo"""
	if duo.size() != 2:
		push_error("[Battle] Duo invalide pour l'attaque")
		return
	
	var leader = duo[0]
	var support = duo[1]
	
	# Calcul des dégâts (exemple simplifié)
	var base_damage = leader.attack_power
	var mana_bonus = support.mana_power * 0.5
	var total_damage = int(base_damage + mana_bonus)
	
	# Appliquer les dégâts
	target.take_damage(total_damage)
	
	# Statistiques
	battle_stats.total_attacks += 1
	battle_stats.total_damage += total_damage
	
	# Notifier l'attaque
	EventBus.attack(leader, target, total_damage)
	
	# Incrémenter la menace du duo
	EventBus.threat_level_changed.emit(duo, 1.0)
	
	# Points divins (Stabilité via duo)
	EventBus.add_divine_points("Astraeon", 2)
	
	print("[Battle] Attaque duo : ", total_damage, " dégâts")

func execute_last_man_stand(unit: Node) -> void:
	"""Attaque désespérée solo (instable)"""
	if not unit.is_alone():
		push_error("[Battle] L'unité n'est pas seule")
		return
	
	var mana_percentage = unit.current_mana / float(unit.max_mana)
	var base_damage = unit.attack_power / 8.0
	var explosion_damage = int(base_damage * (1.0 + mana_percentage))
	
	# Vider le mana
	unit.current_mana = 0
	
	# Dégâts en zone (8 cases adjacentes)
	var targets = _get_adjacent_enemies(unit, 1)
	for target in targets:
		target.take_damage(explosion_damage)
		EventBus.attack(unit, target, explosion_damage)
	
	# Points divins (Chaos via instabilité)
	EventBus.add_divine_points("Kharvûl", 3)
	
	EventBus.notify("Last Man Stand ! Explosion de mana !", "warning")
	print("[Battle] Last Man Stand : ", explosion_damage, " dégâts en zone")

# ============================================================================
# CALLBACKS EVENTBUS
# ============================================================================

func _on_duo_formed(unit_a: Node, unit_b: Node) -> void:
	"""Réaction à la formation d'un duo (autre système)"""
	print("[Battle] Duo détecté par EventBus")
	# Mettre à jour l'UI, les effets visuels, etc.

func _on_duo_broken(unit_a: Node, unit_b: Node) -> void:
	"""Réaction à la rupture d'un duo"""
	print("[Battle] Duo cassé détecté par EventBus")

func _on_unit_died(unit: Node) -> void:
	"""Réaction à la mort d'une unité"""
	print("[Battle] Unité morte : ", unit.name)
	
	# Vérifier fin de combat
	if _check_battle_end():
		_end_battle()

func _on_divine_points_gained(god_name: String, points: int) -> void:
	"""Réaction aux points divins gagnés"""
	print("[Battle] +", points, " points pour ", god_name)

# ============================================================================
# GESTION DES TOURS
# ============================================================================

func _on_end_turn_pressed() -> void:
	"""Fin du tour"""
	current_turn += 1
	print("[Battle] Fin du tour ", current_turn)
	
	# Logique de tour ennemi, etc.
	# ...

func _on_retreat_pressed() -> void:
	"""Retraite du combat"""
	EventBus.notify("Retraite du combat...", "info")
	
	# Résultats de retraite
	var results = {
		"victory": false,
		"retreat": true,
		"stats": battle_stats,
	}
	
	EventBus.end_battle(results)
	
	# Retour à la carte
	EventBus.change_scene(SceneRegistry.SceneID.WORLD_MAP)

# ============================================================================
# FIN DE COMBAT
# ============================================================================

func _check_battle_end() -> bool:
	"""Vérifie si le combat est terminé"""
	# TODO : Implémenter la logique de fin
	return false

func _end_battle() -> void:
	"""Termine le combat"""
	print("[Battle] Combat terminé !")
	
	# Déterminer le MVP
	var mvp_duo = _determine_mvp()
	battle_stats.mvp_duo = mvp_duo
	
	# Notifier le MVP
	if mvp_duo.size() == 2:
		EventBus.mvp_awarded.emit(mvp_duo[0], battle_data.battle_id)
		EventBus.legend_gained.emit(mvp_duo, "battle_victor")
	
	# Résultats
	var results = {
		"victory": true,
		"stats": battle_stats,
		"mvp": mvp_duo,
		"rewards": {
			"gold": 500,
			"experience": 200,
		}
	}
	
	EventBus.end_battle(results)
	
	# Transition vers l'écran de résultats
	await get_tree().create_timer(1.0).timeout
	EventBus.change_scene(SceneRegistry.SceneID.BATTLE_RESULTS)

func _determine_mvp() -> Array:
	"""Détermine le duo MVP du combat"""
	# TODO : Implémenter la logique MVP
	return []

# ============================================================================
# HELPERS
# ============================================================================

func _are_units_adjacent(unit_a: Node, unit_b: Node) -> bool:
	"""Vérifie si deux unités sont adjacentes"""
	# TODO : Implémenter selon votre grille
	return true

func _get_adjacent_enemies(unit: Node, radius: int) -> Array:
	"""Récupère les ennemis adjacents"""
	# TODO : Implémenter selon votre grille
	return []

# ============================================================================
# NETTOYAGE
# ============================================================================

func _exit_tree() -> void:
	"""Nettoyage à la fermeture de la scène"""
	EventBus.disconnect_all(self)
	print("[Battle] Scène nettoyée")
