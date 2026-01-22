-- lua/scenarios/forest_ambush.lua

-- Données du scénario
local scenario = {
    id = "forest_ambush",
    name = "Embuscade en Forêt"
}

-- Dialogue d'introduction
function on_intro()
    return {
        {speaker = "Sir Gaheris", text = "dialogue.forest.intro.001"},
        {speaker = "Elara", text = "dialogue.forest.intro.002"},
        {speaker = "Père Aldric", text = "dialogue.forest.intro.003"}
    }
end

-- Dialogue de victoire
function on_outro(victory)
    if victory then
        return {
            {speaker = "Sir Gaheris", text = "dialogue.forest.victory.001"},
            {speaker = "Elara", text = "dialogue.forest.victory.002"}
        }
    else
        return {
            {speaker = "Sir Gaheris", text = "dialogue.forest.defeat.001"}
        }
    end
end

-- Événement au tour 3: renforts ennemis
function on_turn_start(turn, is_player)
    if turn == 3 and not is_player then
        return {
            type = "spawn_units",
            units = {
                {
                    name = "Gobelin Renfort",
                    position = {x = 18, y = 10},
                    stats = {hp = 60, attack = 20, defense = 10}
                },
                {
                    name = "Gobelin Renfort",
                    position = {x = 19, y = 10},
                    stats = {hp = 60, attack = 20, defense = 10}
                }
            }
        }
    end
    
    return nil
end

-- Événement quand une unité meurt
function on_unit_death(unit)
    if unit.name == "Chef Gobelin" then
        EventBus:notify("Le chef gobelin est tombé ! Les autres fuient !", "info")
        
        -- Tous les gobelins ont -50% défense
        return {
            type = "apply_effect",
            targets = "all_enemies",
            effect = {
                name = "demoralized",
                defense_modifier = -0.5,
                duration = 999
            }
        }
    end
    
    return nil
end

-- Condition de victoire custom
function check_victory_condition(battle_state)
    -- Victoire si le chef gobelin est mort (peu importe les autres)
    for _, unit in ipairs(battle_state.enemy_units) do
        if unit.name == "Chef Gobelin" and unit.is_alive then
            return false
        end
    end
    
    return true
end

-- Condition de défaite custom
function check_defeat_condition(battle_state)
    -- Défaite si Sir Gaheris meurt
    for _, unit in ipairs(battle_state.player_units) do
        if unit.name == "Sir Gaheris" and not unit.is_alive then
            return true
        end
    end
    
    return false
end

return scenario