-- lua/campaign/battles/battle_04_final_boss.lua
-- Combat Final - Affrontement épique

local scenario = {
    id = "final_boss",
    name = "Le Roi des Gobelins",
    difficulty = "legendary"
}

local boss_phase = 1
local boss_enraged = false
local minions_summoned = false
local final_speech = false

-- Dialogue d'introduction épique
function on_intro()
    return {
        {speaker = "Narrateur", text = "Caverne du Roi Gobelin, au cœur des montagnes..."},
        {speaker = "Sir Gaheris", text = "C'est ici. Le repaire du Roi des Gobelins."},
        {speaker = "Elara", text = "Je sens une présence maléfique. Soyez sur vos gardes."},
        {speaker = "Roi Gobelin Gornak", text = "HAHAHAHA ! Vous osez défier GORNAK, Roi des Gobelins ?"},
        {speaker = "Père Aldric", text = "Au nom d'Astraeon, nous mettons fin à votre règne de terreur !"},
        {speaker = "Roi Gobelin Gornak", text = "Vous n'êtes que des INSECTES ! Je vais vous ÉCRASER !"},
        {speaker = "Sir Gaheris", text = "En formation ! C'est notre dernière bataille !"},
        {speaker = "Narrateur", text = "Le combat décisif commence..."}
    }
end

-- Dialogue de victoire/défaite épique
function on_outro(victory)
    if victory then
        return {
            {speaker = "Roi Gobelin Gornak", text = "*tombe à genoux* Non... impossible... Je suis... Gornak..."},
            {speaker = "Sir Gaheris", text = "C'est fini, Gornak. Ton règne de terreur prend fin ici."},
            {speaker = "Roi Gobelin Gornak", text = "Vous... avez gagné... mais d'autres viendront... plus puissants..."},
            {speaker = "Elara", text = "Que veux-tu dire ? Parle !"},
            {speaker = "Roi Gobelin Gornak", text = "*dernier souffle* Les ténèbres... reviennent... préparez-vous..."},
            {speaker = "Père Aldric", text = "Il est parti. Mais ses derniers mots me troublent..."},
            {speaker = "Sir Gaheris", text = "Nous avons sauvé le royaume. C'est ce qui compte pour l'instant."},
            {speaker = "Narrateur", text = "Les héros ont vaincu le Roi des Gobelins. La paix revient... pour un temps."},
            {speaker = "Narrateur", text = "FIN DU CHAPITRE 1"}
        }
    else
        return {
            {speaker = "Roi Gobelin Gornak", text = "HAHAHAHA ! Vous voyez ? Je suis INVINCIBLE !"},
            {speaker = "Sir Gaheris", text = "Retraite ! Nous... nous avons échoué..."},
            {speaker = "Roi Gobelin Gornak", text = "Fuyez, vermines ! Et dites au monde que GORNAK EST SUPRÊME !"},
            {speaker = "Narrateur", text = "La défaite est amère. Le royaume reste sous la menace..."}
        }
    end
end

-- Phases du boss
function on_unit_attack(data)
    -- Phase 2: Boss à 60% HP
    if data.target.name == "Roi Gobelin Gornak" and boss_phase == 1 then
        local hp_percent = data.target.hp / data.target.max_hp
        
        if hp_percent <= 0.6 then
            boss_phase = 2
            
            return {
                type = "apply_effect",
                target = "Roi Gobelin Gornak",
                effect = {
                    name = "battle_fury",
                    attack_modifier = 1.3,
                    speed_modifier = 1.2,
                    duration = 999
                },
                dialogue = {
                    {speaker = "Roi Gobelin Gornak", text = "GRAAAH ! Vous m'avez blessé ! Maintenant je me FÂCHE !"},
                    {speaker = "Elara", text = "Il devient plus rapide ! Attention !"}
                }
            }
        end
    end
    
    -- Phase 3: Boss à 30% HP - Enragé
    if data.target.name == "Roi Gobelin Gornak" and boss_phase == 2 and not boss_enraged then
        local hp_percent = data.target.hp / data.target.max_hp
        
        if hp_percent <= 0.3 then
            boss_phase = 3
            boss_enraged = true
            
            return {
                type = "apply_effect",
                target = "Roi Gobelin Gornak",
                effect = {
                    name = "berserker_rage",
                    attack_modifier = 1.8,
                    defense_modifier = 0.7,
                    speed_modifier = 1.5,
                    duration = 999
                },
                dialogue = {
                    {speaker = "Roi Gobelin Gornak", text = "ASSEEEEEZ ! JE VAIS TOUS VOUS DÉTRUIRE !"},
                    {speaker = "Père Aldric", text = "Il entre en rage berserk ! Sa défense baisse mais il frappe plus fort !"},
                    {speaker = "Sir Gaheris", text = "C'est notre chance ! Concentrez vos attaques !"}
                }
            }
        end
    end
    
    return nil
