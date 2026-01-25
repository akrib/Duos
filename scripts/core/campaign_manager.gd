# scripts/core/campaign_manager.gd
extends Node
class_name CampaignManager

signal battle_started(battle_id: String)

var campaign_state: Dictionary = {
	"current_chapter": 1,
	"current_battle": 1,
	"battles_won": 0
}

# ✅ NE PLUS AVOIR DE DONNÉES ICI
# const BATTLE_DATA = {} ← SUPPRIMÉ

# ✅ Chemins vers les fichiers Lua de données
const BATTLE_DATA_PATHS: Dictionary = {
	"tutorial": "res://lua/battle_data/tutorial.lua",
	"forest_battle": "res://lua/battle_data/forest_battle.lua",
	"village_defense": "res://lua/battle_data/village_defense.lua",
	"boss_fight": "res://lua/battle_data/boss_fight.lua"
}

func _ready() -> void:
	EventBus.safe_connect("battle_ended", _on_battle_ended)
	#_load_campaign_flow()
	print("[CampaignManager] Initialisé (mode Lua)")

## Démarrer un combat en chargeant ses données depuis Lua
# ✅ APRÈS
func start_battle(battle_id: String) -> void:
	"""Démarre un combat en chargeant et validant ses données"""
	print("[CampaignManager] 🎯 Chargement du combat : ", battle_id)
	
	# 1. Charger les données depuis Lua
	var battle_data = load_battle_data_from_lua(battle_id)
	
	if battle_data.is_empty():
		push_error("[CampaignManager] Impossible de charger : ", battle_id)
		return
	
	# 2. Ajouter un ID unique d'instance
	battle_data["battle_id"] = battle_id + "_" + str(Time.get_unix_time_from_system())
	
	# 3. ✅ STOCKER dans BattleDataManager
	var stored = BattleDataManager.set_battle_data(battle_data)
	
	if not stored:
		push_error("[CampaignManager] ❌ Données de combat invalides pour : ", battle_id)
		return
		
	# 4. Émettre les signaux
	battle_started.emit(battle_id)
	EventBus.start_battle(battle_data["battle_id"])  # ✅ Juste l'ID
	
	# 5. Changer de scène
	EventBus.change_scene(SceneRegistry.SceneID.BATTLE)

## Charge un fichier Lua de données de combat
func load_battle_data_from_lua(battle_id: String) -> Dictionary:
	if not BATTLE_DATA_PATHS.has(battle_id):
		push_error("[CampaignManager] Battle ID inconnu : ", battle_id)
		return {}
	
	var lua_path = BATTLE_DATA_PATHS[battle_id]
	
	# Charger le fichier Lua
	var error = LuaManager.load_script(lua_path)
	if error:
		push_error("[CampaignManager] Erreur Lua : ", error.message)
		return {}
	
	# Le script Lua retourne une table avec `return { ... }`
	# On la récupère en appelant le script comme une fonction
	var battle_data = LuaManager.call_lua_function("", [])
	
	if typeof(battle_data) != TYPE_DICTIONARY:
		push_error("[CampaignManager] Format Lua invalide")
		return {}
	
	# Convertir les données Lua en format Godot
	return _convert_lua_to_godot(battle_data)

## Convertit les données Lua en format Godot compatible
func _convert_lua_to_godot(lua_data: Dictionary) -> Dictionary:
	var result = lua_data.duplicate(true)
	
	# Convertir les positions {x=3, y=7} en Vector2i
	if result.has("player_units"):
		for unit in result.player_units:
			if unit.has("position"):
				var pos = unit.position
				unit.position = Vector2i(pos.x, pos.y)
			
			if unit.has("color"):
				var c = unit.color
				unit.color = Color(c.r, c.g, c.b, c.get("a", 1.0))
	
	if result.has("enemy_units"):
		for unit in result.enemy_units:
			if unit.has("position"):
				var pos = unit.position
				unit.position = Vector2i(pos.x, pos.y)
			
			if unit.has("color"):
				var c = unit.color
				unit.color = Color(c.r, c.g, c.b, c.get("a", 1.0))
	
	return result

func _on_battle_ended(results: Dictionary) -> void:
	print("[CampaignManager] Combat terminé")
	
	if results.get("victory", false):
		campaign_state.battles_won += 1
		_advance_campaign()

func _advance_campaign() -> void:
	campaign_state.current_battle += 1
	# Logique de progression...

func start_new_campaign() -> void:
	print("[CampaignManager] 🎮 Démarrage nouvelle campagne (Lua)")
	
	# Charger les données de démarrage depuis Lua
	var campaign_data = _load_campaign_start_from_lua()
	
	if campaign_data.is_empty():
		push_error("[CampaignManager] Impossible de charger campaign_start.lua")
		return
	
	# Initialiser l'état de la campagne depuis Lua
	if campaign_data.has("initial_state"):
		var initial_state = campaign_data.initial_state
		campaign_state.current_chapter = initial_state.get("chapter", 1)
		campaign_state.current_battle = initial_state.get("battle_index", 0)
		campaign_state.battles_won = initial_state.get("battles_won", 0)
	
	# Émettre l'événement
	EventBus.campaign_started.emit()
	
	print("[CampaignManager] ✅ Campagne initialisée : ", campaign_data.get("campaign_id"))

## Charge le fichier campaign_start.lua
func _load_campaign_start_from_lua() -> Dictionary:
	var lua_path = "res://lua/campaign/campaign_start.lua"
	
	if not FileAccess.file_exists(lua_path):
		push_error("[CampaignManager] Fichier introuvable : ", lua_path)
		return {}
	
	var error = LuaManager.load_script(lua_path, false)
	if error:
		push_error("[CampaignManager] Erreur Lua : ", error.message)
		return {}
	
	# Lire et exécuter le contenu
	var file = FileAccess.open(lua_path, FileAccess.READ)
	var lua_content = file.get_as_text()
	file.close()
	
	var lua = LuaAPI.new()
	lua.bind_libraries(["base", "table", "string"])
	lua.do_string(lua_content)
	
	var data = lua.pull_variant("_RESULT")
	
	if typeof(data) != TYPE_DICTIONARY:
		push_error("[CampaignManager] Format invalide pour campaign_start.lua")
		return {}
	
	return data
