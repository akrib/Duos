# scenes/narrative/intro_dialogue.gd
extends Control
## IntroDialogue - Scène dédiée au dialogue d'introduction
## Pilotée à 100% par Lua via campaign_start.lua

class_name IntroDialogue

# ============================================================================
# RÉFÉRENCES UI
# ============================================================================

@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var background: ColorRect = $Background

# ============================================================================
# ÉTAT
# ============================================================================

var campaign_start_data: Dictionary = {}
var current_sequence_index: int = 0

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	# Charger les données de démarrage de campagne depuis Lua
	_load_campaign_start_data()
	
	# Démarrer la séquence
	if not campaign_start_data.is_empty():
		_execute_start_sequence()
	else:
		push_error("[IntroDialogue] Impossible de charger campaign_start.lua")
		_fallback_to_world_map()

# ============================================================================
# CHARGEMENT DEPUIS LUA
# ============================================================================

func _load_campaign_start_data() -> void:
	"""Charge le fichier campaign_start.lua"""
	
	var lua_path = "res://lua/campaign/campaign_start.lua"
	
	if not FileAccess.file_exists(lua_path):
		push_error("[IntroDialogue] Fichier introuvable : ", lua_path)
		return
	
	# Charger via LuaManager
	var error = LuaManager.load_script(lua_path, false)
	if error:
		push_error("[IntroDialogue] Erreur Lua : ", error.message)
		return
	
	# Récupérer les données
	var file = FileAccess.open(lua_path, FileAccess.READ)
	var lua_content = file.get_as_text()
	file.close()
	
	var lua = LuaAPI.new()
	lua.bind_libraries(["base", "table", "string"])
	lua.do_string(lua_content)
	campaign_start_data = lua.pull_variant("_RESULT")
	
	print("[IntroDialogue] ✅ campaign_start.lua chargé : ", campaign_start_data.get("campaign_id"))

# ============================================================================
# EXÉCUTION DE LA SÉQUENCE
# ============================================================================

func _execute_start_sequence() -> void:
	"""Exécute la séquence de démarrage définie dans Lua"""
	
	if not campaign_start_data.has("start_sequence"):
		push_error("[IntroDialogue] Pas de start_sequence définie")
		return
	
	var sequence = campaign_start_data.start_sequence
	current_sequence_index = 0
	
	print("[IntroDialogue] 🎬 Début de la séquence (", sequence.size(), " étapes)")
	
	_execute_next_step()

func _execute_next_step() -> void:
	"""Exécute l'étape suivante de la séquence"""
	
	var sequence = campaign_start_data.start_sequence
	
	# Vérifier si on a fini
	if current_sequence_index >= sequence.size():
		print("[IntroDialogue] ✅ Séquence terminée")
		return
	
	# Récupérer l'étape actuelle
	var step = sequence[current_sequence_index]
	var step_type = step.get("type", "")
	
	print("[IntroDialogue] 📋 Étape ", current_sequence_index + 1, "/", sequence.size(), " : ", step_type)
	
	# Exécuter selon le type
	match step_type:
		"dialogue":
			await _execute_dialogue_step(step)
		
		"transition":
			await _execute_transition_step(step)
		
		"notification":
			_execute_notification_step(step)
		
		"unlock_location":
			_execute_unlock_location_step(step)
		
		_:
			push_warning("[IntroDialogue] Type d'étape inconnu : ", step_type)
	
	# Passer à l'étape suivante
	current_sequence_index += 1
	_execute_next_step()

# ============================================================================
# EXÉCUTION DES DIFFÉRENTS TYPES D'ÉTAPES
# ============================================================================

func _execute_dialogue_step(step: Dictionary) -> void:
	"""Exécute une étape de dialogue"""
	
	var dialogue_id = step.get("dialogue_id", "")
	var blocking = step.get("blocking", true)
	
	if dialogue_id == "":
		push_warning("[IntroDialogue] dialogue_id vide")
		return
	
	print("[IntroDialogue] 💬 Chargement dialogue : ", dialogue_id)
	
	# Charger le dialogue via DialogueDataLoader
	var dialogue_loader = DialogueDataLoader.new()
	var dialogue_data_dict = dialogue_loader.load_dialogue(dialogue_id)
	
	if dialogue_data_dict.is_empty():
		push_error("[IntroDialogue] Impossible de charger le dialogue : ", dialogue_id)
		return
	
	# Convertir en DialogueData
	var dialogue_data = _convert_to_dialogue_data(dialogue_data_dict)
	
	# Démarrer le dialogue
	Dialogue_Manager.start_dialogue(dialogue_data, dialogue_box)
	
	# Attendre la fin si bloquant
	if blocking:
		await Dialogue_Manager.dialogue_ended
		print("[IntroDialogue] ✅ Dialogue terminé")

func _execute_transition_step(step: Dictionary) -> void:
	"""Exécute une transition vers une autre scène"""
	
	var target = step.get("target", "")
	var fade_duration = step.get("fade_duration", 1.0)
	
	print("[IntroDialogue] 🎞️ Transition vers : ", target)
	
	# Mapper les noms Lua vers les SceneID
	var scene_map = {
		"world_map": SceneRegistry.SceneID.WORLD_MAP,
		"battle": SceneRegistry.SceneID.BATTLE,
		"main_menu": SceneRegistry.SceneID.MAIN_MENU
	}
	
	if not scene_map.has(target):
		push_error("[IntroDialogue] Cible de transition inconnue : ", target)
		return
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await tween.finished
	
	# Changer de scène
	EventBus.change_scene(scene_map[target])

func _execute_notification_step(step: Dictionary) -> void:
	"""Affiche une notification"""
	
	var message = step.get("message", "")
	var duration = step.get("duration", 2.0)
	
	EventBus.notify(message, "info")

func _execute_unlock_location_step(step: Dictionary) -> void:
	"""Déverrouille une location sur la world map"""
	
	var location = step.get("location", "")
	
	print("[IntroDialogue] 🔓 Déverrouillage : ", location)
	
	# Envoyer l'événement
	EventBus.location_discovered.emit(location)

# ============================================================================
# HELPERS
# ============================================================================

func _convert_to_dialogue_data(lua_dict: Dictionary) -> DialogueData:
	"""Convertit un dictionnaire Lua en DialogueData"""
	
	var dialogue = DialogueData.new(lua_dict.get("id", ""))
	
	# Copier les propriétés
	dialogue.category = lua_dict.get("category", "general")
	dialogue.priority = lua_dict.get("priority", 0)
	dialogue.skippable = lua_dict.get("skippable", true)
	dialogue.pausable = lua_dict.get("pausable", true)
	
	# Traiter les séquences
	if lua_dict.has("sequences"):
		for sequence in lua_dict.sequences:
			if sequence.has("lines"):
				for line in sequence.lines:
					dialogue.add_line(
						line.get("speaker", ""),
						line.get("text", ""),
						{
							"emotion": line.get("emotion", "neutral"),
							"auto_advance": false  # Désactivé par défaut
						}
					)
	
	return dialogue

func _fallback_to_world_map() -> void:
	"""Fallback en cas d'erreur : aller directement à la world map"""
	
	print("[IntroDialogue] ⚠️ Fallback vers World Map")
	await get_tree().create_timer(1.0).timeout
	EventBus.change_scene(SceneRegistry.SceneID.WORLD_MAP)

# ============================================================================
# NETTOYAGE
# ============================================================================

func _exit_tree() -> void:
	EventBus.disconnect_all(self)