return {
    metadata = {
        id = "campaign_id",              -- OBLIGATOIRE
        name = "Nom Campagne",            -- OBLIGATOIRE
        description = "Description",      -- optionnel
        difficulty = "normal"             -- optionnel
    },
    
    start_sequence = {                    -- ⚠️ OBLIGATOIRE
        {type = "dialogue", character = "X", text = "..."},
        {type = "start_combat", combat_id = "..."}
    },
    
    combats = {
        {
            id = "combat_id",             -- OBLIGATOIRE
            
            -- Ennemis
            enemy_team = {                -- OBLIGATOIRE
                {
                    unit_id = "enemy_01",
                    type = "goblin",
                    level = 1,
                    position = {x = 5, y = 3},
                    -- Optionnels:
                    stats_override = {hp = 50, atk = 10},
                    equipment = {"sword_rusty"}
                }
            },
            
            -- Joueur
            player_team = {
                starting_positions = {{x = 1, y = 3}}  -- OBLIGATOIRE
            },
            
            -- Conditions
            victory_conditions = {        -- OBLIGATOIRE
                type = "eliminate_all"    -- ou "survive_turns", "reach_position"
            },
            
            -- Events
            on_victory = {                -- optionnel
                {type = "dialogue", character = "hero", text = "Victoire !"}
            },
            on_defeat = {                 -- optionnel
                {type = "game_over"}
            }
        }
    }
}