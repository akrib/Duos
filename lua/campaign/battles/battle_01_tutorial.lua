-- lua/campaign/battles/battle_01_tutorial.lua
-- Combat Tutoriel - Introduction aux mécaniques

local scenario = {
    id = "tutorial",
    name = "Première Escarmouche",
    difficulty = "easy"
}

-- Dialogue d'introduction
function on_intro()
    return {
        {speaker = "Narrateur", text = "Forêt de Thornwood, à l'aube..."},
        {speaker = "Sir Gaheris", text = "Nous avons repéré des gobelins près du village. Il faut agir vite."},
        {speaker = "Elara", text = "Je les vois. Trois d'entre eux seulement. Ce devrait être facile."},
        {speaker = "Père Aldric", text = "Ne les sous-estimez pas. Restez prudents."},
        {speaker = "Narrateur", text = "TUTORIEL: Cliquez sur vos unités pour les déplacer et attaquer."}
    }
end

-- Dialogue de victoire
function on_outro(victory)
    if victory then
        return {
            {speaker = "Sir Gaheris", text = "Victoire ! Bien joué, équipe."},
            {speaker = "Elara", text = "Trop facile. J'espère que le prochain défi sera plus intéressant."},
            {speaker = "Père Aldric", text = "Ne vous réjouissez pas trop vite. Ce n'était qu'une patrouille."},
            {speaker = "Narrateur", text = "Les héros ont remporté leur premier combat. Mais ce n'est que le début..."}
        }
    else
        return {
            {speaker = "Sir Gaheris", text = "Retraite ! Nous devons nous replier !"},
            {speaker = "Narrateur", text = "La défaite est amère, mais vous pouvez réessayer."}
        }
    end
end

-- Événement du premier tour
function on_turn_start(turn, is_player)
    if turn == 1 and is_player then
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Narrateur", text = "ASTUCE: Utilisez le terrain à votre avantage. Les forêts offrent de la défense."}
            }
        }
    end
    
    return nil
end

-- Événement quand une unité attaque
function on_unit_attack(data)
    -- Première attaque du joueur
    if data.attacker.is_player and not EventBus.get_story_flag("first_attack_done") then
        EventBus.set_story_flag("first_attack_done", true)
        
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Narrateur", text = "Excellent ! Continuez à attaquer les ennemis pour remporter la victoire."}
            }
        }
    end
    
    return nil
end

-- Événement quand une unité meurt
function on_unit_death(unit)
    if unit.name == "Gobelin Scout" and unit.is_alive == false then
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Elara", text = "Un de moins !"}
            }
        }
    end
    
    return nil
end

-- Récompenses de victoire
function on_victory_rewards()
    return {
        gold = 100,
        experience = 50,
        divine_favor = {
            {god = "Astraeon", amount = 5}
        }
    }
end

return scenario
