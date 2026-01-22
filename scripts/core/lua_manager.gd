# scripts/core/lua_manager.gd
extends Node

signal script_loaded(script_path: String)
signal script_error(error_message: String)

var lua: LuaAPI
var loaded_scripts: Dictionary = {}

func _ready():
    lua = LuaAPI.new()
    add_child(lua)
    
    # Exposer l'API GDScript à Lua
    _setup_lua_bindings()
    
    # Charger les bibliothèques communes
    _load_core_libraries()

func _setup_lua_bindings():
    # Exposer EventBus
    lua.push_variant("EventBus", EventBus)
    
    # Exposer les managers
    lua.push_variant("GameManager", GameManager)
    lua.push_variant("DialogueManager", Dialogue_Manager)
    
    # Fonctions helper
    lua.bind_libraries(["base", "table", "string", "math"])
    
    # Custom API
    lua.expose_constructor("Vector2", Vector2.new)
    lua.expose_constructor("Vector2i", Vector2i.new)
    lua.expose_constructor("Color", Color.new)

func load_script(path: String) -> LuaError:
    var error = lua.do_file(path)
    if error is LuaError:
        script_error.emit(error.message)
        return error
    
    loaded_scripts[path] = true
    script_loaded.emit(path)
    return null

func call_lua_function(func_name: String, args: Array = []):
    return lua.call_function(func_name, args)