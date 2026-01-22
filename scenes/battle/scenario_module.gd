extends Node
## ScenarioModule - Gère les dialogues, événements scriptés, cutscenes
## VERSION CORRIGÉE : Utilise le vrai système de dialogue

class_name ScenarioModule

# ============================================================================
# SIGNAUX
# ============================================================================

signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal event_triggered(event_id: String)

# ============================================================================
# DONNÉES
# ============================================================================

var scenario_data: Dictionary = {}
var triggers: Dictionary = {}
var triggered_events: Array[String] = []

# ✅ NOUVEAU : Référence à la DialogueBox
var dialogue_box: DialogueBox = null

# ============================================================================
# SETUP
# ============================================================================

func setup_scenario(data: Dictionary) -> void:
	"""Configure le scénario"""
	
	scenario_data = data.duplicate(true)
	triggers.clear()
	triggered_events.clear()
	
	# Configurer les triggers de tour
	if data.has("turn_events"):
		for turn in data.turn_events:
			triggers["turn_" + str(turn)] = data.turn_events[turn]
	
	# Configurer les triggers de position
	if data.has("position_events"):
		for pos_key in data.position_events:
			triggers["pos_" + pos_key] = data.position_events[pos_key]
	
	print("[ScenarioModule] Scénario chargé")

# ============================================================================
# CUTSCENES
# ============================================================================

func has_intro() -> bool:
	"""Vérifie s'il y a une intro"""
	
	return scenario_data.has("intro_dialogue") or scenario_data.has("intro_cutscene")

func play_intro() -> void:
	"""Joue la cutscene d'intro"""
	
	if scenario_data.has("intro_dialogue"):
		# ✅ CORRECTION : Utiliser le vrai système de dialogue
		await _play_dialogue_real(scenario_data.intro_dialogue)
	
	await get_tree().create_timer(0.5).timeout

func has_outro() -> bool:
	"""Vérifie s'il y a une outro"""
	
	return scenario_data.has("outro_victory") or scenario_data.has("outro_defeat")

func play_outro(victory: bool) -> void:
	"""Joue la cutscene de fin"""
	
	var dialogue_key = "outro_victory" if victory else "outro_defeat"
	
	if scenario_data.has(dialogue_key):
		# ✅ CORRECTION : Utiliser le vrai système de dialogue
		await _play_dialogue_real(scenario_data[dialogue_key])
	
	await get_tree().create_timer(0.5).timeout

# ============================================================================
# SYSTÈME DE DIALOGUE RÉEL
# ============================================================================

func _play_dialogue_real(dialogue_lines: Array) -> void:
	"""✅ NOUVEAU : Joue un dialogue avec le vrai système DialogueBox"""
	
	if not dialogue_box:
		push_warning("[ScenarioModule] DialogueBox non configurée, fallback vers ancien système")
		await _play_dialogue_fallback(dialogue_lines)
		return
	
	# Créer un DialogueData à partir des lignes
	var dialogue_data = DialogueData.new("scenario_dialogue_" + str(Time.get_ticks_msec()))
	
	for line in dialogue_lines:
		var speaker = line.get("speaker", "???")
		var text = line.get("text", "")
		
		dialogue_data.add_line(speaker, text)
	
	# Démarrer le dialogue
	Dialogue_Manager.start_dialogue(dialogue_data, dialogue_box)
	
	# Attendre que le dialogue se termine
	await Dialogue_Manager.dialogue_ended

# ============================================================================
# FALLBACK (ancien système pour compatibilité)
# ============================================================================

func _play_dialogue_fallback(dialogue_lines: Array) -> void:
	"""Système de dialogue simple (fallback)"""
	
	dialogue_started.emit("dialogue")
	
	for line in dialogue_lines:
		var speaker = line.get("speaker", "???")
		var text = line.get("text", "")
		
		print("[", speaker, "] ", text)
		EventBus.notify(speaker + ": " + text, "info")
		
		await get_tree().create_timer(2.0).timeout
	
	dialogue_ended.emit("dialogue")

# ============================================================================
# TRIGGERS
# ============================================================================

func trigger_turn_event(turn: int, is_player: bool) -> void:
	"""Déclenche les événements du tour"""
	
	var trigger_id = "turn_" + str(turn)
	
	if not triggers.has(trigger_id):
		return
	
	if trigger_id in triggered_events:
		return
	
	var event_data = triggers[trigger_id]
	await _execute_event(event_data, trigger_id)
	
	triggered_events.append(trigger_id)

func trigger_position_event(unit: BattleUnit3D, pos: Vector2i) -> void:
	"""Déclenche les événements de position"""
	
	var pos_key = str(pos.x) + "," + str(pos.y)
	var trigger_id = "pos_" + pos_key
	
	if not triggers.has(trigger_id):
		return
	
	if trigger_id in triggered_events:
		return
	
	var event_data = triggers[trigger_id]
	await _execute_event(event_data, trigger_id)
	
	triggered_events.append(trigger_id)

# ============================================================================
# EXÉCUTION
# ============================================================================

func _execute_event(event_data: Dictionary, event_id: String) -> void:
	"""Exécute un événement"""
	
	event_triggered.emit(event_id)
	
	match event_data.get("type", ""):
		"dialogue":
			await _play_dialogue_text(event_data.get("text", ""))
		
		"reinforcements":
			print("[ScenarioModule] Renforts: ", event_data.get("units", []))
		
		"treasure":
			print("[ScenarioModule] Trésor trouvé: ", event_data.get("item", ""))
		
		_:
			print("[ScenarioModule] Événement inconnu: ", event_data)

func _play_dialogue_text(text: String) -> void:
	"""Joue un texte simple"""
	
	print("[Scenario] ", text)
	EventBus.notify(text, "info")
	await get_tree().create_timer(1.5).timeout
