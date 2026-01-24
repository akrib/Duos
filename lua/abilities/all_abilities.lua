-- lua/abilities/all_abilities.lua
-- Définitions de toutes les capacités et sorts du jeu

return {
    -- ===================
    -- CAPACITÉS DE GUERRIER
    -- ===================
    
    shield_bash = {
        id = "shield_bash",
        name = "Coup de Bouclier",
        description = "Frappe un ennemi avec votre bouclier, l'étourdissant pour 1 tour",
        icon = "res://assets/icons/abilities/shield_bash.png",
        
        type = "active",
        category = "physical",
        class = "warrior",
        
        cost = {
            mana = 0,
            action_points = 1
        },
        
        cooldown = 3,  -- Tours avant de pouvoir réutiliser
        
        targeting = {
            type = "single",
            target = "enemy",
            range = 1,
            line_of_sight = true
        },
        
        effects = {
            {
                type = "damage",
                base_damage = 15,
                scaling = {stat = "attack", ratio = 0.5},
                element = "physical"
            },
            {
                type = "apply_status",
                status = "stunned",
                duration = 1,
                chance = 100  -- Pourcentage
            }
        },
        
        animation = "shield_bash",
        sound = "res://audio/sfx/shield_bash.ogg",
        particle_effect = "res://effects/particles/shield_impact.tres"
    },
    
    defend = {
        id = "defend",
        name = "Défense",
        description = "Adopte une posture défensive, réduisant les dégâts reçus de 50%",
        icon = "res://assets/icons/abilities/defend.png",
        
        type = "active",
        category = "defensive",
        class = "warrior",
        
        cost = {
            mana = 0,
            action_points = 1
        },
        
        cooldown = 0,  -- Peut être utilisé chaque tour
        
        targeting = {
            type = "self"
        },
        
        effects = {
            {
                type = "buff",
                stat = "defense",
                amount = 999,  -- Représente une réduction de 50%
                duration = 1,
                modifier_type = "defense_stance"
            }
        },
        
        animation = "defend_stance",
        sound = "res://audio/sfx/shield_up.ogg"
    },
    
    charge = {
        id = "charge",
        name = "Charge",
        description = "Charge vers un ennemi en ligne droite, infligeant des dégâts et repoussant",
        icon = "res://assets/icons/abilities/charge.png",
        
        type = "active",
        category = "physical",
        class = "warrior",
        
        cost = {
            mana = 10,
            action_points = 1
        },
        
        cooldown = 4,
        
        targeting = {
            type = "line",
            target = "enemy",
            range = 4,
            requires_path = true
        },
        
        effects = {
            {
                type = "move_to_target",
                stop_before = 1  -- S'arrête 1 case avant la cible
            },
            {
                type = "damage",
                base_damage = 25,
                scaling = {stat = "attack", ratio = 0.8},
                element = "physical"
            },
            {
                type = "knockback",
                distance = 2,
                direction = "forward"
            }
        },
        
        animation = "charge",
        sound = "res://audio/sfx/charge.ogg",
        particle_effect = "res://effects/particles/charge_trail.tres"
    },
    
    -- ===================
    -- CAPACITÉS D'ARCHER
    -- ===================
    
    multi_shot = {
        id = "multi_shot",
        name = "Tir Multiple",
        description = "Tire 3 flèches sur des cibles différentes",
        icon = "res://assets/icons/abilities/multi_shot.png",
        
        type = "active",
        category = "physical",
        class = "archer",
        
        cost = {
            mana = 15,
            action_points = 1
        },
        
        cooldown = 3,
        
        targeting = {
            type = "multiple",
            target = "enemy",
            count = 3,
            range = 4
        },
        
        effects = {
            {
                type = "damage",
                base_damage = 12,
                scaling = {stat = "attack", ratio = 0.6},
                element = "physical",
                per_target = true
            }
        },
        
        animation = "multi_shot",
        sound = "res://audio/sfx/multi_arrow.ogg",
        particle_effect = "res://effects/particles/arrow_trail.tres"
    },
    
    snipe = {
        id = "snipe",
        name = "Tir de Précision",
        description = "Tire une flèche puissante avec +50% de chance de coup critique",
        icon = "res://assets/icons/abilities/snipe.png",
        
        type = "active",
        category = "physical",
        class = "archer",
        
        cost = {
            mana = 20,
            action_points = 1
        },
        
        cooldown = 4,
        
        targeting = {
            type = "single",
            target = "enemy",
            range = 6,
            line_of_sight = true
        },
        
        effects = {
            {
                type = "damage",
                base_damage = 35,
                scaling = {stat = "attack", ratio = 1.2},
                element = "physical",
                crit_bonus = 50  -- +50% chance de critique
            }
        },
        
        animation = "snipe",
        sound = "res://audio/sfx/arrow_critical.ogg",
        particle_effect = "res://effects/particles/snipe_flash.tres"
    },
    
    poison_arrow = {
        id = "poison_arrow",
        name = "Flèche Empoisonnée",
        description = "Tire une flèche qui empoisonne la cible pendant 3 tours",
        icon = "res://assets/icons/abilities/poison_arrow.png",
        
        type = "active",
        category = "physical",
        class = "archer",
        
        cost = {
            mana = 12,
            action_points = 1
        },
        
        cooldown = 5,
        
        targeting = {
            type = "single",
            target = "enemy",
            range = 4
        },
        
        effects = {
            {
                type = "damage",
                base_damage = 15,
                scaling = {stat = "attack", ratio = 0.5},
                element = "physical"
            },
            {
                type = "apply_status",
                status = "poison",
                damage_per_turn = 10,
                duration = 3
            }
        },
        
        animation = "poison_arrow",
        sound = "res://audio/sfx/poison_arrow.ogg",
        particle_effect = "res://effects/particles/poison_cloud.tres"
    },
    
    -- ===================
    -- CAPACITÉS DE CLERC
    -- ===================
    
    heal = {
        id = "heal",
        name = "Soin",
        description = "Restaure 40 PV à une unité alliée",
        icon = "res://assets/icons/abilities/heal.png",
        
        type = "active",
        category = "support",
        class = "cleric",
        
        cost = {
            mana = 15,
            action_points = 1
        },
        
        cooldown = 0,
        
        targeting = {
            type = "single",
            target = "ally",
            range = 3
        },
        
        effects = {
            {
                type = "heal",
                base_amount = 40,
                scaling = {stat = "magic", ratio = 0.8}
            }
        },
        
        animation = "heal",
        sound = "res://audio/sfx/heal.ogg",
        particle_effect = "res://effects/particles/heal_glow.tres"
    },
    
    divine_shield = {
        id = "divine_shield",
        name = "Bouclier Divin",
        description = "Protège une unité avec un bouclier absorbant 50 dégâts",
        icon = "res://assets/icons/abilities/divine_shield.png",
        
        type = "active",
        category = "support",
        class = "cleric",
        
        cost = {
            mana = 20,
            action_points = 1
        },
        
        cooldown = 4,
        
        targeting = {
            type = "single",
            target = "ally",
            range = 3
        },
        
        effects = {
            {
                type = "shield",
                amount = 50,
                duration = 3
            }
        },
        
        animation = "divine_shield",
        sound = "res://audio/sfx/divine_shield.ogg",
        particle_effect = "res://effects/particles/divine_glow.tres"
    },
    
    smite = {
        id = "smite",
        name = "Châtiment",
        description = "Invoque la colère divine sur un ennemi",
        icon = "res://assets/icons/abilities/smite.png",
        
        type = "active",
        category = "magic",
        class = "cleric",
        
        cost = {
            mana = 25,
            action_points = 1
        },
        
        cooldown = 3,
        
        targeting = {
            type = "single",
            target = "enemy",
            range = 4
        },
        
        effects = {
            {
                type = "damage",
                base_damage = 30,
                scaling = {stat = "magic", ratio = 1.0},
                element = "holy"
            }
        },
        
        animation = "smite",
        sound = "res://audio/sfx/holy_smite.ogg",
        particle_effect = "res://effects/particles/divine_strike.tres"
    },
    
    -- ===================
    -- SORTS DE MAGE
    -- ===================
    
    fireball = {
        id = "fireball",
        name = "Boule de Feu",
        description = "Lance une boule de feu explosive dans une zone de 2x2",
        icon = "res://assets/icons/abilities/fireball.png",
        
        type = "active",
        category = "magic",
        class = "mage",
        
        cost = {
            mana = 30,
            action_points = 1
        },
        
        cooldown = 2,
        
        targeting = {
            type = "area",
            target = "enemy",
            range = 5,
            area_size = {x = 2, y = 2},
            area_shape = "square"
        },
        
        effects = {
            {
                type = "damage",
                base_damage = 45,
                scaling = {stat = "magic", ratio = 1.2},
                element = "fire"
            },
            {
                type = "apply_status",
                status = "burning",
                damage_per_turn = 8,
                duration = 2,
                chance = 60
            }
        },
        
        animation = "fireball",
        sound = "res://audio/sfx/fireball_cast.ogg",
        particle_effect = "res://effects/particles/fireball_explosion.tres"
    },
    
    ice_spike = {
        id = "ice_spike",
        name = "Pique de Glace",
        description = "Invoque un pic de glace qui gèle l'ennemi",
        icon = "res://assets/icons/abilities/ice_spike.png",
        
        type = "active",
        category = "magic",
        class = "mage",
        
        cost = {
            mana = 25,
            action_points = 1
        },
        
        cooldown = 3,
        
        targeting = {
            type = "single",
            target = "enemy",
            range = 4
        },
        
        effects = {
            {
                type = "damage",
                base_damage = 35,
                scaling = {stat = "magic", ratio = 1.0},
                element = "ice"
            },
            {
                type = "apply_status",
                status = "frozen",
                duration = 1,
                chance = 50
            }
        },
        
        animation = "ice_spike",
        sound = "res://audio/sfx/ice_spike.ogg",
        particle_effect = "res://effects/particles/ice_shards.tres"
    },
    
    lightning_bolt = {
        id = "lightning_bolt",
        name = "Éclair",
        description = "Frappe un ennemi avec la foudre, pouvant rebondir sur 2 cibles proches",
        icon = "res://assets/icons/abilities/lightning_bolt.png",
        
        type = "active",
        category = "magic",
        class = "mage",
        
        cost = {
            mana = 35,
            action_points = 1
        },
        
        cooldown = 4,
        
        targeting = {
            type = "chain",
            target = "enemy",
            range = 5,
            max_bounces = 2,
            bounce_range = 3
        },
        
        effects = {
            {
                type = "damage",
                base_damage = 40,
                scaling = {stat = "magic", ratio = 1.1},
                element = "lightning",
                damage_reduction_per_bounce = 0.5  -- 50% de dégâts en moins par rebond
            }
        },
        
        animation = "lightning_bolt",
        sound = "res://audio/sfx/lightning.ogg",
        particle_effect = "res://effects/particles/lightning_chain.tres"
    },
    
    -- ===================
    -- CAPACITÉS PASSIVES
    -- ===================
    
    counter_attack = {
        id = "counter_attack",
        name = "Contre-Attaque",
        description = "Riposte automatiquement aux attaques en mêlée avec 50% des dégâts",
        icon = "res://assets/icons/abilities/counter_attack.png",
        
        type = "passive",
        category = "physical",
        class = "warrior",
        
        effects = {
            {
                type = "on_hit_melee",
                trigger_chance = 100,
                retaliation_damage = 0.5  -- 50% des dégâts d'attaque
            }
        }
    },
    
    evasion = {
        id = "evasion",
        name = "Évasion",
        description = "15% de chance d'esquiver complètement une attaque",
        icon = "res://assets/icons/abilities/evasion.png",
        
        type = "passive",
        category = "defensive",
        class = "archer",
        
        effects = {
            {
                type = "dodge_chance",
                amount = 15  -- Pourcentage
            }
        }
    },
    
    regeneration = {
        id = "regeneration",
        name = "Régénération",
        description = "Restaure 5 PV au début de chaque tour",
        icon = "res://assets/icons/abilities/regeneration.png",
        
        type = "passive",
        category = "support",
        class = "cleric",
        
        effects = {
            {
                type = "heal_per_turn",
                amount = 5
            }
        }
    }
}
