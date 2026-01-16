extends Control
## Exemple de scène utilisant l'auto-connexion de signaux via SceneLoader

@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var options_button: Button = $MarginContainer/VBoxContainer/OptionsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/QuitButton
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel

func _ready() -> void:
	# Les signaux sont auto-connectés par SceneLoader
	# Mais on peut aussi le faire manuellement si besoin
	if not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if not options_button.pressed.is_connected(_on_options_pressed):
		options_button.pressed.connect(_on_options_pressed)
	if not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Connexion à l'EventBus
	EventBus.safe_connect("game_started", _on_game_started)

## Méthode appelée par SceneLoader pour l'auto-connexion
func _get_signal_connections() -> Array:
	"""
	Retourne une liste de connexions de signaux à établir automatiquement.
	Format : [
		{
			"source": Node,          # L'objet émettant le signal
			"signal_name": String,   # Nom du signal
			"target": Node,          # L'objet recevant le signal
			"method": String         # Nom de la méthode à appeler
		}
	]
	"""
	
	# Attendre que les nœuds soient prêts
	if not is_node_ready():
		return []
	
	return [
		{
			"source": start_button,
			"signal_name": "pressed",
			"target": self,
			"method": "_on_start_pressed"
		},
		{
			"source": options_button,
			"signal_name": "pressed",
			"target": self,
			"method": "_on_options_pressed"
		},
		{
			"source": quit_button,
			"signal_name": "pressed",
			"target": self,
			"method": "_on_quit_pressed"
		},
	]

# ============================================================================
# CALLBACKS
# ============================================================================

func _on_start_pressed() -> void:
	print("[MainMenu] Démarrage du jeu")
	EventBus.notify("Démarrage de la partie...", "info")
	EventBus.game_started.emit()
	
	# Demander le chargement de la carte du monde
	EventBus.change_scene(SceneRegistry.SceneID.WORLD_MAP)

func _on_options_pressed() -> void:
	print("[MainMenu] Ouverture des options")
	EventBus.change_scene(SceneRegistry.SceneID.OPTIONS_MENU)

func _on_quit_pressed() -> void:
	print("[MainMenu] Demande de quitter le jeu")
	EventBus.quit_game_requested.emit()

func _on_game_started() -> void:
	print("[MainMenu] Le jeu a démarré (via EventBus)")

# ============================================================================
# NETTOYAGE
# ============================================================================

func _exit_tree() -> void:
	# EventBus se déconnecte automatiquement, mais on peut le faire manuellement aussi
	EventBus.disconnect_all(self)
