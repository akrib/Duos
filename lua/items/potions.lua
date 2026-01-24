-- lua/items/potions.lua
-- Définitions des potions et items consommables

local ItemHelpers = require("lua/lib/item_helpers")

return {
    -- Potions de soin
    healing_potion_minor = {
        id = "healing_potion_minor",
        name = "Petite Potion de Soin",
        description = "Restaure 30 PV à une unité alliée",
        icon = "res://assets/icons/items/potion_red_small.png",
        
        type = "consumable",
        category = "potion",
        rarity = "common",
        
        usage = {
            target_type = "ally",
            target_count = 1,
            range = 1,  -- Cases de portée
            area_effect = false
        },
        
        effects = {
            {
                type = "heal",
                amount = 30,
                stat = "hp"
            }
        },
        
        value = 50,  -- Prix d'achat/vente
        stack_size = 10,
        weight = 0.1
    },
    
    healing_potion = {
        id = "healing_potion",
        name = "Potion de Soin",
        description = "Restaure 60 PV à une unité alliée",
        icon = "res://assets/icons/items/potion_red_medium.png",
        
        type = "consumable",
        category = "potion",
        rarity = "common",
        
        usage = {
            target_type = "ally",
            target_count = 1,
            range = 1
        },
        
        effects = {
            {type = "heal", amount = 60, stat = "hp"}
        },
        
        value = 100,
        stack_size = 10,
        weight = 0.2
    },
    
    healing_potion_greater = {
        id = "healing_potion_greater",
        name = "Grande Potion de Soin",
        description = "Restaure 120 PV à une unité alliée",
        icon = "res://assets/icons/items/potion_red_large.png",
        
        type = "consumable",
        category = "potion",
        rarity = "uncommon",
        
        usage = {
            target_type = "ally",
            target_count = 1,
            range = 1
        },
        
        effects = {
            {type = "heal", amount = 120, stat = "hp"}
        },
        
        value = 250,
        stack_size = 5,
        weight = 0.3
    },
    
    -- Potions de mana
    mana_potion = {
        id = "mana_potion",
        name = "Potion de Mana",
        description = "Restaure 30 PM à une unité alliée",
        icon = "res://assets/icons/items/potion_blue.png",
        
        type = "consumable",
        category = "potion",
        rarity = "common",
        
        usage = {
            target_type = "ally",
            target_count = 1,
            range = 1
        },
        
        effects = {
            {type = "restore", amount = 30, stat = "mana"}
        },
        
        value = 75,
        stack_size = 10,
        weight = 0.1
    },
    
    -- Potions de buff temporaire
    strength_potion = {
        id = "strength_potion",
        name = "Potion de Force",
        description = "Augmente l'attaque de 10 pendant 3 tours",
        icon = "res://assets/icons/items/potion_orange.png",
        
        type = "consumable",
        category = "potion",
        rarity = "uncommon",
        
        usage = {
            target_type = "ally",
            target_count = 1,
            range = 1
        },
        
        effects = {
            {
                type = "buff",
                stat = "attack",
                amount = 10,
                duration = 3  -- Tours
            }
        },
        
        value = 150,
        stack_size = 5,
        weight = 0.2
    },
    
    defense_potion = {
        id = "defense_potion",
        name = "Potion de Protection",
        description = "Augmente la défense de 10 pendant 3 tours",
        icon = "res://assets/icons/items/potion_green.png",
        
        type = "consumable",
        category = "potion",
        rarity = "uncommon",
        
        usage = {
            target_type = "ally",
            target_count = 1,
            range = 1
        },
        
        effects = {
            {
                type = "buff",
                stat = "defense",
                amount = 10,
                duration = 3
            }
        },
        
        value = 150,
        stack_size = 5,
        weight = 0.2
    },
    
    speed_potion = {
        id = "speed_potion",
        name = "Potion de Célérité",
        description = "Augmente le mouvement de 2 pendant 2 tours",
        icon = "res://assets/icons/items/potion_yellow.png",
        
        type = "consumable",
        category = "potion",
        rarity = "rare",
        
        usage = {
            target_type = "ally",
            target_count = 1,
            range = 1
        },
        
        effects = {
            {
                type = "buff",
                stat = "movement",
                amount = 2,
                duration = 2
            }
        },
        
        value = 200,
        stack_size = 3,
        weight = 0.15
    },
    
    -- Potions spéciales
    antidote = {
        id = "antidote",
        name = "Antidote",
        description = "Retire le poison d'une unité alliée",
        icon = "res://assets/icons/items/potion_purple.png",
        
        type = "consumable",
        category = "potion",
        rarity = "common",
        
        usage = {
            target_type = "ally",
            target_count = 1,
            range = 1
        },
        
        effects = {
            {
                type = "remove_status",
                status = "poison"
            }
        },
        
        value = 80,
        stack_size = 10,
        weight = 0.1
    },
    
    elixir_of_life = {
        id = "elixir_of_life",
        name = "Élixir de Vie",
        description = "Restaure complètement les PV et retire tous les effets négatifs",
        icon = "res://assets/icons/items/elixir_gold.png",
        
        type = "consumable",
        category = "elixir",
        rarity = "legendary",
        
        usage = {
            target_type = "ally",
            target_count = 1,
            range = 1
        },
        
        effects = {
            {type = "heal", amount = 9999, stat = "hp"},
            {type = "remove_all_debuffs"}
        },
        
        value = 1000,
        stack_size = 1,
        weight = 0.5
    },
    
    -- Bombes et objets offensifs
    fire_bomb = {
        id = "fire_bomb",
        name = "Bombe Incendiaire",
        description = "Inflige 40 dégâts de feu dans une zone de 2x2",
        icon = "res://assets/icons/items/bomb_fire.png",
        
        type = "consumable",
        category = "bomb",
        rarity = "uncommon",
        
        usage = {
            target_type = "enemy",
            target_count = "area",
            range = 3,
            area_effect = true,
            area_size = {x = 2, y = 2}
        },
        
        effects = {
            {
                type = "damage",
                element = "fire",
                amount = 40
            },
            {
                type = "apply_status",
                status = "burning",
                duration = 2
            }
        },
        
        value = 120,
        stack_size = 5,
        weight = 0.3
    },
    
    smoke_bomb = {
        id = "smoke_bomb",
        name = "Bombe Fumigène",
        description = "Réduit la précision de -50% dans une zone de 3x3 pendant 2 tours",
        icon = "res://assets/icons/items/bomb_smoke.png",
        
        type = "consumable",
        category = "bomb",
        rarity = "uncommon",
        
        usage = {
            target_type = "area",
            target_count = "area",
            range = 4,
            area_effect = true,
            area_size = {x = 3, y = 3}
        },
        
        effects = {
            {
                type = "apply_status",
                status = "blind",
                accuracy_penalty = -50,
                duration = 2
            }
        },
        
        value = 100,
        stack_size = 5,
        weight = 0.2
    }
}
