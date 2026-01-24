-- lua/lib/ability_helpers.lua
-- Fonctions utilitaires pour créer des capacités facilement

local AbilityHelpers = {}

-- Créer une attaque physique simple
function AbilityHelpers.create_physical_attack(id, name, damage, range, cooldown, mana_cost)
    mana_cost = mana_cost or 0
    
    return {
        id = id,
        name = name,
        description = "Inflige " .. damage .. " dégâts physiques",
        icon = "res://assets/icons/abilities/" .. id .. ".png",
        
        type = "active",
        category = "physical",
        
        cost = {
            mana = mana_cost,
            action_points = 1
        },
        
        cooldown = cooldown,
        
        targeting = {
            type = "single",
            target = "enemy",
            range = range
        },
        
        effects = {
            {
                type = "damage",
                base_damage = damage,
                element = "physical"
            }
        },
        
        animation = id,
        sound = "res://audio/sfx/" .. id .. ".ogg"
    }
end

-- Créer un sort de magie élémentaire
function AbilityHelpers.create_elemental_spell(id, name, element, damage, range, cooldown, mana_cost, area_size)
    local targeting_type = area_size and "area" or "single"
    
    local ability = {
        id = id,
        name = name,
        description = "Sort de " .. element .. " infligeant " .. damage .. " dégâts",
        icon = "res://assets/icons/abilities/" .. id .. ".png",
        
        type = "active",
        category = "magic",
        
        cost = {
            mana = mana_cost,
            action_points = 1
        },
        
        cooldown = cooldown,
        
        targeting = {
            type = targeting_type,
            target = "enemy",
            range = range
        },
        
        effects = {
            {
                type = "damage",
                base_damage = damage,
                element = element
            }
        },
        
        animation = id,
        sound = "res://audio/sfx/" .. id .. ".ogg",
        particle_effect = "res://effects/particles/" .. element .. "_impact.tres"
    }
    
    -- Ajouter la taille de zone si applicable
    if area_size then
        ability.targeting.area_size = {x = area_size, y = area_size}
        ability.targeting.area_shape = "square"
    end
    
    return ability
end

-- Créer un sort de soin
function AbilityHelpers.create_heal_ability(id, name, heal_amount, range, cooldown, mana_cost)
    return {
        id = id,
        name = name,
        description = "Restaure " .. heal_amount .. " PV",
        icon = "res://assets/icons/abilities/" .. id .. ".png",
        
        type = "active",
        category = "support",
        
        cost = {
            mana = mana_cost,
            action_points = 1
        },
        
        cooldown = cooldown,
        
        targeting = {
            type = "single",
            target = "ally",
            range = range
        },
        
        effects = {
            {
                type = "heal",
                base_amount = heal_amount
            }
        },
        
        animation = "heal",
        sound = "res://audio/sfx/heal.ogg",
        particle_effect = "res://effects/particles/heal_glow.tres"
    }
end

-- Créer un buff
function AbilityHelpers.create_buff_ability(id, name, stat, amount, duration, range, mana_cost)
    return {
        id = id,
        name = name,
        description = "Augmente " .. stat .. " de " .. amount .. " pendant " .. duration .. " tours",
        icon = "res://assets/icons/abilities/" .. id .. ".png",
        
        type = "active",
        category = "support",
        
        cost = {
            mana = mana_cost,
            action_points = 1
        },
        
        cooldown = 0,
        
        targeting = {
            type = "single",
            target = "ally",
            range = range
        },
        
        effects = {
            {
                type = "buff",
                stat = stat,
                amount = amount,
                duration = duration
            }
        },
        
        animation = "buff",
        sound = "res://audio/sfx/buff.ogg"
    }
end

-- Créer une capacité passive
function AbilityHelpers.create_passive(id, name, effect_type, value)
    return {
        id = id,
        name = name,
        description = "Capacité passive : " .. effect_type,
        icon = "res://assets/icons/abilities/" .. id .. ".png",
        
        type = "passive",
        category = "passive",
        
        effects = {
            {
                type = effect_type,
                amount = value
            }
        }
    }
end

-- Ajouter un effet de statut à une capacité
function AbilityHelpers.add_status_effect(ability, status, duration, chance)
    chance = chance or 100
    
    table.insert(ability.effects, {
        type = "apply_status",
        status = status,
        duration = duration,
        chance = chance
    })
    
    return ability
end

-- Valider une capacité
function AbilityHelpers.validate_ability(ability)
    local required_fields = {"id", "name", "type", "category"}
    
    for _, field in ipairs(required_fields) do
        if not ability[field] then
            print("[AbilityHelpers] ERREUR : Champ manquant '" .. field .. "' dans l'abilité")
            return false
        end
    end
    
    -- Vérifier la structure des coûts pour les capacités actives
    if ability.type == "active" then
        if not ability.cost or not ability.cost.action_points then
            print("[AbilityHelpers] ERREUR : Coût manquant pour l'abilité active " .. ability.id)
            return false
        end
    end
    
    return true
end

return AbilityHelpers
