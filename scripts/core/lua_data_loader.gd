# scripts/core/lua_data_loader.gd
extends Node
class_name LuaDataLoader

## ⚙️ HELPER CENTRALISÉ POUR LE CHARGEMENT DE FICHIERS LUA
## 
## Responsabilités :
## - Charger et exécuter des fichiers .lua
## - Convertir les données Lua en types Godot
## - Cache pour éviter les rechargements
## - Gestion d'erreurs unifiée
## 
## Usage :
##   var data = LuaDataLoader.load_lua_data("res://lua/items/potions.lua")
##   var item = data.get("healing_potion")

# ============================================================================
# CACHE GLOBAL
# ============================================================================

static var _cache: Dictionary = {}
static var _lua_instances: Dictionary = {}  # Une instance LuaAPI par fichier

# ✅ NOUVEAU : Mode de validation
enum ValidationMode {
	STRICT,    # Refuse les données invalides
	PERMISSIVE # Accepte mais log les erreurs
}

static var validation_mode: ValidationMode = ValidationMode.STRICT

static var validation_modes: Dictionary = {
	"ability": ValidationMode.STRICT,
	"enemy": ValidationMode.STRICT,
	"item": ValidationMode.PERMISSIVE,  # On peut skip des items
	"dialogue": ValidationMode.PERMISSIVE,  # Mieux qu'un crash
}

static func get_validation_mode_for(type: String) -> ValidationMode:
	return validation_modes.get(type, ValidationMode.STRICT)

# ============================================================================
# CHARGEMENT PRINCIPAL
# ============================================================================

## Charge un fichier Lua et retourne ses données
## 
## @param lua_path : Chemin vers le fichier .lua
## @param use_cache : Utiliser le cache (true par défaut)
## @param convert_types : Convertir automatiquement les types Lua en Godot
## @return Dictionary contenant les données Lua, ou {} en cas d'erreur
# ✅ APRÈS
static func load_lua_data(
	lua_path: String, 
	use_cache: bool = true, 
	convert_types: bool = true,
	validate_fn: Callable = Callable()  # ✅ NOUVEAU : fonction de validation optionnelle
) -> Variant:
	"""
	Charge un fichier Lua avec validation optionnelle
	
	@param lua_path : Chemin du fichier
	@param use_cache : Utiliser le cache
	@param convert_types : Convertir les types Lua → Godot
	@param validate_fn : Fonction de validation (ex: DataValidator.validate_ability)
	"""
	
	# Cache
	if use_cache and _cache.has(lua_path):
		return _cache[lua_path]
	
	# Vérifier existence
	if not FileAccess.file_exists(lua_path):
		push_error("[LuaDataLoader] Fichier introuvable : ", lua_path)
		return {}
	
	# Exécution
	var raw_data = _execute_lua_file(lua_path)
	
	if typeof(raw_data) == TYPE_NIL:
		return {}
	
	# Conversion
	var processed_data = raw_data
	if convert_types:
		processed_data = _convert_lua_to_godot(raw_data)
	
	# ✅ NOUVEAU : Validation
	if validate_fn.is_valid():
		var validation_result = validate_fn.call(processed_data)
		
		if validation_result and validation_result.has("valid"):
			if not validation_result.valid:
				var errors = validation_result.get("errors", [])
				
				if validation_mode == ValidationMode.STRICT:
					push_error("[LuaDataLoader] ❌ Données invalides : ", lua_path)
					for error in errors:
						push_error("  - ", error)
					return {}
				else:  # PERMISSIVE
					push_warning("[LuaDataLoader] ⚠️ Données avec erreurs : ", lua_path)
					for error in errors:
						push_warning("  - ", error)
	
	# Cache
	if use_cache:
		_cache[lua_path] = processed_data
	
	return processed_data
	
## Charge plusieurs fichiers Lua d'un dossier
## 
## @param folder_path : Chemin vers le dossier contenant les .lua
## @param use_cache : Utiliser le cache
## @return Dictionary fusionné de tous les fichiers
static func load_lua_folder(folder_path: String, use_cache: bool = true) -> Dictionary:
	var merged_data: Dictionary = {}
	var files = _get_lua_files_in_folder(folder_path)
	
	for file_name in files:
		var file_path = folder_path.path_join(file_name)
		var data = load_lua_data(file_path, use_cache)
		
		if typeof(data) == TYPE_DICTIONARY:
			merged_data.merge(data)
	
	return merged_data

# ============================================================================
# EXÉCUTION LUA
# ============================================================================

## Exécute un fichier Lua et retourne le résultat
# scripts/core/lua_data_loader.gd

