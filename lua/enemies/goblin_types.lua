-- lua/enemies/goblin_types.lua
-- Définitions des différents types de gobelins

return {
    -- ===================
    -- GOBELINS DE BASE
    -- ===================
    
    goblin_scout = {
        id = "goblin_scout",
        name = "Éclaireur Gobelin",
        description = "Gobelin léger et rapide, excellent pour l'exploration",
        
        -- Apparence
        model = "res://assets/models/enemies/goblin_scout.glb",
        icon = "res://assets/icons/enemies/goblin_scout.png",
        scale = 0.9,
        color = {r = 0.6, g = 0.5, b = 0.3, a = 1.0},
        
        -- Statistiques de base
        stats = {
            level = 1,
            hp = 40,
            max_hp = 40,
            mana = 0,
            max_mana = 0,
            attack = 12,
            defense = 6,
            magic = 0,
            resistance = 3,
            movement = 6,
            range = 1,
            initiative = 15
        },
        
        -- Type et classe
        type = "humanoid",
        faction = "goblin",
        class = "scout",
        size = "small",
        
        -- Comportement IA
        ai_behavior = {
            aggression = 60,  -- Pourcentage (0=défensif, 100=très agressif)
            intelligence = 30,
            caution = 70,  -- Fuit si PV < 30%
            preferred_range = "melee",
            target_priority = "weakest"  -- Cible les unités les plus faibles
        },
        
        -- Capacités
        abilities = {},  -- Pas de capacités spéciales
        
        -- Résistances et faiblesses
        resistances = {
            fire = -20,  -- Faible au feu
            physical = 0
        },
        
        -- Loot
        loot_table = {
            gold = {min = 5, max = 15},
            experience = 15,
            items = {
                {id = "healing_potion_minor", chance = 10},
                {id = "goblin_dagger", chance = 5}
            }
        }
    },
    
    goblin_warrior = {
        id = "goblin_warrior",
        name = "Guerrier Gobelin",
        description = "Gobelin équipé d'une épée et d'un bouclier",
        
        model = "res://assets/models/enemies/goblin_warrior.glb",
        icon = "res://assets/icons/enemies/goblin_warrior.png",
        scale = 1.0,
        color = {r = 0.7, g = 0.2, b = 0.2, a = 1.0},
        
        stats = {
            level = 2,
            hp = 60,
            max_hp = 60,
            mana = 0,
            max_mana = 0,
            attack = 20,
            defense = 10,
            magic = 0,
            resistance = 5,
            movement = 5,
            range = 1,
            initiative = 10
        },
        
        type = "humanoid",
        faction = "goblin",
        class = "warrior",
        size = "small",
        
        ai_behavior = {
            aggression = 75,
            intelligence = 35,
            caution = 40,
            preferred_range = "melee",
            target_priority = "nearest"
        },
        
        abilities = {"shield_bash"},  -- Capacité de base
        
        resistances = {
            fire = -10,
            physical = 5
        },
        
        loot_table = {
            gold = {min = 10, max = 25},
            experience = 25,
            items = {
                {id = "healing_potion", chance = 15},
                {id = "goblin_sword", chance = 8}
            }
        }
    },
    
    goblin_archer = {
        id = "goblin_archer",
        name = "Archer Gobelin",
        description = "Gobelin armé d'un arc, préfère attaquer à distance",
        
        model = "res://assets/models/enemies/goblin_archer.glb",
        icon = "res://assets/icons/enemies/goblin_archer.png",
        scale = 0.95,
        color = {r = 0.8, g = 0.3, b = 0.2, a = 1.0},
        
        stats = {
            level = 2,
            hp = 45,
            max_hp = 45,
            mana = 10,
            max_mana = 10,
            attack = 18,
            defense = 6,
            magic = 0,
            resistance = 4,
            movement = 4,
            range = 3,
            initiative = 12
        },
        
        type = "humanoid",
        faction = "goblin",
        class = "archer",
        size = "small",
        
        ai_behavior = {
            aggression = 65,
            intelligence = 40,
            caution = 60,
            preferred_range = "ranged",
            target_priority = "low_defense",
            keep_distance = true  -- Essaie de maintenir la distance
        },
        
        abilities = {"poison_arrow"},
        
        resistances = {
            fire = -15,
            physical = 0
        },
        
        loot_table = {
            gold = {min = 8, max = 20},
            experience = 22,
            items = {
                {id = "healing_potion_minor", chance = 12},
                {id = "goblin_bow", chance = 6}
            }
        }
    },
    
    -- ===================
    -- GOBELINS SPÉCIALISÉS
    -- ===================
    
    goblin_shaman = {
        id = "goblin_shaman",
        name = "Shaman Gobelin",
        description = "Gobelin pratiquant la magie primitive, capable de soigner ses alliés",
        
        model = "res://assets/models/enemies/goblin_shaman.glb",
        icon = "res://assets/icons/enemies/goblin_shaman.png",
        scale = 1.0,
        color = {r = 0.6, g = 0.2, b = 0.6, a = 1.0},
        
        stats = {
            level = 3,
            hp = 55,
            max_hp = 55,
            mana = 40,
            max_mana = 40,
            attack = 15,
            defense = 8,
            magic = 22,
            resistance = 12,
            movement = 4,
            range = 2,
            initiative = 11
        },
        
        type = "humanoid",
        faction = "goblin",
        class = "shaman",
        size = "small",
        
        ai_behavior = {
            aggression = 40,
            intelligence = 60,
            caution = 70,
            preferred_range = "support",
            target_priority = "support_allies",  -- Priorité aux soins
            heal_threshold = 50  -- Soigne si allié < 50% PV
        },
        
        abilities = {"heal", "curse"},
        
        resistances = {
            fire = 0,
            ice = 10,
            physical = -5,
            magic = 15
        },
        
        loot_table = {
            gold = {min = 15, max = 35},
            experience = 35,
            items = {
                {id = "mana_potion", chance = 20},
                {id = "shaman_staff", chance = 10},
                {id = "mystical_herb", chance = 15}
            }
        }
    },
    
    goblin_berserker = {
        id = "goblin_berserker",
        name = "Berserker Gobelin",
        description = "Gobelin enragé qui devient plus dangereux quand il est blessé",
        
        model = "res://assets/models/enemies/goblin_berserker.glb",
        icon = "res://assets/icons/enemies/goblin_berserker.png",
        scale = 1.1,
        color = {r = 0.9, g = 0.1, b = 0.1, a = 1.0},
        
        stats = {
            level = 4,
            hp = 80,
            max_hp = 80,
            mana = 0,
            max_mana = 0,
            attack = 28,
            defense = 8,
            magic = 0,
            resistance = 6,
            movement = 5,
            range = 1,
            initiative = 13
        },
        
        type = "humanoid",
        faction = "goblin",
        class = "berserker",
        size = "small",
        
        ai_behavior = {
            aggression = 95,
            intelligence = 25,
            caution = 10,  -- Ne fuit presque jamais
            preferred_range = "melee",
            target_priority = "strongest",  -- Cible les ennemis les plus forts
            berserk_threshold = 50  -- Enrage en dessous de 50% PV
        },
        
        abilities = {"rage", "reckless_attack"},
        
        -- Capacité passive : Rage du Berserker
        passive_effects = {
            {
                type = "on_low_hp",
                threshold = 50,  -- Déclenché à 50% PV
                effect = {
                    type = "buff",
                    stat = "attack",
                    amount = 15,
                    stat2 = "movement",
                    amount2 = 2
                }
            }
        },
        
        resistances = {
            fire = -5,
            physical = 10
        },
        
        loot_table = {
            gold = {min = 20, max = 45},
            experience = 45,
            items = {
                {id = "healing_potion", chance = 18},
                {id = "berserker_axe", chance = 12},
                {id = "strength_potion", chance = 8}
            }
        }
    },
    
    -- ===================
    -- CHEFS ET BOSS
    -- ===================
    
    goblin_chieftain = {
        id = "goblin_chieftain",
        name = "Chef Gobelin",
        description = "Leader des gobelins, inspire ses troupes et combat avec férocité",
        
        model = "res://assets/models/enemies/goblin_chieftain.glb",
        icon = "res://assets/icons/enemies/goblin_chieftain.png",
        scale = 1.3,
        color = {r = 0.9, g = 0.2, b = 0.2, a = 1.0},
        
        stats = {
            level = 5,
            hp = 120,
            max_hp = 120,
            mana = 20,
            max_mana = 20,
            attack = 32,
            defense = 18,
            magic = 10,
            resistance = 12,
            movement = 5,
            range = 1,
            initiative = 14
        },
        
        type = "humanoid",
        faction = "goblin",
        class = "chieftain",
        size = "medium",
        elite = true,  -- Boss/Elite
        
        ai_behavior = {
            aggression = 80,
            intelligence = 55,
            caution = 35,
            preferred_range = "melee",
            target_priority = "player_leader",  -- Cible le héros principal
            use_tactics = true  -- Utilise des tactiques avancées
        },
        
        abilities = {"warcry", "charge", "intimidate"},
        
        -- Aura de commandement
        passive_effects = {
            {
                type = "aura",
                radius = 3,
                targets = "allies",
                effect = {
                    type = "buff",
                    stat = "attack",
                    amount = 5,
                    stat2 = "morale",
                    amount2 = 10
                }
            }
        },
        
        resistances = {
            fire = 5,
            ice = 5,
            physical = 15,
            magic = 10
        },
        
        loot_table = {
            gold = {min = 100, max = 200},
            experience = 100,
            guaranteed_items = {
                {id = "chieftain_sword", chance = 100},
                {id = "healing_potion_greater", chance = 100}
            },
            items = {
                {id = "rare_gem", chance = 30},
                {id = "ancient_coin", chance = 25}
            }
        }
    },
    
    goblin_king = {
        id = "goblin_king",
        name = "Roi des Gobelins",
        description = "Souverain légendaire des gobelins, combattant redoutable et stratège brillant",
        
        model = "res://assets/models/enemies/goblin_king.glb",
        icon = "res://assets/icons/enemies/goblin_king.png",
        scale = 1.5,
        color = {r = 1.0, g = 0.15, b = 0.15, a = 1.0},
        
        stats = {
            level = 10,
            hp = 250,
            max_hp = 250,
            mana = 80,
            max_mana = 80,
            attack = 45,
            defense = 28,
            magic = 25,
            resistance = 22,
            movement = 6,
            range = 2,
            initiative = 18
        },
        
        type = "humanoid",
        faction = "goblin",
        class = "king",
        size = "medium",
        boss = true,  -- Boss final
        
        ai_behavior = {
            aggression = 85,
            intelligence = 80,
            caution = 45,
            preferred_range = "versatile",
            target_priority = "tactical",  -- Cibles tactiques
            use_tactics = true,
            summon_reinforcements = true,  -- Peut appeler des renforts
            phase_transitions = {  -- Phases de combat
                {hp_threshold = 75, action = "summon_guards"},
                {hp_threshold = 50, action = "enrage"},
                {hp_threshold = 25, action = "desperate_assault"}
            }
        },
        
        abilities = {
            "royal_decree",  -- Buff tous les alliés
            "devastating_strike",
            "summon_minions",
            "dark_pact"  -- Sacrifice des PV pour des dégâts massifs
        },
        
        passive_effects = {
            {
                type = "aura",
                radius = 5,
                targets = "allies",
                effect = {
                    type = "buff",
                    stat = "attack",
                    amount = 10,
                    stat2 = "defense",
                    amount2 = 8
                }
            },
            {
                type = "regeneration",
                amount = 5  -- Régénère 5 PV par tour
            }
        },
        
        resistances = {
            fire = 20,
            ice = 20,
            lightning = 15,
            physical = 25,
            magic = 20,
            holy = -10  -- Faible au sacré
        },
        
        immunities = {"poison", "stun"},  -- Immunités
        
        loot_table = {
            gold = {min = 500, max = 1000},
            experience = 500,
            guaranteed_items = {
                {id = "crown_of_the_goblin_king", chance = 100},
                {id = "legendary_greatsword", chance = 100},
                {id = "elixir_of_life", chance = 100}
            },
            items = {
                {id = "divine_artifact", chance = 50},
                {id = "ancient_scroll", chance = 40}
            }
        },
        
        -- Dialogues pendant le combat
        battle_dialogue = {
            on_spawn = "Vous osez défier le Roi des Gobelins ? Vous allez le regretter !",
            on_phase_2 = "Assez de jeux ! Il est temps de montrer ma vraie puissance !",
            on_phase_3 = "Vous... vous êtes plus forts que prévu... Mais je ne tomberai pas !",
            on_defeat = "Non... comment est-ce possible... Le royaume... tombera...",
            on_kill_player = "Pathétique. Votre royaume est perdu !"
        }
    }
}
