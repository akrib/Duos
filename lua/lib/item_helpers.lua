-- lua/lib/item_helpers.lua
-- Fonctions utilitaires pour créer des items facilement

local ItemHelpers = {}

-- Créer une potion de soin simple
function ItemHelpers.create_healing_potion(id, name, heal_amount, value, rarity)
    rarity = rarity or "common"
    
    return {
        id = id,
        name = name,
        description = "Restaure " .. heal_amount .. " PV à une unité alliée",
        icon = "res://assets/icons/items/potion_red.png",
        
        type = "consumable",
        category = "potion",
        rarity = rarity,
        
        usage = {
            target_type = "ally",
            target_count = 1,
            range = 1
        },
        
        effects = {
            {type = "heal", amount = heal_amount, stat = "hp"}
        },
        
        value = value,
        stack_size = 10,
        weight = 0.1
    }
end

-- Créer une potion de buff
function ItemHelpers.create_buff_potion(id, name, stat, amount, duration, value, color)
    color = color or "orange"
    
    return {
        id = id,
        name = name,
        description = "Augmente " .. stat .. " de " .. amount .. " pendant " .. duration .. " tours",
        icon = "res://assets/icons/items/potion_" .. color .. ".png",
        
        type = "consumable",
        category = "potion",
        rarity = "uncommon",
        
        usage = {
            target_type = "ally",
            target_count = 1,
            range = 1
        },
        
        effects = {
            {
                type = "buff",
                stat = stat,
                amount = amount,
                duration = duration
            }
        },
        
        value = value,
        stack_size = 5,
        weight = 0.2
    }
end

-- Créer une bombe
function ItemHelpers.create_bomb(id, name, damage, area_size, range, value, element)
    element = element or "fire"
    
    return {
        id = id,
        name = name,
        description = "Inflige " .. damage .. " dégâts de " .. element .. " dans une zone",
        icon = "res://assets/icons/items/bomb_" .. element .. ".png",
        
        type = "consumable",
        category = "bomb",
        rarity = "uncommon",
        
        usage = {
            target_type = "enemy",
            target_count = "area",
            range = range,
            area_effect = true,
            area_size = {x = area_size, y = area_size}
        },
        
        effects = {
            {
                type = "damage",
                element = element,
                amount = damage
            }
        },
        
        value = value,
        stack_size = 5,
        weight = 0.3
    }
end

-- Créer un équipement simple
function ItemHelpers.create_equipment(id, name, slot, stat_bonuses, value, rarity)
    rarity = rarity or "common"
    
    local description = "Équipement pour " .. slot .. " : "
    for stat, bonus in pairs(stat_bonuses) do
        description = description .. "+" .. bonus .. " " .. stat .. ", "
    end
    
    return {
        id = id,
        name = name,
        description = description,
        icon = "res://assets/icons/items/" .. slot .. "_" .. id .. ".png",
        
        type = "equipment",
        category = slot,
        rarity = rarity,
        
        stat_bonuses = stat_bonuses,
        
        value = value,
        stack_size = 1,
        weight = 1.0
    }
end

-- Valider un item
function ItemHelpers.validate_item(item)
    -- Vérifier les champs obligatoires
    local required_fields = {"id", "name", "type", "category"}
    
    for _, field in ipairs(required_fields) do
        if not item[field] then
            print("[ItemHelpers] ERREUR : Champ manquant '" .. field .. "' dans l'item")
            return false
        end
    end
    
    -- Vérifier que les valeurs sont valides
    if item.value and item.value < 0 then
        print("[ItemHelpers] ERREUR : Valeur négative dans l'item " .. item.id)
        return false
    end
    
    return true
end

-- Créer un loot drop
function ItemHelpers.create_loot_drop(item_id, min_quantity, max_quantity, drop_chance)
    max_quantity = max_quantity or min_quantity
    drop_chance = drop_chance or 100
    
    return {
        item_id = item_id,
        quantity = {min = min_quantity, max = max_quantity},
        chance = drop_chance
    }
end

return ItemHelpers