static func _execute_lua_file(lua_path: String) -> Variant:
	var lua = LuaAPI.new()
	_setup_lua_environment(lua)
	
	var file = FileAccess.open(lua_path, FileAccess.READ)
	if not file:
		push_error("[LuaDataLoader] Impossible d'ouvrir : ", lua_path)
		return null
	
	var lua_content = file.get_as_text()
	file.close()
	
	# ✅ DEBUG : Afficher les premières lignes
	var preview = lua_content.substr(0, 200).replace("\n", " ")
	print("[LuaDataLoader] 📄 Chargement : ", lua_path)
	print("[LuaDataLoader] 📄 Preview : ", preview, "...")
	
	# Détecter le premier `return`
	var lines = lua_content.split("\n")
	var first_code_line_index = -1
	
	for i in range(lines.size()):
		var line = lines[i].strip_edges()
		if line.is_empty() or line.begins_with("--"):
			continue
		first_code_line_index = i
		break
	
	var assignment_code: String
	
	if first_code_line_index >= 0:
		var first_code_line = lines[first_code_line_index].strip_edges()
		
		if first_code_line.begins_with("return "):
			# Wrapper dans une fonction
			assignment_code = "local __temp_func = function()\n" + lua_content + "\nend\n_RESULT = __temp_func()"
		else:
			assignment_code = "_RESULT = " + lua_content
	else:
		push_error("[LuaDataLoader] Fichier sans code : ", lua_path)
		return null
	
	# Exécuter
	var error = lua.do_string(assignment_code)
	if error is LuaError:
		push_error("[LuaDataLoader] ❌ Erreur Lua : ", error.message)
		return null
	
	# Récupérer le résultat
	var result = lua.pull_variant("_RESULT")
	
	# ✅ DEBUG : Afficher le type du résultat
	print("[LuaDataLoader] 📦 Type récupéré : ", typeof(result))
	if typeof(result) == TYPE_DICTIONARY:
		print("[LuaDataLoader] 📦 Clés : ", result.keys())
	
	# Nettoyer
	lua.do_string("_RESULT = nil")
	
	return result
	
## Configure l'environnement Lua standard
static func _setup_lua_environment(lua: LuaAPI) -> void:
	# ✅ AJOUT : Activer plus de libs pour supporter les tables complexes
	lua.bind_libraries(["base", "table", "string", "math", "coroutine"])
	
	# Exposer les types Godot utiles
	lua.push_variant("Vector2i", func(x, y): return Vector2i(x, y))
	lua.push_variant("Color", func(r, g, b, a=1.0): return Color(r, g, b, a))
	
	# ✅ AJOUT : Fonction de debug Lua
	lua.push_variant("godot_print", func(msg): print("[Lua] ", msg))

# ============================================================================
# CONVERSION DE TYPES
# ============================================================================

# scripts/core/lua_data_loader.gd

# ============================================================================
# CONVERSION DE TYPES (CORRIGÉE)
# ============================================================================

## Convertit récursivement les données Lua en types Godot
static func _convert_lua_to_godot(data: Variant) -> Variant:
	match typeof(data):
		TYPE_DICTIONARY:
			return _convert_dict(data)
		TYPE_ARRAY:
			return _convert_array(data)  # ✅ DÉJÀ EXISTANT
		_:
			return data

## Convertit un Dictionary Lua
static func _convert_dict(dict: Dictionary) -> Dictionary:
	var result = {}
	
	for key in dict:
		var value = dict[key]
		
		# ✅ CORRECTION : Convertir les valeurs récursivement (Arrays inclus)
		result[key] = _convert_lua_to_godot(value)
	
	# ✅ Conversions spéciales APRÈS avoir traité les enfants
	result = _apply_special_conversions(result)
	
	return result

## Convertit un Array Lua
static func _convert_array(arr: Array) -> Array:
	var result = []
	
	for item in arr:
		result.append(_convert_lua_to_godot(item))  # ✅ Récursion
	
	return result

## Applique des conversions spéciales (position, color, etc.)
static func _apply_special_conversions(dict: Dictionary) -> Variant:
	# Conversion automatique de {x, y} en Vector2i
	if dict.has("x") and dict.has("y") and dict.size() == 2:
		if typeof(dict.x) == TYPE_INT and typeof(dict.y) == TYPE_INT:
			return Vector2i(dict.x, dict.y)
	
	# Conversion automatique de {r, g, b, a} en Color
	if dict.has("r") and dict.has("g") and dict.has("b"):
		return Color(
			dict.get("r", 1.0),
			dict.get("g", 1.0),
			dict.get("b", 1.0),
			dict.get("a", 1.0)
		)
	
	# ✅ PAS besoin de récursion ici, elle est déjà faite dans _convert_dict
	return dict
	
# ============================================================================
# UTILITAIRES
# ============================================================================

## Liste tous les fichiers .lua dans un dossier
static func _get_lua_files_in_folder(folder_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(folder_path)
	
	if not dir:
		push_error("[LuaDataLoader] Impossible d'ouvrir : ", folder_path)
		return files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".lua"):
			files.append(file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return files

## Vide le cache
static func clear_cache() -> void:
	_cache.clear()
	print("[LuaDataLoader] Cache vidé")

## Vide le cache d'un fichier spécifique
static func clear_cache_for(lua_path: String) -> void:
	_cache.erase(lua_path)
	print("[LuaDataLoader] Cache vidé pour : ", lua_path)

## Vérifie si un fichier est en cache
static func is_cached(lua_path: String) -> bool:
	return _cache.has(lua_path)

## Retourne la taille du cache
static func get_cache_size() -> int:
	return _cache.size()

## Retourne les statistiques du cache
static func get_cache_stats() -> Dictionary:
	return {
		"files_cached": _cache.size(),
		"paths": _cache.keys()
	}
