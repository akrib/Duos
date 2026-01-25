# scripts/core/dialogue_data_loader.gd
extends Node
class_name DialogueDataLoader

const DIALOGUES_PATH = "res://lua/dialogues/"

var _dialogue_cache: Dictionary = {}

# ============================================================================
# CHARGEMENT
# ============================================================================

## Charge un dialogue depuis Lua (avec validation)
func load_dialogue(dialogue_id: String) -> Dictionary:
	print("[DialogueDataLoader] Chargement du dialogue : ", dialogue_id)
	
	# Vérifier le cache local
	if _dialogue_cache.has(dialogue_id):
		print("[DialogueDataLoader] Dialogue trouvé en cache")
		return _dialogue_cache[dialogue_id]
	
	# Construire le chemin
	var lua_path = DIALOGUES_PATH + dialogue_id + ".lua"
	
	# Charger via LuaDataLoader
	var raw_data = LuaDataLoader.load_lua_data(lua_path, true, true)
	
	if typeof(raw_data) != TYPE_DICTIONARY or raw_data.is_empty():
		push_error("[DialogueDataLoader] Impossible de charger : ", dialogue_id)
		return {}
	
	# ✅ VALIDATION
	var validation = DataValidator.validate_dialogue(raw_data, dialogue_id)
	
	if not validation.valid:
		push_error("[DialogueDataLoader] ❌ Dialogue invalide : ", dialogue_id)
		for error in validation.errors:
			push_error("  - ", error)
		
		# Mode strict : retourner vide
		if LuaDataLoader.validation_mode == LuaDataLoader.ValidationMode.STRICT:
			return {}
	
	# Warnings
	for warning in validation.warnings:
		push_warning("[DialogueDataLoader] ⚠️ ", dialogue_id, " : ", warning)
	
	# Post-traitement spécifique aux dialogues
	var dialogue_data = _post_process_dialogue(raw_data)
	
	# Mettre en cache
	_dialogue_cache[dialogue_id] = dialogue_data
	
	print("[DialogueDataLoader] ✅ Dialogue chargé et validé : ", dialogue_id)
	return dialogue_data

## Post-traitement spécifique aux dialogues
func _post_process_dialogue(raw_data: Dictionary) -> Dictionary:
	# Les conversions de base (Vector2i, Color) sont déjà faites par LuaDataLoader
	# On ne garde ici QUE les conversions spécifiques aux dialogues
	
	return raw_data

## Précharge plusieurs dialogues
func preload_dialogues(dialogue_ids: Array) -> void:
	for dialogue_id in dialogue_ids:
		load_dialogue(dialogue_id)

## Liste tous les dialogues disponibles
func get_available_dialogues() -> Array:
	return LuaDataLoader._get_lua_files_in_folder(DIALOGUES_PATH).map(
		func(file): return file.replace(".lua", "")
	)

## Vide le cache
func clear_cache() -> void:
	_dialogue_cache.clear()
	# Vider aussi le cache global du loader
	for dialogue_id in get_available_dialogues():
		LuaDataLoader.clear_cache_for(DIALOGUES_PATH + dialogue_id + ".lua")
