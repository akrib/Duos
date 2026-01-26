extends Node
## Logger - Système de logs avancé avec niveaux et catégories

enum LogLevel {
	DEBUG,
	INFO,
	WARNING,
	ERROR,
	CRITICAL
}

const LOG_FILE_PATH = "user://logs/game.log"
const MAX_LOG_FILE_SIZE = 10 * 1024 * 1024  # 10 MB

var current_log_level: LogLevel = LogLevel.DEBUG
var enabled_categories: Array[String] = []  # Vide = toutes
var log_to_file: bool = true
var log_to_console: bool = true

var log_file: FileAccess = null
var session_start_time: float = 0.0

func _ready() -> void:
	session_start_time = Time.get_unix_time_from_system()
	
	if log_to_file:
		_open_log_file()
	
	info("LOGGER", "=== Nouvelle session ===")
	info("LOGGER", "Godot %s" % Engine.get_version_info().string)

func _open_log_file() -> void:
	# Créer le dossier si nécessaire
	if not DirAccess.dir_exists_absolute("user://logs"):
		DirAccess.make_dir_absolute("user://logs")
	
	# Rotation des logs si trop gros
	if FileAccess.file_exists(LOG_FILE_PATH):
		var size = FileAccess.get_file_as_bytes(LOG_FILE_PATH).size()
		if size > MAX_LOG_FILE_SIZE:
			_rotate_log_file()
	
	log_file = FileAccess.open(LOG_FILE_PATH, FileAccess.READ_WRITE)
	if log_file:
		log_file.seek_end()

func _rotate_log_file() -> void:
	var backup_path = LOG_FILE_PATH.replace(".log", "_%s.log" % Time.get_datetime_string_from_system())
	DirAccess.rename_absolute(LOG_FILE_PATH, backup_path)

func log(level: LogLevel, category: String, message: String) -> void:
	if level < current_log_level:
		return
	
	if not enabled_categories.is_empty() and category not in enabled_categories:
		return
	
	var timestamp = Time.get_datetime_string_from_system()
	var level_str = LogLevel.keys()[level]
	var formatted = "[%s][%s][%s] %s" % [timestamp, level_str, category, message]
	
	if log_to_console:
		match level:
			LogLevel.DEBUG:
				print(formatted)
			LogLevel.INFO:
				print(formatted)
			LogLevel.WARNING:
				push_warning(formatted)
			LogLevel.ERROR, LogLevel.CRITICAL:
				push_error(formatted)
	
	if log_to_file and log_file:
		log_file.store_line(formatted)
		log_file.flush()

func debug(category: String, message: String) -> void:
	log(LogLevel.DEBUG, category, message)

func info(category: String, message: String) -> void:
	log(LogLevel.INFO, category, message)

func warning(category: String, message: String) -> void:
	log(LogLevel.WARNING, category, message)

func error(category: String, message: String) -> void:
	log(LogLevel.ERROR, category, message)

func critical(category: String, message: String) -> void:
	log(LogLevel.CRITICAL, category, message)

func set_log_level(level: LogLevel) -> void:
	current_log_level = level
	info("LOGGER", "Niveau de log changé : %s" % LogLevel.keys()[level])

func enable_category(category: String) -> void:
	if category not in enabled_categories:
		enabled_categories.append(category)

func disable_category(category: String) -> void:
	enabled_categories.erase(category)

func _exit_tree() -> void:
	if log_file:
		log_file.close()