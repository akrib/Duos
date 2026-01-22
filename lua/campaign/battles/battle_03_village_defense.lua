-- lua/campaign/battles/battle_03_village_defense.lua
-- Défense du Village - Protéger les civils

local scenario = {
    id = "village_defense",
    name = "Défense du Village de Millhaven",
    difficulty = "hard"
}

local wave_count = 0
local civilians_saved = 3
local village_elder_alive = true

-- Dialogue d'introduction
function on_intro()
    return {
        {speaker = "Narrateur", text = "Village de Millhaven, crépuscule..."},
        {speaker = "Villageois", text = "À l'aide ! Les gobelins attaquent le village !"},
        {speaker = "Sir Gaheris", text = "Nous devons protéger les civils ! Formez un périmètre défensif !"},
        {speaker = "Elara", text = "Il y en a trop ! Ils arrivent par vagues !"},
        {speaker = "Ancien du Village", text = "S'il vous plaît, protégez les maisons ! Nous avons des enfants ici !"},
        {speaker = "Père Aldric", text = "La foi nous guidera. Nous ne les laisserons pas passer !"},
        {speaker = "Narrateur", text = "OBJECTIF: Survivre 10 tours en protégeant les civils"}
    }
end

-- Dialogue de victoire/défaite
function on_outro(victory)
    if victory then
        local civilians_text = "Tous les civils sont saufs !"
        if civilians_saved == 2 then
            civilians_text = "Deux civils ont été sauvés, mais un est tombé..."
        elseif civilians_saved == 1 then
            civilians_text = "Seul un civil a survécu... C'est une victoire amère."
        elseif civilians_saved == 0 then
            civilians_text = "Aucun civil n'a survécu... La victoire est en cendres."
        end
        
        return {
            {speaker = "Sir Gaheris", text = "Nous avons tenu ! Le village est sauvé !"},
            {speaker = "Ancien du Village", text = "Merci, héros ! Vous nous avez sauvés !"},
            {speaker = "Narrateur", text = civilians_text},
            {speaker = "Elara", text = "Ils reviendront. Nous devons trouver leur campement."},
            {speaker = "Père Aldric", text = "Astraeon vous bénisse, braves guerriers."}
        }
    else
        return {
            {speaker = "Ancien du Village", text = "Non ! Le village tombe !"},
            {speaker = "Sir Gaheris", text = "Repli ! Sauvez qui vous pouvez !"},
            {speaker = "Narrateur", text = "Le village de Millhaven est tombé. Les survivants fuient dans la nuit."}
        }
    end
end

-- Vagues d'ennemis tous les 3 tours
function on_turn_start(turn, is_player)
    -- Vagues d'ennemis
    if turn % 3 == 0 and not is_player and turn < 10 then
        wave_count = wave_count + 1
        
        local spawn_positions = {
            {x = 1, y = 7},
            {x = 2, y = 14},
            {x = 18, y = 1},
            {x = 19, y = 14}
        }
        
        local units_to_spawn = {}
        local enemy_count = math.min(wave_count + 1, 4)
        
        for i = 1, enemy_count do
            local pos = spawn_positions[i]
            table.insert(units_to_spawn, {
                name = "Gobelin Pillard",
                position = pos,
                stats = {hp = 70, attack = 25, defense = 12, movement = 6, range = 1},
                color = {r = 0.8, g = 0.3, b = 0.2, a = 1.0}
            })
        end
        
        return {
            type = "spawn_units",
            units = units_to_spawn,
            dialogue = {
                {speaker = "Elara", text = "Nouvelle vague ! Ils ne s'arrêtent jamais !"},
                {speaker = "Sir Gaheris", text = "Tenez bon ! Protégez les civils !"}
            }
        }
    end
    
    -- Tour 5: Événement spécial
    if turn == 5 and is_player then
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Ancien du Village", text = "Tenez encore un peu ! Les renforts du royaume arrivent !"},
                {speaker = "Père Aldric", text = "Courage, mes amis ! La fin est proche !"}
            }
        }
    end
    
    -- Tour 8: Boss arrive
    if turn == 8 and not is_player then
        return {
            type = "spawn_units",
            units = {
                {
                    name = "Seigneur de Guerre Gobelin",
                    position = {x = 10, y = 1},
                    stats = {hp = 150, attack = 35, defense = 25, movement = 5, range = 1},
                    color = {r = 0.9, g = 0.1, b = 0.1, a = 1.0}
                }
            },
            dialogue = {
                {speaker = "Seigneur de Guerre Gobelin", text = "GRAAAH ! Je vais détruire ce village moi-même !"},
                {speaker = "Sir Gaheris", text = "Leur chef ! C'est lui que nous devons arrêter !"}
            }
        }
    end
    
    return nil
end

-- Événement quand un civil meurt
function on_unit_death(unit)
    if unit.name == "Civil" then
        civilians_saved = civilians_saved - 1
        
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Père Aldric", text = "Non ! Nous avons perdu un innocent !"},
                {speaker = "Sir Gaheris", text = "Redoublez vos efforts ! Ne les laissez pas approcher !"}
            }
        }
    end
    
    if unit.name == "Ancien du Village" then
        village_elder_alive = false
        
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Elara", text = "L'Ancien est tombé ! C'est une catastrophe !"},
                {speaker = "Narrateur", text = "La mort de l'Ancien affectera profondément le village..."}
            }
        }
    end
    
    -- Boss tué
    if unit.name == "Seigneur de Guerre Gobelin" and not unit.is_alive then
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Sir Gaheris", text = "Le Seigneur de Guerre est tombé ! Victoire !"},
                {speaker = "Gobelin Pillard", text = "Fuite ! Le chef est mort !"}
            }
        }
    end
    
    return nil
end

-- Condition de victoire: Survivre 10 tours
function check_victory_condition(battle_state)
    if battle_state.turn >= 10 then
        return true
    end
    
    -- Victoire anticipée si tous les ennemis sont morts
    local enemies_alive = 0
    for _, unit in ipairs(battle_state.enemy_units) do
        if unit.is_alive then
            enemies_alive = enemies_alive + 1
        end
    end
    
    return enemies_alive == 0
end

-- Condition de défaite: Tous les civils morts
function check_defeat_condition(battle_state)
    if civilians_saved == 0 then
        return true
    end
    
    -- Ou tous les héros morts
    local heroes_alive = 0
    for _, unit in ipairs(battle_state.player_units) do
        if unit.is_alive then
            heroes_alive = heroes_alive + 1
        end
    end
    
    return heroes_alive == 0
end

-- Récompenses basées sur la performance
function on_victory_rewards()
    local base_gold = 300
    local bonus_gold = civilians_saved * 100
    
    local divine_favor = {}
    
    -- Bonus selon les civils sauvés
    if civilians_saved == 3 then
        table.insert(divine_favor, {god = "Astraeon", amount = 20})
    else
        table.insert(divine_favor, {god = "Kharvul", amount = 10})
    end
    
    return {
        gold = base_gold + bonus_gold,
        experience = 200,
        items = {"Armure Renforcée", "Potion Supérieure"},
        divine_favor = divine_favor,
        special = {
            civilians_saved = civilians_saved,
            village_elder_alive = village_elder_alive
        }
    }
end

return scenario
