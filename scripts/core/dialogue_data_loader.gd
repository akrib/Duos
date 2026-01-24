# scripts/core/dialogue_data_loader.gd
extends Node
class_name DialogueDataLoader

## Charge et gère les données de dialogues depuis des fichiers Lua

const DIALOGUES_PATH = "res://lua/dialogues/"

var _dialogue_cache: Dictionary = {}
var _lua: LuaAPI

func _init():
	_lua = LuaAPI.new()
	_setup_lua_environment()

func _setup_lua_environment():
	# Exposer les fonctions nécessaires
	_lua.bind_libraries(["base", "table", "string"])
	print("[DialogueDataLoader] Environnement Lua initialisé")

## Charge les données d'un dialogue depuis un fichier Lua
func load_dialogue(dialogue_id: String) -> Dictionary:
	print("[DialogueDataLoader] Chargement du dialogue : ", dialogue_id)
	
	# Vérifier le cache
	if _dialogue_cache.has(dialogue_id):
		print("[DialogueDataLoader] Dialogue trouvé en cache")
		return _dialogue_cache[dialogue_id]
	
	# Construire le chemin du fichier
	var file_path = DIALOGUES_PATH + dialogue_id + ".lua"
	
	# Vérifier que le fichier existe
	if not FileAccess.file_exists(file_path):
		push_error("[DialogueDataLoader] Fichier introuvable : ", file_path)
		return {}
	
	# Charger le fichier Lua
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[DialogueDataLoader] Impossible d'ouvrir : ", file_path)
		return {}
	
	var lua_content = file.get_as_text()
	file.close()
	
	# Exécuter le script Lua
	var error = _lua.do_string(lua_content)
	if error is LuaError:
		push_error("[DialogueDataLoader] Erreur Lua : ", error.message)
		return {}
	
	# Récupérer le résultat (le script Lua retourne une table)
	var raw_data = _lua.pull_variant("_RESULT")
	
	if typeof(raw_data) != TYPE_DICTIONARY:
		push_error("[DialogueDataLoader] Format invalide pour : ", dialogue_id)
		return {}
	
	# Post-traiter les données
	var dialogue_data = _process_dialogue_data(raw_data)
	
	# Mettre en cache
	_dialogue_cache[dialogue_id] = dialogue_data
	
	print("[DialogueDataLoader] ✅ Dialogue chargé : ", dialogue_id)
	return dialogue_data

## Post-traite les données de dialogue pour Godot
func _process_dialogue_data(raw_data: Dictionary) -> Dictionary:
	var processed = raw_data.duplicate(true)
	
	# Convertir les couleurs
	if processed.has("sequences"):
		for sequence in processed.sequences:
			if sequence.has("participants"):
				for participant in sequence.participants:
					if participant.has("color"):
						var c = participant.color
						participant.color = Color(
							c.get("r", 1.0),
							c.get("g", 1.0),
							c.get("b", 1.0),
							c.get("a", 1.0)
						)
	
	return processed

## Précharge plusieurs dialogues
func preload_dialogues(dialogue_ids: Array) -> void:
	print("[DialogueDataLoader] Préchargement de ", dialogue_ids.size(), " dialogues...")
	
	for dialogue_id in dialogue_ids:
		load_dialogue(dialogue_id)
	
	print("[DialogueDataLoader] ✅ Préchargement terminé")

## Obtient la liste de tous les dialogues disponibles
func get_available_dialogues() -> Array:
	var dialogues = []
	var dir = DirAccess.open(DIALOGUES_PATH)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".lua"):
				var dialogue_id = file_name.replace(".lua", "")
				dialogues.append(dialogue_id)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return dialogues

## Vide le cache
func clear_cache() -> void:
	_dialogue_cache.clear()
	print("[DialogueDataLoader] Cache vidé")

## Obtient une séquence spécifique d'un dialogue
func get_sequence(dialogue_id: String, sequence_id: String) -> Dictionary:
	var dialogue = load_dialogue(dialogue_id)
	
	if not dialogue.has("sequences"):
		return {}
	
	for sequence in dialogue.sequences:
		if sequence.get("id") == sequence_id:
			return sequence
	
	push_error("[DialogueDataLoader] Séquence introuvable : ", sequence_id)
	return {}

## Obtient les choix disponibles pour un dialogue
func get_choices(dialogue_id: String) -> Array:
	var dialogue = load_dialogue(dialogue_id)
	return dialogue.get("choices", [])

## Vérifie si un dialogue a des choix
func has_choices(dialogue_id: String) -> bool:
	var dialogue = load_dialogue(dialogue_id)
	return dialogue.has("choices") and dialogue.choices.size() > 0
