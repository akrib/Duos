return {
    campaign_id = "main_campaign",
    
    start_sequence = {
        {
            speaker = "Narrateur",
            text = "Texte du premier dialogue..."
        },
        {
            speaker = "Personnage",
            text = "Autre dialogue..."
        },
        {
            type = "dialogue",
            dialogue_id = "intro",  -- Référence au fichier lua/dialogues/intro.lua
            blocking = true  -- Bloque jusqu'à la fin du dialogue
        },
        {
            type = "transition",
            target = "world_map",
            fade_duration = 1.0
        },
        {
            type = "notification",
            message = "Bienvenue dans le royaume de Valoria",
            duration = 3.0
        },
        {
            type = "unlock_location",
            location = "castle"
        },
        {
            type = "unlock_location",
            location = "forest_battle"
        }
    },
    
    -- État initial de la campagne
    initial_state = {
        chapter = 1,
        battle_index = 0,
        battles_won = 0,
        locations_unlocked = {},
        flags = {}
    },
    
    -- Métadonnées
    metadata = {
        name = "La Menace de la Forêt Noire",
        description = "Le royaume est en danger...",
        difficulty = "normal"
    }
}