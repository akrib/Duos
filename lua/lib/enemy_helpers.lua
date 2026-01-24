-- lua/lib/enemy_helpers.lua
-- Fonctions utilitaires pour créer des ennemis facilement

local EnemyHelpers = {}

-- Créer un ennemi de base
function EnemyHelpers.create_basic_enemy(id, name, level, hp, attack, defense, movement, range)
    return {
        id = id,
        name = name,
        description = "Ennemi de niveau " .. level,
        
        model = "res://assets/models/enemies/" .. id .. ".glb",
        icon = "res://assets/icons/enemies/" .. id .. ".png",
        scale = 1.0,
        color = {r = 0.7, g = 0.2, b = 0.2, a = 1.0},
        
        stats = {
            level = level,
            hp = hp,
            max_hp = hp,
            mana = 0,
            max_mana = 0,
            attack = attack,
            defense = defense,
            magic = 0,
            resistance = 5,
            movement = movement,
            range = range,
            initiative = 10
        },
        
        type = "humanoid",
        faction = "enemy",
        size = "small",
        
        ai_behavior = {
            aggression = 70,
            intelligence = 40,
            caution = 50,
            preferred_range = range > 1 and "ranged" or "melee",
            target_priority = "nearest"
        },
        
        abilities = {},
        resistances = {},
        
        loot_table = {
            gold = {min = level * 5, max = level * 15},
            experience = level * 10,
            items = {}
        }
    }
end

-- Créer un boss
function EnemyHelpers.create_boss(id, name, level, hp, attack, defense, movement, abilities)
    local boss = EnemyHelpers.create_basic_enemy(id, name, level, hp, attack, defense, movement, 1)
    
    boss.boss = true
    boss.elite = true
    boss.size = "medium"
    boss.scale = 1.5
    boss.color = {r = 1.0, g = 0.2, b = 0.2, a = 1.0}
    
    boss.stats.mana = 80
    boss.stats.max_mana = 80
    boss.stats.magic = 20
    boss.stats.resistance = 15
    
    boss.abilities = abilities or {}
    
    boss.ai_behavior = {
        aggression = 80,
        intelligence = 70,
        caution = 40,
        preferred_range = "versatile",
        target_priority = "tactical",
        use_tactics = true
    }
    
    -- Loot amélioré
    boss.loot_table = {
        gold = {min = level * 50, max = level * 100},
        experience = level * 50,
        guaranteed_items = {},
        items = {}
    }
    
    return boss
end

-- Ajouter une capacité à un ennemi
function EnemyHelpers.add_ability(enemy, ability_id)
    table.insert(enemy.abilities, ability_id)
    return enemy
end

-- Définir les résistances
function EnemyHelpers.set_resistances(enemy, resistances)
    enemy.resistances = resistances
    return enemy
end

-- Ajouter une aura passive
function EnemyHelpers.add_aura(enemy, radius, stat, amount, targets)
    targets = targets or "allies"
    
    enemy.passive_effects = enemy.passive_effects or {}
    
    table.insert(enemy.passive_effects, {
        type = "aura",
        radius = radius,
        targets = targets,
        effect = {
            type = "buff",
            stat = stat,
            amount = amount
        }
    })
    
    return enemy
end

-- Configurer l'IA
function EnemyHelpers.set_ai_behavior(enemy, aggression, intelligence, caution, target_priority)
    enemy.ai_behavior = {
        aggression = aggression or 70,
        intelligence = intelligence or 40,
        caution = caution or 50,
        preferred_range = enemy.stats.range > 1 and "ranged" or "melee",
        target_priority = target_priority or "nearest"
    }
    
    return enemy
end

-- Ajouter du loot
function EnemyHelpers.add_loot(enemy, item_id, chance)
    chance = chance or 100
    
    table.insert(enemy.loot_table.items, {
        id = item_id,
        chance = chance
    })
    
    return enemy
end

