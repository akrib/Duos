# scripts/core/campaign_manager.gd
extends Node
## CampaignManager - Gère la progression de la campagne Lua

signal campaign_started()
signal chapter_changed(chapter_id: int)
signal battle_started(battle_id: String)
signal campaign_completed()

# État de la campagne
var campaign_state: Dictionary = {
	"current_chapter": 1,
	"current_battle": 1,
	"battles_won": 0,
	"astraeon_favor": 0,
	"kharvul_favor": 0,
	"story_flags": {}
}

# Mapping des IDs de bataille vers les scripts Lua
const BATTLE_SCRIPTS: Dictionary = {
	"tutorial": "res://lua/campaign/battles/battle_01_tutorial.lua",
	"forest_ambush": "res://lua/campaign/battles/battle_02_forest_ambush.lua",
	"village_defense": "res://lua/campaign/battles/battle_03_village_defense.lua",
	"final_boss": "res://lua/campaign/battles/battle_04_final_boss.lua"
}

# Données des combats
const BATTLE_DATA: Dictionary = {
	"tutorial": {
		"terrain": "forest",
		"player_units": [
			{
				"name": "Sir Gaheris",
				"position": Vector2i(3, 7),
				"stats": {"hp": 120, "attack": 28, "defense": 22, "movement": 4, "range": 1},
				"abilities": ["Shield Bash"],
				"color": Color(0.2, 0.3, 0.8)
			},
			{
				"name": "Elara",
				"position": Vector2i(4, 6),
				"stats": {"hp": 85, "attack": 22, "defense": 12, "movement": 5, "range": 3},
				"abilities": ["Multi-Shot"],
				"color": Color(0.2, 0.7, 0.3)
			},
			{
				"name": "Père Aldric",
				"position": Vector2i(2, 8),
				"stats": {"hp": 95, "attack": 15, "defense": 18, "movement": 4, "range": 2},
				"abilities": ["Heal"],
				"color": Color(0.8, 0.8, 0.3)
			}
		],
		"enemy_units": [
			{
				"name": "Gobelin Scout",
				"position": Vector2i(15, 7),
				"stats": {"hp": 50, "attack": 18, "defense": 8, "movement": 5, "range": 1},
				"color": Color(0.7, 0.2, 0.2)
			},
			{
				"name": "Gobelin Scout",
				"position": Vector2i(16, 6),
				"stats": {"hp": 50, "attack": 18, "defense": 8, "movement": 5, "range": 1},
				"color": Color(0.7, 0.2, 0.2)
			},
			{
				"name": "Gobelin Scout",
				"position": Vector2i(16, 8),
				"stats": {"hp": 50, "attack": 18, "defense": 8, "movement": 5, "range": 1},
				"color": Color(0.7, 0.2, 0.2)
			}
		]
	},
	
	"forest_ambush": {
		"terrain": "forest",
		"player_units": [
			{
				"name": "Sir Gaheris",
				"position": Vector2i(3, 7),
				"stats": {"hp": 120, "attack": 28, "defense": 22, "movement": 4, "range": 1},
				"abilities": ["Shield Bash", "Defend"],
				"color": Color(0.2, 0.3, 0.8)
			},
			{
				"name": "Elara",
				"position": Vector2i(4, 6),
				"stats": {"hp": 85, "attack": 22, "defense": 12, "movement": 5, "range": 3},
				"abilities": ["Multi-Shot"],
				"color": Color(0.2, 0.7, 0.3)
			},
			{
				"name": "Père Aldric",
				"position": Vector2i(2, 8),
				"stats": {"hp": 95, "attack": 15, "defense": 18, "movement": 4, "range": 2},
				"abilities": ["Heal"],
				"color": Color(0.8, 0.8, 0.3)
			}
		],
		"enemy_units": [
			{
				"name": "Chef Gobelin",
				"position": Vector2i(15, 8),
				"stats": {"hp": 120, "attack": 30, "defense": 20, "movement": 5, "range": 1},
				"color": Color(0.9, 0.2, 0.2)
			},
			{
				"name": "Gobelin Guerrier",
				"position": Vector2i(16, 7),
				"stats": {"hp": 70, "attack": 22, "defense": 12, "movement": 5, "range": 1},
				"color": Color(0.7, 0.2, 0.2)
			},
			{
				"name": "Gobelin Guerrier",
				"position": Vector2i(16, 9),
				"stats": {"hp": 70, "attack": 22, "defense": 12, "movement": 5, "range": 1},
				"color": Color(0.7, 0.2, 0.2)
			},
			{
				"name": "Gobelin Archer",
				"position": Vector2i(18, 8),
				"stats": {"hp": 55, "attack": 20, "defense": 8, "movement": 4, "range": 3},
				"color": Color(0.8, 0.3, 0.2)
			},
			{
				"name": "Shaman Gobelin",
				"position": Vector2i(19, 7),
				"stats": {"hp": 60, "attack": 18, "defense": 10, "movement": 4, "range": 2},
				"abilities": ["Heal"],
				"color": Color(0.6, 0.2, 0.6)
			}
		]
	},
	
	"village_defense": {
		"terrain": "plains",
		"player_units": [
			{
				"name": "Sir Gaheris",
				"position": Vector2i(10, 10),
				"stats": {"hp": 140, "attack": 32, "defense": 25, "movement": 4, "range": 1},
				"abilities": ["Shield Bash", "Defend", "Rally"],
				"color": Color(0.2, 0.3, 0.8)
			},
			{
				"name": "Elara",
				"position": Vector2i(11, 9),
				"stats": {"hp": 95, "attack": 26, "defense": 15, "movement": 5, "range": 3},
				"abilities": ["Multi-Shot", "Eagle Eye"],
				"color": Color(0.2, 0.7, 0.3)
			},
			{
				"name": "Père Aldric",
				"position": Vector2i(9, 9),
				"stats": {"hp": 110, "attack": 18, "defense": 20, "movement": 4, "range": 2},
				"abilities": ["Heal", "Divine Shield"],
				"color": Color(0.8, 0.8, 0.3)
			}
		],
		"enemy_units": [
			{
				"name": "Gobelin Pillard",
				"position": Vector2i(1, 7),
				"stats": {"hp": 70, "attack": 25, "defense": 12, "movement": 6, "range": 1},
				"color": Color(0.8, 0.3, 0.2)
			},
			{
				"name": "Gobelin Pillard",
				"position": Vector2i(2, 14),
				"stats": {"hp": 70, "attack": 25, "defense": 12, "movement": 6, "range": 1},
				"color": Color(0.8, 0.3, 0.2)
			}
		],
		"neutral_units": [
			{
				"name": "Civil",
				"position": Vector2i(10, 12),
				"stats": {"hp": 30, "attack": 0, "defense": 5, "movement": 2, "range": 0},
				"color": Color(0.5, 0.5, 0.5)
			},
			{
				"name": "Civil",
				"position": Vector2i(12, 12),
				"stats": {"hp": 30, "attack": 0, "defense": 5, "movement": 2, "range": 0},
				"color": Color(0.5, 0.5, 0.5)
			},
			{
				"name": "Ancien du Village",
				"position": Vector2i(11, 13),
				"stats": {"hp": 40, "attack": 0, "defense": 8, "movement": 1, "range": 0},
				"color": Color(0.6, 0.6, 0.6)
			}
		]
	},
	
	"final_boss": {
		"terrain": "mountain",
		"player_units": [
			{
				"name": "Sir Gaheris",
				"position": Vector2i(5, 10),
				"stats": {"hp": 160, "attack": 35, "defense": 28, "movement": 4, "range": 1},
				"abilities": ["Shield Bash", "Defend", "Rally", "Heroic Strike"],
				"color": Color(0.2, 0.3, 0.8)
			},
			{
				"name": "Elara",
				"position": Vector2i(6, 9),
				"stats": {"hp": 105, "attack": 30, "defense": 18, "movement": 5, "range": 3},
				"abilities": ["Multi-Shot", "Eagle Eye", "Piercing Shot"],
				"color": Color(0.2, 0.7, 0.3)
			},
			{
				"name": "Père Aldric",
				"position": Vector2i(4, 9),
				"stats": {"hp": 125, "attack": 22, "defense": 22, "movement": 4, "range": 2},
				"abilities": ["Heal", "Divine Shield", "Smite"],
				"color": Color(0.8, 0.8, 0.3)
			}
		],
		"enemy_units": [
			{
				"name": "Roi Gobelin Gornak",
				"position": Vector2i(10, 7),
				"stats": {"hp": 300, "attack": 45, "defense": 30, "movement": 5, "range": 1},
				"abilities": ["Cleave", "Battle Roar"],
				"color": Color(0.95, 0.1, 0.1)
			}
		]
	}
}

