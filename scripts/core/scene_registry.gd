extends Node
## SceneRegistry - Registre centralisé de toutes les scènes du jeu
## Permet un accès découplé aux chemins de scènes

class_name SceneRegistry

# Énumération des scènes principales
enum SceneID {
	# Menus
	MAIN_MENU,
	OPTIONS_MENU,
	PAUSE_MENU,
	SAVE_LOAD_MENU,
	
	# Monde
	WORLD_MAP,
	TOWN,
	CASTLE,
	
	# Combat
	BATTLE,
	BATTLE_PREPARATION,
	BATTLE_RESULTS,
	
	# Narration
	CUTSCENE,
	DIALOGUE,
	
	# Système
	LOADING_SCREEN,
	CREDITS,
}

# Registre des chemins de scènes
const SCENE_PATHS: Dictionary = {
	# Menus
	SceneID.MAIN_MENU: "res://scenes/menu/main_menu.tscn",
	SceneID.OPTIONS_MENU: "res://scenes/menu/options_menu.tscn",
	SceneID.PAUSE_MENU: "res://scenes/menu/pause_menu.tscn",
	SceneID.SAVE_LOAD_MENU: "res://scenes/menu/save_load_menu.tscn",
	
	# Monde
	SceneID.WORLD_MAP: "res://scenes/world/world_map.tscn",
	SceneID.TOWN: "res://scenes/world/town.tscn",
	SceneID.CASTLE: "res://scenes/world/castle.tscn",
	
	# Combat
	SceneID.BATTLE: "res://scenes/battle/battle_3d.tscn",
	SceneID.BATTLE_PREPARATION: "res://scenes/battle/battle_preparation.tscn",
	SceneID.BATTLE_RESULTS: "res://scenes/battle/battle_results.tscn",
	
	# Narration
	SceneID.CUTSCENE: "res://scenes/narrative/cutscene.tscn",
	SceneID.DIALOGUE: "res://scenes/narrative/dialogue.tscn",
	
	# Système
	SceneID.LOADING_SCREEN: "res://scenes/system/loading_screen.tscn",
	SceneID.CREDITS: "res://scenes/system/credits.tscn",
}

# Métadonnées des scènes (optionnel)
const SCENE_METADATA: Dictionary = {
	SceneID.MAIN_MENU: {
		"category": "menu",
		"requires_save": false,
		"pausable": false,
	},
	SceneID.WORLD_MAP: {
		"category": "world",
		"requires_save": true,
		"pausable": true,
		"music": "res://audio/music/world_theme.ogg",
	},
	SceneID.BATTLE: {
		"category": "battle",
		"requires_save": true,
		"pausable": true,
		"music": "res://audio/music/battle_theme.ogg",
	},
}

## Obtenir le chemin d'une scène
static func get_scene_path(scene_id: SceneID) -> String:
	if SCENE_PATHS.has(scene_id):
		return SCENE_PATHS[scene_id]
	
	push_error("[SceneRegistry] SceneID introuvable : ", scene_id)
	return ""

## Obtenir les métadonnées d'une scène
static func get_scene_metadata(scene_id: SceneID) -> Dictionary:
	if SCENE_METADATA.has(scene_id):
		return SCENE_METADATA[scene_id]
	return {}

## Vérifier si une scène existe
static func scene_exists(scene_id: SceneID) -> bool:
	var path = get_scene_path(scene_id)
	return path != "" and ResourceLoader.exists(path)

## Obtenir toutes les scènes d'une catégorie
static func get_scenes_by_category(category: String) -> Array[SceneID]:
	var result: Array[SceneID] = []
	
	for scene_id in SCENE_METADATA:
		var metadata = SCENE_METADATA[scene_id]
		if metadata.get("category") == category:
			result.append(scene_id)
	
	return result

## Obtenir le nom lisible d'une scène
static func get_scene_name(scene_id: SceneID) -> String:
	var scene_names = {
		SceneID.MAIN_MENU: "Menu Principal",
		SceneID.OPTIONS_MENU: "Options",
		SceneID.PAUSE_MENU: "Pause",
		SceneID.SAVE_LOAD_MENU: "Sauvegarder/Charger",
		SceneID.WORLD_MAP: "Carte du Monde",
		SceneID.TOWN: "Ville",
		SceneID.CASTLE: "Château",
		SceneID.BATTLE: "Combat",
		SceneID.BATTLE_PREPARATION: "Préparation Combat",
		SceneID.BATTLE_RESULTS: "Résultats Combat",
		SceneID.CUTSCENE: "Cinématique",
		SceneID.DIALOGUE: "Dialogue",
		SceneID.LOADING_SCREEN: "Chargement",
		SceneID.CREDITS: "Crédits",
	}
	
	return scene_names.get(scene_id, "Inconnu")

## Validation du registre au démarrage
static func validate_registry() -> bool:
	var all_valid = true
	
	for scene_id in SCENE_PATHS:
		var path = SCENE_PATHS[scene_id]
		if not ResourceLoader.exists(path):
			push_warning("[SceneRegistry] Scène manquante : ", get_scene_name(scene_id), " (", path, ")")
			all_valid = false
	
	return all_valid