end

-- Événements par tour
function on_turn_start(turn, is_player)
    -- Tour 3: Invocation de sbires
    if turn == 3 and not is_player and not minions_summoned then
        minions_summoned = true
        
        return {
            type = "spawn_units",
            units = {
                {
                    name = "Garde d'Élite Gobelin",
                    position = {x = 8, y = 7},
                    stats = {hp = 100, attack = 30, defense = 20, movement = 5, range = 1},
                    color = {r = 0.6, g = 0.1, b = 0.1, a = 1.0}
                },
                {
                    name = "Garde d'Élite Gobelin",
                    position = {x = 12, y = 7},
                    stats = {hp = 100, attack = 30, defense = 20, movement = 5, range = 1},
                    color = {r = 0.6, g = 0.1, b = 0.1, a = 1.0}
                },
                {
                    name = "Shaman Gobelin",
                    position = {x = 10, y = 5},
                    stats = {hp = 80, attack = 25, defense = 15, movement = 4, range = 3},
                    abilities = {"Heal", "Curse"},
                    color = {r = 0.5, g = 0.1, b = 0.5, a = 1.0}
                }
            },
            dialogue = {
                {speaker = "Roi Gobelin Gornak", text = "MES GARDES ! TUEZ-LES TOUS !"},
                {speaker = "Elara", text = "Il appelle des renforts ! Nous devons les gérer rapidement !"}
            }
        }
    end
    
    -- Tour 6: Attaque spéciale du boss
    if turn == 6 and not is_player then
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Roi Gobelin Gornak", text = "PRENEZ ÇA ! FRAPPE DU ROI !"},
                {speaker = "Narrateur", text = "Le Roi Gobelin prépare une attaque dévastatrice !"}
            }
        }
    end
    
    -- Tour 9: Dernier avertissement
    if turn == 9 and is_player and not final_speech then
        final_speech = true
        
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Roi Gobelin Gornak", text = "Vous êtes TENACES ! Mais cela ne changera RIEN !"},
                {speaker = "Sir Gaheris", text = "Nous ne reculerons pas ! Pour le royaume !"},
                {speaker = "Elara", text = "Finissons-en !"},
                {speaker = "Père Aldric", text = "Qu'Astraeon guide nos coups !"}
            }
        }
    end
    
    return nil
end

-- Mort d'un allié du boss
function on_unit_death(unit)
    -- Shaman tué
    if unit.name == "Shaman Gobelin" and not unit.is_alive then
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Roi Gobelin Gornak", text = "Mes shamans ! NOOON !"},
                {speaker = "Elara", text = "Plus de soins pour lui ! Pressons l'attaque !"}
            }
        }
    end
    
    -- Garde d'élite tué
    if unit.name:find("Garde d'Élite") and not unit.is_alive then
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Roi Gobelin Gornak", text = "Mes gardes les plus fidèles... vous paierez pour ça !"}
            }
        }
    end
    
    -- Un héros tombe
    if unit.is_player and not unit.is_alive then
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Roi Gobelin Gornak", text = "HAHAHA ! Un de moins ! Vous êtes FAIBLES !"},
                {speaker = "Sir Gaheris", text = "Non ! Tenez bon, restez concentrés !"}
            }
        }
    end
    
    return nil
end

-- Condition de victoire: Boss mort
function check_victory_condition(battle_state)
    for _, unit in ipairs(battle_state.enemy_units) do
        if unit.name == "Roi Gobelin Gornak" and unit.is_alive then
            return false
        end
    end
    
    return true
end

-- Récompenses légendaires
function on_victory_rewards()
    return {
        gold = 1000,
        experience = 500,
        items = {
            "Épée du Roi Déchu",
            "Armure Légendaire",
            "Potion Élixir",
            "Amulette de Protection"
        },
        divine_favor = {
            {god = "Astraeon", amount = 50},
            {god = "Kharvul", amount = 30}
        },
        special = {
            title = "Tueur de Roi",
            achievement = "Vainqueur du Roi Gobelin Gornak"
        }
    }
end

return scenario
