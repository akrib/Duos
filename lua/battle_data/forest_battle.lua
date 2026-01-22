-- lua/battle_data/forest_battle.lua
-- Données pures du combat de la forêt

return {
    id = "forest_battle",
    name = "Embuscade en Forêt",
    
    -- Configuration du terrain
    terrain = {
        type = "forest",  -- ou preset "plains", "mountain", etc.
        width = 20,
        height = 15
    },
    
    -- Unités du joueur
    player_units = {
        {
            name = "Sir Gaheris",
            position = {x = 3, y = 7},
            stats = {
                hp = 120,
                attack = 28,
                defense = 22,
                movement = 4,
                range = 1
            },
            abilities = {"Shield Bash", "Defend"},
            color = {r = 0.2, g = 0.3, b = 0.8, a = 1.0}
        },
        {
            name = "Elara l'Archère",
            position = {x = 4, y = 6},
            stats = {
                hp = 85,
                attack = 22,
                defense = 12,
                movement = 5,
                range = 3
            },
            abilities = {"Multi-Shot"},
            color = {r = 0.2, g = 0.7, b = 0.3, a = 1.0}
        },
        {
            name = "Père Aldric",
            position = {x = 2, y = 8},
            stats = {
                hp = 95,
                attack = 15,
                defense = 18,
                movement = 4,
                range = 2
            },
            abilities = {"Heal"},
            color = {r = 0.8, g = 0.8, b = 0.3, a = 1.0}
        }
    },
    
    -- Unités ennemies
    enemy_units = {
        {
            name = "Chef Gobelin",
            position = {x = 15, y = 8},
            stats = {
                hp = 90,
                attack = 25,
                defense = 15,
                movement = 5,
                range = 1
            },
            color = {r = 0.9, g = 0.2, b = 0.2, a = 1.0}
        },
        {
            name = "Gobelin Guerrier",
            position = {x = 16, y = 7},
            stats = {
                hp = 60,
                attack = 20,
                defense = 10,
                movement = 5,
                range = 1
            },
            color = {r = 0.7, g = 0.2, b = 0.2, a = 1.0}
        },
        {
            name = "Gobelin Guerrier",
            position = {x = 16, y = 9},
            stats = {
                hp = 60,
                attack = 20,
                defense = 10,
                movement = 5,
                range = 1
            },
            color = {r = 0.7, g = 0.2, b = 0.2, a = 1.0}
        },
        {
            name = "Gobelin Archer",
            position = {x = 18, y = 8},
            stats = {
                hp = 45,
                attack = 18,
                defense = 6,
                movement = 4,
                range = 3
            },
            color = {r = 0.8, g = 0.3, b = 0.2, a = 1.0}
        },
        {
            name = "Shaman Gobelin",
            position = {x = 19, y = 7},
            stats = {
                hp = 55,
                attack = 22,
                defense = 8,
                movement = 4,
                range = 2
            },
            abilities = {"Heal"},
            color = {r = 0.6, g = 0.2, b = 0.6, a = 1.0}
        }
    },
    
    -- Objectifs
    objectives = {
        primary = {
            {
                type = "defeat_all_enemies",
                description = "Éliminez tous les gobelins"
            }
        },
        secondary = {
            {
                type = "survive_turns",
                turns = 10,
                description = "Survivez sans perdre d'unité"
            }
        }
    },
    
    -- Scénario (chemin vers le script événementiel)
    scenario_script = "res://lua/campaign/battles/battle_02_forest_ambush.lua"
}