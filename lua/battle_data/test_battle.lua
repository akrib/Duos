-- lua/battle_data/test_battle.lua

local Helpers = require("lua/lib/battle_helpers")

return {
    id = "test_battle",
    
    player_units = {
        Helpers.create_unit("Héros", 3, 7, 150, 30, 25, 4, 1, {r=0.2, g=0.3, b=0.8, a=1})
    },
    
    enemy_units = {
        Helpers.create_goblin("Gobelin 1", 15, 7),
        Helpers.create_goblin("Gobelin 2", 16, 8),
        Helpers.create_goblin("Gobelin 3", 17, 7)
    },
    
    terrain = {type = "forest"},
    objectives = {
        primary = {{type = "defeat_all_enemies", description = "Éliminez tous les ennemis"}}
    }
}