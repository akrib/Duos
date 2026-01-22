# scripts/core/lua_manager.gd
extends Node

var lua: LuaAPI
var loaded_scripts: Dictionary = {}
var script_cache: Dictionary = {}  # ✅ Cache pour éviter de recharger

func _ready():
    lua = LuaAPI.new()
    _setup_lua_bindings()
    print("[LuaManager] Initialisé")

func _setup_lua_bindings():
    lua.push_variant("EventBus", EventBus)
    lua.push_variant("GameManager", GameManager)
    
    # ✅ Exposer Vector2i et Color pour Lua
    lua.push_variant("Vector2i", func(x, y): return Vector2i(x, y))
    lua.push_variant("Color", func(r, g, b, a=1.0): return Color(r, g, b, a))
    
    lua.bind_libraries(["base", "table", "string", "math"])

## Charge et exécute un script Lua (avec cache)
func load_script(path: String, use_cache: bool = true) -> LuaError:
    # Si déjà en cache, ne pas recharger
    if use_cache and script_cache.has(path):
        return null
    
    var error = lua.do_file(path)
    if error is LuaError:
        push_error("[LuaManager] Erreur : ", error.message)
        return error
    
    loaded_scripts[path] = true
    script_cache[path] = true
    print("[LuaManager] ✅ Script chargé : ", path)
    return null

## Charge un fichier Lua qui retourne une table
func load_data_file(path: String) -> Variant:
    # Charger le fichier
    var error = load_script(path, false)  # Ne pas utiliser le cache
    if error:
        return null
    
    # Exécuter et récupérer le résultat
    # Les fichiers de données utilisent `return { ... }`
    # Pour récupérer le résultat, on peut utiliser dostring avec le contenu
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        push_error("[LuaManager] Impossible d'ouvrir : ", path)
        return null
    
    var content = file.get_as_text()
    file.close()
    
    # Exécuter et récupérer le retour
    var result_error = lua.do_string(content)
    if result_error is LuaError:
        push_error("[LuaManager] Erreur d'exécution : ", result_error.message)
        return null
    
    # Récupérer la valeur de retour (dernière valeur sur la stack Lua)
    # Note: LuaAPI ne fournit pas directement un moyen de récupérer la valeur de retour
    # On doit créer une variable globale temporaire
    var temp_var = "__temp_return_" + str(Time.get_ticks_msec())
    lua.do_string(temp_var + " = " + content)
    
    var data = lua.pull_variant(temp_var)
    
    # Nettoyer
    lua.do_string(temp_var + " = nil")
    
    return data

func call_lua_function(func_name: String, args: Array = []):
    var result = lua.pull_variant(func_name)
    
    if result is LuaError:
        return null
    
    if result is Callable:
        return result.callv(args)
    
    return null