func _ready() -> void:
	# Connecter aux événements de combat
	EventBus.safe_connect("battle_ended", _on_battle_ended)
	
	print("[CampaignManager] Initialisé")

## Démarrer une nouvelle campagne
func start_new_campaign() -> void:
	print("[CampaignManager] 🎬 Nouvelle campagne démarrée")
	
	# Réinitialiser l'état
	campaign_state = {
		"current_chapter": 1,
		"current_battle": 1,
		"battles_won": 0,
		"astraeon_favor": 0,
		"kharvul_favor": 0,
		"story_flags": {}
	}
	
	campaign_started.emit()
	
	# Charger le gestionnaire de campagne Lua
	var error = LuaManager.load_script("res://lua/campaign/campaign_manager.lua")
	if error:
		push_error("[CampaignManager] Erreur chargement script: ", error.message)
		return
	
	# Démarrer le premier combat
	await get_tree().create_timer(0.5).timeout
	start_next_battle()

## Démarrer le prochain combat de la campagne
func start_next_battle() -> void:
	# Récupérer l'ID du combat actuel depuis Lua
	var battle_id = _get_current_battle_id()
	
	if not battle_id:
		print("[CampaignManager] ✅ Campagne terminée!")
		campaign_completed.emit()
		_show_campaign_end()
		return
	
	print("[CampaignManager] 🎯 Démarrage du combat: ", battle_id)
	battle_started.emit(battle_id)
	
	# Charger le script Lua du combat
	if BATTLE_SCRIPTS.has(battle_id):
		var lua_script = BATTLE_SCRIPTS[battle_id]
		var error = LuaManager.load_script(lua_script)
		if error:
			push_error("[CampaignManager] Erreur chargement combat: ", error.message)
			return
	
	# Préparer les données du combat
	var battle_data = _prepare_battle_data(battle_id)
	
	# Lancer le combat
	EventBus.start_battle(battle_data)
	EventBus.change_scene(SceneRegistry.SceneID.BATTLE)

