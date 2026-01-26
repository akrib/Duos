-- lua/campaign/campaign_start.lua
return {
    campaign_id = "main_campaign",
    name = "La Légende des Duos",
    
    -- État initial
    initial_state = {
        chapter = 1,
        battle_index = 0,
        battles_won = 0
    },
    
    -- ✅ AJOUT : start_sequence (obligatoire)
    start_sequence = {
        {
            type = "dialogue",
            dialogue_id = "intro_001",
            blocking = true
        },
        
        {
            type = "notification",
            message = "Bienvenue dans le monde de Tárnor !",
            duration = 3.0
        },
        
        {
            type = "unlock_location",
            location = "village_nord"
        },
        
        {
            type = "unlock_location",
            location = "chateau_royal"
        },
        
        {
            type = "transition",
            target = "world_map",
            fade_duration = 1.0
        }
    }
}