-- Créer un groupe d'ennemis
function EnemyHelpers.create_enemy_group(base_enemy_id, count, positions, variations)
    variations = variations or {}
    
    local group = {}
    
    for i = 1, count do
        local enemy = {
            base_id = base_enemy_id,
            position = positions[i] or {x = 10 + i, y = 10},
            
            -- Variations optionnelles
            stat_multipliers = variations.stat_multipliers or {hp = 1.0, attack = 1.0, defense = 1.0},
            level_offset = variations.level_offset or 0,
            custom_name = variations.names and variations.names[i] or nil
        }
        
        table.insert(group, enemy)
    end
    
    return group
end

-- Créer des phases de boss
function EnemyHelpers.add_boss_phases(boss, phases)
    boss.ai_behavior.phase_transitions = phases
    return boss
end

-- Exemple de phases
function EnemyHelpers.create_phase(hp_threshold, action, params)
    return {
        hp_threshold = hp_threshold,
        action = action,
        params = params or {}
    }
end

-- Valider un ennemi
function EnemyHelpers.validate_enemy(enemy)
    local required_fields = {"id", "name", "stats", "type", "faction"}
    
    for _, field in ipairs(required_fields) do
        if not enemy[field] then
            print("[EnemyHelpers] ERREUR : Champ manquant '" .. field .. "' dans l'ennemi")
            return false
        end
    end
    
    -- Vérifier que les stats sont valides
    local required_stats = {"hp", "max_hp", "attack", "defense", "movement", "range"}
    for _, stat in ipairs(required_stats) do
        if not enemy.stats[stat] then
            print("[EnemyHelpers] ERREUR : Stat manquante '" .. stat .. "' dans l'ennemi " .. enemy.id)
            return false
        end
    end
    
    return true
end

-- Appliquer un template d'ennemi
function EnemyHelpers.apply_template(base_enemy, template_name)
    local templates = {
        elite = {
            stat_multipliers = {hp = 1.5, attack = 1.3, defense = 1.3},
            loot_multiplier = 2.0,
            color_tint = {r = 0.2, g = 0.0, b = 0.0, a = 0.0}  -- Rougit légèrement
        },
        veteran = {
            stat_multipliers = {hp = 1.2, attack = 1.2, defense = 1.2},
            level_bonus = 2,
            abilities_bonus = {"veteran_instincts"}
        },
        weakened = {
            stat_multipliers = {hp = 0.7, attack = 0.8, defense = 0.8},
            loot_multiplier = 0.5
        }
    }
    
    local template = templates[template_name]
    if not template then
        print("[EnemyHelpers] Template inconnu : " .. template_name)
        return base_enemy
    end
    
    -- Appliquer les multiplicateurs de stats
    if template.stat_multipliers then
        for stat, mult in pairs(template.stat_multipliers) do
            if base_enemy.stats[stat] then
                base_enemy.stats[stat] = math.floor(base_enemy.stats[stat] * mult)
            end
        end
    end
    
    -- Appliquer le bonus de niveau
    if template.level_bonus then
        base_enemy.stats.level = base_enemy.stats.level + template.level_bonus
    end
    
    -- Ajouter des capacités bonus
    if template.abilities_bonus then
        for _, ability in ipairs(template.abilities_bonus) do
            table.insert(base_enemy.abilities, ability)
        end
    end
    
    -- Modifier le loot
    if template.loot_multiplier then
        base_enemy.loot_table.gold.min = math.floor(base_enemy.loot_table.gold.min * template.loot_multiplier)
        base_enemy.loot_table.gold.max = math.floor(base_enemy.loot_table.gold.max * template.loot_multiplier)
        base_enemy.loot_table.experience = math.floor(base_enemy.loot_table.experience * template.loot_multiplier)
    end
    
    -- Modifier la couleur
    if template.color_tint then
        base_enemy.color.r = math.min(1.0, base_enemy.color.r + template.color_tint.r)
        base_enemy.color.g = math.min(1.0, base_enemy.color.g + template.color_tint.g)
        base_enemy.color.b = math.min(1.0, base_enemy.color.b + template.color_tint.b)
    end
    
    return base_enemy
end

return EnemyHelpers
