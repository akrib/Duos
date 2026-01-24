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
func start_battle(battle_id: String) -> void:
	print("[CampaignManager] 🎯 Chargement du combat : ", battle_id)
	
	# Charger les données depuis Lua
	var battle_data = load_battle_data_from_lua(battle_id)
	
	if battle_data.is_empty():
		push_error("[CampaignManager] Impossible de charger : ", battle_id)
		return
	
	# Ajouter un ID unique pour cette instance
	battle_data["battle_id"] = battle_id + "_" + str(Time.get_unix_time_from_system())
	
	battle_started.emit(battle_id)
	
	# Lancer le combat
	EventBus.start_battle(battle_data)
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

#func _load_campaign_flow() -> void:
	#var error = LuaManager.load_script("res://lua/campaign/campaign_flow.lua")
	#if error:
		#push_error("[CampaignManager] Erreur chargement campaign_flow")
		#return
	#
	#campaign_flow = LuaManager.call_lua_function("", [])
	#print("[CampaignManager] Flux de campagne chargé : ", campaign_flow.chapters.size(), " chapitres")
#
#func get_current_battle_id() -> String:
	#var chapter_idx = campaign_state.current_chapter - 1
	#var battle_idx = campaign_state.current_battle - 1
	#
	#if chapter_idx >= campaign_flow.chapters.size():
		#return ""
	#
	#var chapter = campaign_flow.chapters[chapter_idx]
	#if battle_idx >= chapter.battles.size():
		#return ""
	#
	#return chapter.battles[battle_idx]
