-- lua/campaign/campaign_manager.lua
-- Gestionnaire de campagne - Gère la progression narrative et les combats

local CampaignManager = {}

-- État de la campagne
CampaignManager.state = {
    current_chapter = 1,
    current_battle = 1,
    battles_won = 0,
    total_battles = 4,
    astraeon_favor = 0,
    kharvul_favor = 0,
    party_units = {},
    unlocked_abilities = {},
    story_flags = {}
}

-- Chapitres de la campagne
CampaignManager.chapters = {
    {
        id = 1,
        name = "Les Ombres de la Forêt",
        description = "Des gobelins menacent les villages. Votre équipe doit intervenir.",
        battles = {"tutorial", "forest_ambush"}
    },
    {
        id = 2,
        name = "La Défense du Royaume",
        description = "L'ennemi se rapproche. Il faut protéger le village.",
        battles = {"village_defense"}
    },
    {
        id = 3,
        name = "Le Chef de Guerre",
        description = "Affrontement final contre le chef des gobelins.",
        battles = {"final_boss"}
    }
}

-- Récupérer le combat actuel
function CampaignManager:get_current_battle()
    local chapter = self.chapters[self.state.current_chapter]
    if not chapter then
        return nil
    end
    
    local battle_id = chapter.battles[self.state.current_battle]
    return battle_id
end

-- Progression vers le combat suivant
function CampaignManager:advance_to_next_battle()
    local chapter = self.chapters[self.state.current_chapter]
    
    self.state.current_battle = self.state.current_battle + 1
    
    -- Si tous les combats du chapitre sont terminés
    if self.state.current_battle > #chapter.battles then
        self.state.current_chapter = self.state.current_chapter + 1
        self.state.current_battle = 1
        
        -- Fin de la campagne
        if self.state.current_chapter > #self.chapters then
            return "campaign_completed"
        end
        
        return "chapter_completed"
    end
    
    return "battle_completed"
end

-- Mettre à jour la faveur divine
function CampaignManager:update_divine_favor(god, amount)
    if god == "Astraeon" then
        self.state.astraeon_favor = self.state.astraeon_favor + amount
    elseif god == "Kharvul" then
        self.state.kharvul_favor = self.state.kharvul_favor + amount
    end
end

-- Débloquer une capacité
function CampaignManager:unlock_ability(unit_name, ability_name)
    if not self.state.unlocked_abilities[unit_name] then
        self.state.unlocked_abilities[unit_name] = {}
    end
    
    table.insert(self.state.unlocked_abilities[unit_name], ability_name)
end

-- Définir un flag d'histoire
function CampaignManager:set_story_flag(flag_name, value)
    self.state.story_flags[flag_name] = value
end

-- Récupérer un flag d'histoire
function CampaignManager:get_story_flag(flag_name)
    return self.state.story_flags[flag_name] or false
end

-- Obtenir le dialogue d'introduction du chapitre
function CampaignManager:get_chapter_intro()
    local chapter = self.chapters[self.state.current_chapter]
    if not chapter then
        return nil
    end
    
    return {
        {speaker = "Narrateur", text = "Chapitre " .. chapter.id .. ": " .. chapter.name},
        {speaker = "Narrateur", text = chapter.description}
    }
end

return CampaignManager
