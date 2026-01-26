-- lua/world_map/world_map_data.lua
return {
    id = "main_world_map",
    name = "Carte du Monde - Campagne Principale",
    
    -- Configuration du joueur
    player = {
        start_location = "village_nord",
        icon = "res://icon.svg",
        scale = 1.5,
        bounce_speed = 1.5,
        bounce_amount = 10.0,
        move_speed = 300.0
    },
    
    -- Liste des locations
    locations = {
        {
            id = "village_nord",
            name = "Village du Nord",
            position = {x = 400, y = 300},
            icon = "res://icon.svg",
            scale = 2.0,
            color = {r = 0.8, g = 0.8, b = 1.0, a = 1.0},
            unlocked_at_step = 0,  -- Déverrouillé dès le début
            connections = {"chateau_royal"}
        },
        
        {
            id = "chateau_royal",
            name = "Château Royal",
            position = {x = 960, y = 540},
            icon = "res://icon.svg",
            scale = 3.0,
            color = {r = 0.9, g = 0.8, b = 0.5, a = 1.0},
            unlocked_at_step = 0,
            connections = {"village_nord", "port_est", "zone_combat"}
        },
        
        {
            id = "port_est",
            name = "Port de l'Est",
            position = {x = 1500, y = 700},
            icon = "res://icon.svg",
            scale = 2.0,
            color = {r = 0.5, g = 0.7, b = 1.0, a = 1.0},
            unlocked_at_step = 1,  -- Déverrouillé après le premier combat
            connections = {"chateau_royal"}
        },
        
        {
            id = "zone_combat",
            name = "Zone de Combat",
            position = {x = 700, y = 650},
            icon = "res://icon.svg",
            scale = 2.5,
            color = {r = 1.0, g = 0.3, b = 0.3, a = 1.0},
            unlocked_at_step = 0,
            connections = {"chateau_royal"}
        }
    },
    
    -- Configuration visuelle des connexions
    connections_visual = {
        color = {r = 0.7, g = 0.7, b = 0.7, a = 0.6},
        color_locked = {r = 0.3, g = 0.3, b = 0.3, a = 0.3},
        width = 3.0
    }
}