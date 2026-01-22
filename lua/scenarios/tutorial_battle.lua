-- lua/scenarios/tutorial_battle.lua

local BattleHelpers = require("lua/lib/battle_helpers")
local DialogueBuilder = require("lua/lib/dialogue_builder")

local scenario = {
    id = "tutorial_battle"
}

-- État persistant du scénario
local tutorial_state = {
    movement_explained = false,
    attack_explained = false,
    duo_explained = false
}

function on_intro()
    return DialogueBuilder.create()
        :add_line("Tutoriel", "Bienvenue dans votre premier combat !")
        :add_line("Tutoriel", "Commençons par les bases...")
        :build()
end

function on_unit_select(unit)
    if not tutorial_state.movement_explained and unit.is_player then
        tutorial_state.movement_explained = true
        
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Tutoriel", text = "Cliquez sur 'Déplacer' pour voir les cases accessibles."}
            }
        }
    end
    
    return nil
end

function on_unit_move(unit, from_pos, to_pos)
    if not tutorial_state.attack_explained then
        tutorial_state.attack_explained = true
        
        return {
            type = "dialogue",
            dialogue = {
                {speaker = "Tutoriel", text = "Excellent ! Maintenant, sélectionnez un ennemi pour attaquer."}
            }
        }
    end
    
    return nil
end

-- Calcul de dégâts personnalisé (première attaque fait toujours 1 dégât)
function calculate_damage(attacker, target, base_damage)
    if not tutorial_state.first_attack_done then
        tutorial_state.first_attack_done = true
        return 1  -- Dégâts réduits pour le tutoriel
    end
    
    return base_damage
end

return scenario