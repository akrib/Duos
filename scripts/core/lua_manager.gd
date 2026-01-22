# scripts/core/lua_manager.gd
extends Node

signal script_loaded(script_path: String)
signal script_error(error_message: String)

var lua: LuaAPI
var loaded_scripts: Dictionary = {}

func _ready():
	lua = LuaAPI.new()
	
	# Exposer l'API GDScript à Lua
	_setup_lua_bindings()
	
	print("[LuaManager] Initialisé")

func _setup_lua_bindings():
	# Exposer EventBus
	lua.push_variant("EventBus", EventBus)
	
	# Exposer les managers
	lua.push_variant("GameManager", GameManager)
	lua.push_variant("DialogueManager", Dialogue_Manager)
	
	# Fonctions helper
	lua.bind_libraries(["base", "table", "string", "math"])
	
	# Exposer des constructeurs via des fonctions callable
	lua.push_variant("Vector2", func(x, y): return Vector2(x, y))
	lua.push_variant("Vector2i", func(x, y): return Vector2i(x, y))
	lua.push_variant("Color", func(r, g, b, a = 1.0): return Color(r, g, b, a))
	
	print("[LuaManager] Bindings configurés")

func load_script(path: String) -> LuaError:
	var error = lua.do_file(path)
	if error is LuaError:
		script_error.emit(error.message)
		push_error("[LuaManager] Erreur de chargement: ", error.message)
		return error
	
	loaded_scripts[path] = true
	script_loaded.emit(path)
	print("[LuaManager] Script chargé: ", path)
	return null

func call_lua_function(func_name: String, args: Array = []):
	var result = lua.pull_variant(func_name)
	
	if result is LuaError:
		push_error("[LuaManager] Fonction Lua introuvable: ", func_name)
		return null
	
	if result is Callable:
		return result.callv(args)
	
	return null

func function_exists(func_name: String) -> bool:
	var result = lua.pull_variant(func_name)
	return result is Callable
