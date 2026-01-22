extends Resource
## DialogueData - Format de données pour les dialogues
## Peut être créé en code ou chargé depuis JSON/CSV

class_name DialogueData

# ============================================================================
# PROPRIÉTÉS
# ============================================================================

@export var dialogue_id: String = ""
@export var category: String = "general"  # combat, story, bark, etc.
@export var priority: int = 0  # Pour interruptions
@export var skippable: bool = true
@export var pausable: bool = true

# Lignes de dialogue
@export var lines: Array[Dictionary] = []

# Métadonnées
@export var metadata: Dictionary = {}

# ============================================================================
# FORMAT DES LIGNES
# ============================================================================

## Format d'une ligne de dialogue :
## {
##     "speaker": "Nom du personnage",
##     "speaker_key": "clé_i18n_nom",  # Pour i18n
##     "text": "Texte affiché",
##     "text_key": "dialogue.key.01",  # Pour i18n
##     "portrait": "res://portraits/knight.png",
##     "emotion": "happy",  # happy, sad, angry, neutral...
##     "voice_sfx": "res://sfx/voice_male.ogg",
##     "speed": 50.0,  # Override vitesse
##     "auto_advance": true,
##     "auto_delay": 2.0,
##     "effects": ["shake", "rainbow"],  # Effets BBCode
##     "choices": [],  # Si ligne avec choix
##     "event": {},  # Événement à déclencher
##     "metadata": {}
## }

# ============================================================================
# CONSTRUCTION
# ============================================================================

func _init(id: String = "") -> void:
	dialogue_id = id

## Ajouter une ligne de dialogue
func add_line(speaker: String, text: String, options: Dictionary = {}) -> DialogueData:
	var line = {
		"speaker": speaker,
		"text": text,
	}
	
	# Fusionner avec les options
	for key in options:
		line[key] = options[key]
	
	# i18n auto si non spécifié
	if not line.has("text_key"):
		line["text_key"] = _generate_text_key(speaker, text)
	
	lines.append(line)
	return self

## Ajouter une ligne avec choix
func add_choice_line(speaker: String, text: String, choices: Array, options: Dictionary = {}) -> DialogueData:
	var line = {
		"speaker": speaker,
		"text": text,
		"choices": choices
	}
	
	for key in options:
		line[key] = options[key]
	
	if not line.has("text_key"):
		line["text_key"] = _generate_text_key(speaker, text)
	
	lines.append(line)
	return self

## Ajouter un événement
func add_event(event_type: String, event_data: Dictionary = {}) -> DialogueData:
	var line = {
		"event": {
			"type": event_type
		}
	}
	
	for key in event_data:
		line.event[key] = event_data[key]
	
	lines.append(line)
	return self

# ============================================================================
# CHARGEMENT DEPUIS FICHIER
# ============================================================================

static func from_json(json_path: String) -> DialogueData:
	"""Charge un dialogue depuis un fichier JSON"""
	
	if not FileAccess.file_exists(json_path):
		push_error("[DialogueData] Fichier introuvable : " + json_path)
		return null
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("[DialogueData] Erreur de parsing JSON : " + json_path)
		return null
	
	var data = json.data
	
	var dialogue = DialogueData.new()
	dialogue.dialogue_id = data.get("dialogue_id", "")
	dialogue.category = data.get("category", "general")
	dialogue.priority = data.get("priority", 0)
	dialogue.skippable = data.get("skippable", true)
	dialogue.pausable = data.get("pausable", true)
	dialogue.lines = data.get("lines", [])
	dialogue.metadata = data.get("metadata", {})
	
	return dialogue

static func from_csv(csv_path: String, dialogue_id: String) -> DialogueData:
	"""Charge un dialogue depuis un fichier CSV"""
	
	if not FileAccess.file_exists(csv_path):
		push_error("[DialogueData] Fichier CSV introuvable : " + csv_path)
		return null
	
	var dialogue = DialogueData.new(dialogue_id)
	
	var file = FileAccess.open(csv_path, FileAccess.READ)
	var headers = file.get_csv_line()
	
	while not file.eof_reached():
		var line_data = file.get_csv_line()
		
		if line_data.size() < 2:
			continue
		
		var line = {}
		for i in range(min(headers.size(), line_data.size())):
			line[headers[i]] = line_data[i]
		
		# Parser les choix si présents
		if line.has("choices") and line.choices != "":
			line.choices = line.choices.split("|")
		
		dialogue.lines.append(line)
	
	file.close()
	return dialogue

# ============================================================================
# SAUVEGARDE
# ============================================================================

func to_json() -> String:
	"""Exporte le dialogue en JSON"""
	
	var data = {
		"dialogue_id": dialogue_id,
		"category": category,
		"priority": priority,
		"skippable": skippable,
		"pausable": pausable,
		"lines": lines,
		"metadata": metadata
	}
	
	return JSON.stringify(data, "\t")

func save_to_file(file_path: String) -> void:
	"""Sauvegarde le dialogue dans un fichier JSON"""
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(to_json())
	file.close()
	
	print("[DialogueData] Dialogue sauvegardé : ", file_path)

# ============================================================================
# HELPERS
# ============================================================================

func get_line(index: int) -> Dictionary:
	"""Retourne une ligne par index"""
	
	if index < 0 or index >= lines.size():
		return {}
	
	return lines[index]

func get_line_count() -> int:
	"""Retourne le nombre de lignes"""
	return lines.size()

func _generate_text_key(speaker: String, text: String) -> String:
	"""Génère une clé i18n automatique"""
	
	var sanitized_speaker = speaker.to_lower().replace(" ", "_")
	var hash = str(text.hash()).substr(0, 6)
	
	return "dialogue.%s.%s.%s" % [dialogue_id, sanitized_speaker, hash]

# ============================================================================
# HELPERS STATIQUES
# ============================================================================

## Créer un dialogue rapide en code
## Créer un dialogue rapide en code
static func quick_dialogue(id: String, lines_data: Array) -> DialogueData:
	"""
	Crée rapidement un dialogue depuis un array
	Format : [["Speaker", "Text"], ["Speaker2", "Text2"], ...]
	"""
	
	var dialogue = DialogueData.new(id)
	
	for line_data in lines_data:
		if line_data.size() >= 2:
			# ✅ CORRECTION: Désactiver l'auto-advance par défaut
			dialogue.add_line(line_data[0], line_data[1], {
				"auto_advance": false  # <-- IMPORTANT !
			})
	
	return dialogue

## Créer un bark (message court unique)
static func create_bark(speaker: String, text: String) -> DialogueData:
	"""Crée un dialogue bark (message court)"""
	
	var dialogue = DialogueData.new("bark_" + str(Time.get_ticks_msec()))
	dialogue.category = "bark"
	dialogue.skippable = true
	
	dialogue.add_line(speaker, text, {
		"auto_advance": true,
		"auto_delay": 1.5,
		"speed": 100.0
	})
	
	return dialogue