func _get_current_battle_id() -> String:
	# Chapitres et leurs combats
	var chapters = [
		["tutorial", "forest_ambush"],
		["village_defense"],
		["final_boss"]
	]
	
	var chapter_idx = campaign_state.current_chapter - 1
	var battle_idx = campaign_state.current_battle - 1
	
	if chapter_idx >= chapters.size():
		return ""
	
	var chapter_battles = chapters[chapter_idx]
	if battle_idx >= chapter_battles.size():
		return ""
	
	return chapter_battles[battle_idx]

func _prepare_battle_data(battle_id: String) -> Dictionary:
	var base_data = BATTLE_DATA.get(battle_id, {})
	
	var battle_data = {
		"battle_id": battle_id + "_" + str(Time.get_unix_time_from_system()),
		"terrain": base_data.get("terrain", "plains"),
		"player_units": base_data.get("player_units", []),
		"enemy_units": base_data.get("enemy_units", []),
		"objectives": {
			"primary": [
				{"type": "defeat_all_enemies", "description": "Éliminez tous les ennemis"}
			]
		},
		"scenario": {
			"lua_script": BATTLE_SCRIPTS.get(battle_id, "")
		}
	}
	
	# Ajouter unités neutres si présentes
	if base_data.has("neutral_units"):
		battle_data["neutral_units"] = base_data.neutral_units
	
	return battle_data

func _on_battle_ended(results: Dictionary) -> void:
	print("[CampaignManager] Combat terminé: ", results.get("victory", false))
	
	if results.get("victory", false):
		campaign_state.battles_won += 1
		
		# Mettre à jour la faveur divine
		if results.has("rewards") and results.rewards.has("divine_favor"):
			for favor in results.rewards.divine_favor:
				if favor.has("god") and favor.has("amount"):
					_add_divine_favor(favor.god, favor.amount)
		
		# Avancer au combat suivant
		_advance_campaign()
	else:
		# Défaite - proposer de réessayer
		print("[CampaignManager] Défaite - Réessayez")

func _advance_campaign() -> void:
	campaign_state.current_battle += 1
	
	# Vérifier si le chapitre est terminé
	var battle_id = _get_current_battle_id()
	
	if not battle_id:
		# Chapitre terminé
		campaign_state.current_chapter += 1
		campaign_state.current_battle = 1
		
		# Vérifier si la campagne est terminée
		if campaign_state.current_chapter > 3:
			campaign_completed.emit()
			_show_campaign_end()
			return
		
		# Nouveau chapitre
		chapter_changed.emit(campaign_state.current_chapter)
		_show_chapter_intro()
	else:
		# Prochain combat dans le même chapitre
		start_next_battle()

func _show_chapter_intro() -> void:
	# Afficher l'intro du chapitre
	await get_tree().create_timer(2.0).timeout
	EventBus.notify("Nouveau Chapitre !", "success")
	await get_tree().create_timer(1.0).timeout
	start_next_battle()

func _show_campaign_end() -> void:
	EventBus.notify("🎉 CAMPAGNE TERMINÉE ! 🎉", "success")
	await get_tree().create_timer(3.0).timeout
	EventBus.change_scene(SceneRegistry.SceneID.MAIN_MENU)

func _add_divine_favor(god: String, amount: int) -> void:
	if god == "Astraeon":
		campaign_state.astraeon_favor += amount
	elif god == "Kharvul":
		campaign_state.kharvul_favor += amount
	
	EventBus.add_divine_points(god, amount)

## Obtenir l'état de la campagne
func get_campaign_state() -> Dictionary:
	return campaign_state.duplicate()
