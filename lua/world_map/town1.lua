-- lua/world_map/locations/town1.lua
-- Actions et interactions disponibles au Village du Nord

return {
    id = "town1",
    name = "Village du Nord",
    description = "Un paisible village de pêcheurs et fermiers.",
    
    -- Actions disponibles dans le menu principal
    actions = {
        {
            id = "explore",
            label = "🏘️ Explorer le village",
            description = "Se promener librement dans le village",
            type = "exploration",
            icon = "res://icon.svg",
            -- Action custom via EventBus
            event = {
                type = "explore_location",
                location_id = "town1"
            }
        },
        {
            id = "tavern",
            label = "🍺 Taverne 'Le Repos du Voyageur'",
            description = "Boire un verre et écouter les rumeurs",
            type = "building",
            scene = "res://scenes/world/tavern.tscn"
        },
        {
            id = "shop_general",
            label = "🛒 Épicerie Générale",
            description = "Acheter des provisions",
            type = "shop",
            shop_id = "town1_general_store"
        },
        {
            id = "blacksmith",
            label = "⚒️ Forge",
            description = "Réparer ou améliorer son équipement",
            type = "shop",
            shop_id = "town1_blacksmith"
        },
        {
            id = "quest_board",
            label = "📜 Panneau des Quêtes",
            description = "Consulter les missions disponibles",
            type = "quest_board",
            unlocked_at_step = 1  -- Déverrouillé plus tard
        }
    },
    
    -- Personnages rencontrables (pour dialogues dynamiques)
    npcs = {
        {
            id = "mayor",
            name = "Le Maire Aldwin",
            portrait = "res://assets/portraits/mayor.png",
            
            -- Où le trouver (plusieurs lieux possibles)
            locations = {
                {
                    place_id = "town_hall",
                    place_name = "Mairie",
                    chance = 85,  -- 85% de chance d'être ici
                    time_of_day = {"morning", "afternoon"}  -- Plages horaires (optionnel)
                },
                {
                    place_id = "tavern",
                    place_name = "Taverne",
                    chance = 10,
                    time_of_day = {"evening"}
                },
                {
                    place_id = "town_square",
                    place_name = "Place du Village",
                    chance = 5,
                    time_of_day = {"afternoon"}
                }
            },
            
            -- Dialogue associé
            dialogue_file = "res://lua/dialogues/mayor_town1.lua",
            
            -- Conditions d'apparition
            appears_after_step = 0,
            disappears_after_step = -1  -- -1 = toujours présent
        },
        {
            id = "blacksmith_npc",
            name = "Forgeronne Greta",
            portrait = "res://assets/portraits/blacksmith.png",
            
            locations = {
                {
                    place_id = "blacksmith",
                    place_name = "Forge",
                    chance = 95
                },
                {
                    place_id = "tavern",
                    place_name = "Taverne",
                    chance = 5,
                    time_of_day = {"evening"}
                }
            },
            
            dialogue_file = "res://lua/dialogues/blacksmith_town1.lua",
            appears_after_step = 0
        },
        {
            id = "mysterious_traveler",
            name = "Voyageur Mystérieux",
            portrait = "res://assets/portraits/traveler.png",
            
            locations = {
                {
                    place_id = "tavern",
                    place_name = "Taverne",
                    chance = 30  -- Apparaît rarement
                }
            },
            
            dialogue_file = "res://lua/dialogues/traveler.lua",
            appears_after_step = 3  -- N'apparaît qu'après progression
        }
    },
    
    -- Lieux visitables (accès direct)
    places = {
        {
            id = "town_hall",
            name = "Mairie",
            description = "Bâtiment administratif du village",
            type = "building",
            icon = "res://assets/icons/town_hall.png",
            scene = "res://scenes/world/town_hall.tscn",
            unlocked_at_step = 0
        },
        {
            id = "town_square",
            name = "Place du Village",
            description = "Cœur animé du village",
            type = "area",
            scene = "res://scenes/world/town_square.tscn",
            unlocked_at_step = 0
        }
    },
    
    -- Ressources visuelles/audio spécifiques
    resources = {
        background_image = "res://assets/backgrounds/town1.png",
        ambient_music = "res://audio/music/peaceful_village.ogg",
        ambient_sfx = "res://audio/sfx/village_sounds.ogg",
        
        -- Images pour le menu (optionnel)
        menu_background = "res://assets/ui/town1_menu_bg.png"
    },
    
    -- Informations de quêtes (optionnel)
    quests = {
        available_here = {"quest_wolves", "quest_delivery"},
        completed_here = {"quest_intro"}
    }
}