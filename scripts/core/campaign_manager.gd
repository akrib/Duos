# scripts/core/campaign_manager.gd
extends Node
class_name CampaignManager

signal battle_started(battle_id: String)

var campaign_state: Dictionary = {
	"current_chapter": 1,
	"current_battle": 1,
	"battles_won": 0
}

# ✅ Chemins vers les fichiers JSON de données de combat
const BATTLE_DATA_PATHS: Dictionary = {
	"tutorial": "res://data/battles/tutorial.json",
	"forest_battle": "res://data/battles/forest_battle.json",
	"village_defense": "res://data/battles/village_defense.json",
	"boss_fight": "res://data/battles/boss_fight.json"
}

func _ready() -> void:
	EventBus.safe_connect("battle_ended", _on_battle_ended)
	print("[CampaignManager] ✅ Initialisé (mode JSON)")

## Démarrer un combat en chargeant ses données depuis JSON
func start_battle(battle_id: String) -> void:
	print("[CampaignManager] 🎯 Chargement du combat : ", battle_id)
	
	# Charger depuis JSON
	var battle_data = load_battle_data_from_json(battle_id)
	
	if battle_data.is_empty():
		push_error("[CampaignManager] Impossible de charger : ", battle_id)
		return
	
	# Ajouter un ID unique
	battle_data["battle_id"] = battle_id + "_" + str(Time.get_unix_time_from_system())
	
	# Stocker dans BattleDataManager
	var stored = BattleDataManager.set_battle_data(battle_data)
	
	if stored:
		print("[CampaignManager] ✅ Données de combat stockées")
		EventBus.change_scene(SceneRegistry.SceneID.BATTLE)
	else:
		push_error("[CampaignManager] ❌ Échec du stockage des données")

## Charge un fichier JSON de données de combat
func load_battle_data_from_json(battle_id: String) -> Dictionary:
	if not BATTLE_DATA_PATHS.has(battle_id):
		push_error("[CampaignManager] Battle ID inconnu : ", battle_id)
		return {}
	
	var json_path = BATTLE_DATA_PATHS[battle_id]
	var json_loader = JSONDataLoader.new()
	var battle_data = json_loader.load_json_file(json_path)
	
	if typeof(battle_data) != TYPE_DICTIONARY or battle_data.is_empty():
		push_error("[CampaignManager] Impossible de charger : ", battle_id)
		return {}
	
	# Convertir position {x, y} → Vector2i
	battle_data = _convert_json_positions(battle_data)
	
	print("[CampaignManager] ✅ Battle data chargée : ", battle_id)
	return battle_data

## Convertit les positions JSON en Vector2i
func _convert_json_positions(data: Dictionary) -> Dictionary:
	var result = data.duplicate(true)
	
	# Player units
	if result.has("player_units"):
		for unit in result.player_units:
			if unit.has("position"):
				var pos = unit.position
				unit.position = Vector2i(pos.x, pos.y)
	
	# Enemy units
	if result.has("enemy_units"):
		for unit in result.enemy_units:
			if unit.has("position"):
				var pos = unit.position
				unit.position = Vector2i(pos.x, pos.y)
	
	return result

func _on_battle_ended(results: Dictionary) -> void:
	print("[CampaignManager] Combat terminé")
	
	if results.get("victory", false):
		campaign_state.battles_won += 1
		_advance_campaign()

func _advance_campaign() -> void:
	campaign_state.current_battle += 1
	# TODO: Logique de progression de campagne

## Démarre une nouvelle campagne
func start_new_campaign() -> void:
	print("[CampaignManager] 🎮 Démarrage nouvelle campagne (JSON)")
	
	# Charger les données de démarrage depuis JSON
	var campaign_data = _load_campaign_start_from_json()
	
	if campaign_data.is_empty():
		push_error("[CampaignManager] Impossible de charger campaign_start.json")
		return
	
	# Initialiser l'état de la campagne depuis JSON
	if campaign_data.has("initial_state"):
		var initial_state = campaign_data.initial_state
		campaign_state.current_chapter = initial_state.get("chapter", 1)
		campaign_state.current_battle = initial_state.get("battle_index", 0)
		campaign_state.battles_won = initial_state.get("battles_won", 0)
	
	# Émettre l'événement
	EventBus.campaign_started.emit()
	
	print("[CampaignManager] ✅ Campagne initialisée : ", campaign_data.get("campaign_id"))

## Charge le fichier campaign_start.json
func _load_campaign_start_from_json() -> Dictionary:
	var json_path = "res://data/campaign/campaign_start.json"
	
	if not FileAccess.file_exists(json_path):
		push_error("[CampaignManager] Fichier introuvable : ", json_path)
		return {}
	
	# Utiliser JSONDataLoader
	var json_loader = JSONDataLoader.new()
	var data = json_loader.load_json_file(json_path)
	
	if typeof(data) != TYPE_DICTIONARY or data.is_empty():
		push_error("[CampaignManager] Format invalide pour campaign_start.json")
		return {}
	
	return data
