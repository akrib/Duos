-- lua/campaign/battles/battle_02_forest_ambush.lua
-- Embuscade dans la Forêt - Combat avec renforts et choix moraux

local scenario = {
    id = "forest_ambush",
    name = "Embuscade en Forêt",
    difficulty = "normal"
}

local reinforcements_spawned = false
local goblin_chief_speech = false

-- Dialogue d'introduction
function on_intro()
    return {
        {speaker = "Narrateur", text = "Plus profond dans la forêt..."},
        {speaker = "Sir Gaheris", text = "Attention ! Je sens une présence..."},
        {speaker = "Chef Gobelin", text = "GRAAAH ! Vous tombez dans notre piège, humains stupides !"},
        {speaker = "Elara", text = "Une embuscade ! À vos positions !"},
        {speaker = "Père Aldric", text = "Restez groupés ! Je vais vous soigner si nécessaire."},
        {speaker = "Chef Gobelin", text = "Mes guerriers vont vous déchiqueter !"}
    }
end

-- Dialogue de victoire/défaite
function on_outro(victory)
    if victory then
        -- Choix moral après la victoire
        return {
            {speaker = "Sir Gaheris", text = "Nous avons gagné. Le chef gobelin est à terre."},
            {speaker = "Chef Gobelin", text = "*tousse du sang* Par pitié... épargnez-moi... J'ai une famille..."},
            {speaker = "Elara", text = "C'est un piège ! Ne l'écoutez pas !"},
            {speaker = "Père Aldric", text = "Même nos ennemis méritent la miséricorde. Que décidez-vous ?"},
            {speaker = "Narrateur", text = "CHOIX: Épargner le chef (Astraeon +10) ou l'éliminer (Kharvûl +10)"}
        }
    else
        return {
            {speaker = "Chef Gobelin", text = "Fuyez, vermines ! Cette forêt est à nous !"},
            {speaker = "Sir Gaheris", text = "Retraite stratégique ! Nous reviendrons plus forts !"}
        }
    end
end

-- Événements par tour
function on_turn_start(turn, is_player)
    -- Tour 3: Renforts ennemis
    if turn == 3 and not is_player and not reinforcements_spawned then
        reinforcements_spawned = true
        
        return {
            type = "spawn_units",
            units = {
                {
                    name = "Gobelin Renfort",
                    position = {x = 18, y = 10},
                    stats = {hp = 60, attack = 20, defense = 10, movement = 5, range = 1},
                    color = {r = 0.7, g = 0.2, b = 0.2, a = 1.0}
                },
                {
                    name = "Gobelin Renfort",
                    position = {x = 19, y = 10},
                    stats = {hp = 60, attack = 20, defense = 10, movement = 5, range = 1},
                    color = {r = 0.7, g = 0.2, b = 0.2, a = 1.0}
                }
            },
            dialogue = {
                {speaker = "Chef Gobelin", text = "Mes renforts arrivent ! Vous êtes finis !"},
                {speaker = "Elara", text = "Encore plus d'ennemis ! Restez concentrés !"}
            }
        }
    end
    
    -- Tour 5: Le chef devient enragé
    if turn == 5 and not is_player then
        return {
            type = "apply_effect",
            target = "Chef Gobelin",
            effect = {
                name = "enraged",
                attack_modifier = 1.5,
                defense_modifier = 0.8,
                duration = 999
            },
            dialogue = {
                {speaker = "Chef Gobelin", text = "ASSEZ ! VOUS ALLEZ TOUS MOURIR !"},
                {speaker = "Père Aldric", text = "Il devient enragé ! Attention à sa force !"}
            }
        }
    end
    
    return nil
end

-- Événement quand une unité meurt
function on_unit_death(unit)
    -- Si le chef meurt
    if unit.name == "Chef Gobelin" and not unit.is_alive then
        return {
            type = "apply_effect",
            targets = "all_enemies",
            effect = {
                name = "demoralized",
                attack_modifier = 0.7,
                defense_modifier = 0.5,
                duration = 999
            },
            dialogue = {
                {speaker = "Gobelin Guerrier", text = "Le chef est tombé ! Fuyons !"},
                {speaker = "Sir Gaheris", text = "Ils sont démoralisés ! Pressez l'attaque !"}
            }
        }
    end
    
    return nil
end

-- Événement quand une unité attaque
function on_unit_attack(data)
    -- Le chef fait un discours la première fois qu'il attaque
    if data.attacker.name == "Chef Gobelin" and not goblin_chief_speech then
        goblin_chief_speech = true
        
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Chef Gobelin", text = "Je vais vous montrer la puissance des gobelins !"}
            }
        }
    end
    
    -- Coup critique
    if data.damage > 40 then
        return {
            type = "dialogue",
            dialogue = {
                {speaker = data.attacker.name, text = "Coup critique !"}
            }
        }
    end
    
    return nil
end

-- Condition de victoire personnalisée
function check_victory_condition(battle_state)
    -- Victoire si le chef gobelin est mort (peu importe les autres)
    for _, unit in ipairs(battle_state.enemy_units) do
        if unit.name == "Chef Gobelin" and unit.is_alive then
            return false
        end
    end
    
    return true
end

-- Récompenses
function on_victory_rewards()
    return {
        gold = 250,
        experience = 120,
        items = {"Potion de Soin", "Épée de Fer"},
        divine_favor = {
            {god = "Astraeon", amount = 10},
            {god = "Kharvul", amount = 5}
        }
    }
end

return scenario
