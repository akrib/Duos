-- lua/world_map/world_map_data.lua
-- Configuration complète de la carte du monde

return {
    -- Métadonnées
    id = "main_world_map",
    name = "Royaume de Valoria",
    
    -- Locations (points sur la carte)
    locations = {
        {
            id = "castle",
            name = "Château Royal",
            position = {x = 960, y = 540},  -- Position sur la carte (pixels)
            unlocked_at_step = 0,  -- Disponible dès le début
            connections = {"town1", "town2", "battle_zone"},
            icon = "res://icon.svg",  -- Icône de la location
            scale = 1.5,  -- Taille de l'icône
            color = {r = 0.9, g = 0.8, b = 0.5, a = 1.0},
            data_file = "res://lua/world_map/locations/castle.lua"
        },
        {
            id = "town1",
            name = "Village du Nord",
            position = {x = 400, y = 300},
            unlocked_at_step = 0,
            connections = {"castle", "battle_zone"},
            icon = "res://icon.svg",
            scale = 1.0,
            color = {r = 0.6, g = 0.8, b = 0.6, a = 1.0},
            data_file = "res://lua/world_map/locations/town1.lua"
        },
        {
            id = "town2",
            name = "Port de l'Est",
            position = {x = 1500, y = 700},
            unlocked_at_step = 2,  -- Déverrouillé après step 2
            connections = {"castle"},
            icon = "res://icon.svg",
            scale = 1.0,
            color = {r = 0.5, g = 0.7, b = 0.9, a = 1.0},
            data_file = "res://lua/world_map/locations/town2.lua"
        },
        {
            id = "battle_zone",
            name = "Zone de Combat",
            position = {x = 700, y = 650},
            unlocked_at_step = 1,  -- Déverrouillé après step 1
            connections = {"town1", "castle"},
            icon = "res://icon.svg",
            scale = 1.2,
            color = {r = 1.0, g = 0.4, b = 0.4, a = 1.0},
            data_file = "res://lua/world_map/locations/battle_zone.lua"
        }
    },
    
    -- Configuration du joueur
    player = {
        start_location = "castle",
        icon = "res://icon.svg",
        scale = 0.8,
        bounce_speed = 1.5,  -- Vitesse de l'animation bounce
        bounce_amount = 10.0,  -- Amplitude du bounce (pixels)
        move_speed = 300.0  -- Vitesse de déplacement (pixels/sec)
    },
    
    -- Configuration visuelle des connexions
    connections_visual = {
        color = {r = 0.7, g = 0.7, b = 0.7, a = 0.6},
        color_locked = {r = 0.3, g = 0.3, b = 0.3, a = 0.3},
        width = 3.0,
        dash_length = 15.0,
        dash_gap = 10.0
    },
    
    -- Musique/ambiance de la carte
    resources = {
        music = "res://audio/music/world_map_theme.ogg",
        ambient_sfx = "res://audio/sfx/world_ambience.ogg"
    }
}