return {
    metadata = {
        id = "chapter_1",
        name = "Chapitre 1 : Le Réveil"
    },
    
    start_sequence = {
        {type = "dialogue", character = "narrator", text = "Votre aventure commence..."},
        {type = "start_combat", combat_id = "fight_1"}
    },
    
    combats = {
        -- Combat 1 : Tutorial
        {
            id = "fight_1",
            enemy_team = {{unit_id = "slime_01", type = "slime", level = 1, position = {x = 5, y = 3}}},
            player_team = {starting_positions = {{x = 1, y = 3}}},
            victory_conditions = {type = "eliminate_all"},
            on_victory = {{type = "start_combat", combat_id = "fight_2"}}
        },
        
        -- Combat 2 : Intermédiaire
        {
            id = "fight_2",
            enemy_team = {
                {unit_id = "goblin_01", type = "goblin", level = 2, position = {x = 5, y = 2}},
                {unit_id = "goblin_02", type = "goblin", level = 2, position = {x = 5, y = 4}}
            },
            player_team = {starting_positions = {{x = 1, y = 3}}},
            victory_conditions = {type = "eliminate_all"},
            on_victory = {{type = "start_combat", combat_id = "fight_3"}}
        },
        
        -- Combat 3 : Boss
        {
            id = "fight_3",
            enemy_team = {{unit_id = "boss_orc", type = "orc_chief", level = 5, position = {x = 6, y = 3}}},
            player_team = {starting_positions = {{x = 1, y = 3}}},
            victory_conditions = {type = "eliminate_all"},
            on_victory = {{type = "dialogue", character = "hero", text = "Chapitre terminé !"}}
        }
    }
}