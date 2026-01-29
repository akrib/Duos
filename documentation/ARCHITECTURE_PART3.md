# ARCHITECTURE_PART3.md - Formats de Données & Systèmes Finaux

**Tactical RPG Duos - Godot 4.5**  
**Date:** 2026-01-29  
**Partie:** 3/3 (Formats JSON, Items, Localisation, Schémas Finaux)

---

## TABLE DES MATIÈRES

1. [Vue d'ensemble](#vue-densemble)
2. [Système d'Items & Inventaire](#système-ditems--inventaire)
3. [Système d'Abilities](#système-dabilities)
4. [Système d'Ennemis](#système-dennemis)
5. [Formats de Données de Combat](#formats-de-données-de-combat)
6. [Système de Campaign](#système-de-campaign)
7. [Système de Locations & Maps](#système-de-locations--maps)
8. [Système de Mana & Effets](#système-de-mana--effets)
9. [Système de Localisation](#système-de-localisation)
10. [Schémas de Validation](#schémas-de-validation)
11. [Checklist d'Intégration](#checklist-dintégration)
12. [Index Global des Systèmes](#index-global-des-systèmes)

---

## VUE D'ENSEMBLE

### Architecture des Données

```
data/
├── abilities/           # Capacités (fireball.json, heal.json, ...)
├── battles/            # Données de combat (tutorial.json, boss_fight.json, ...)
├── campaign/           # Progression campagne (campaign_start.json)
├── dialogues/          # Dialogues (intro_prologue.json, village_elder.json)
├── enemies/            # Templates ennemis (goblin_warrior.json, ...)
├── items/
│   ├── consumables/    # Potions, scrolls
│   └── weapons/        # Armes, armures
├── mana/              # Effets de mana (mana_effects.json)
├── maps/
│   ├── locations/      # Détails locations (starting_village.json, ...)
│   ├── overworld.json  # Carte générale (legacy)
│   └── world_map_data.json  # Données world map
├── ring/              # Anneaux duo (rings.json)
├── scenarios/         # Scénarios combat (tutorial_scenario.json)
└── team/              # Unités recrutables (available_units.json)

localization/
└── dialogues.csv      # Traductions (en, fr, es)
```

### Loaders Disponibles

```gdscript
JSONDataLoader          # Chargeur générique
AbilityDataLoader      # Charge abilities/
DialogueDataLoader     # Charge dialogues/
EnemyDataLoader        # Charge enemies/
ItemDataLoader         # Charge items/ (récursif)
WorldMapDataLoader     # Charge maps/
```

---

## SYSTÈME D'ITEMS & INVENTAIRE

### Structure Item Générique

**Champs communs (tous items) :**

```json
{
  "id": "unique_item_id",
  "name": "Nom affiché",
  "description": "Description détaillée",
  "category": "weapon|armor|consumable|misc",
  "subcategory": "sword|potion|helmet|...",
  "rarity": "common|uncommon|rare|epic|legendary",
  "value": 150,           // Prix de vente (achat = value * 2)
  "weight": 3.5,
  "stackable": true|false,
  "max_stack": 99,
  "icon": "res://path/to/icon.png"
}
```

### Items Consommables

**Fichier :** `data/items/consumables/health_potion.json`

```json
{
  "id": "health_potion",
  "name": "Potion de vie",
  "description": "Restaure 50 PV",
  "category": "consumable",
  "subcategory": "potion",
  "rarity": "common",
  "value": 25,
  "weight": 0.2,
  "stackable": true,
  "max_stack": 99,
  "usable_in_combat": true,
  "usable_in_field": true,
  "effects": [
    {
      "type": "heal",
      "target": "self",
      "value": 50,
      "is_percentage": false
    }
  ],
  "use_animation": "res://animations/items/use_potion.tres",
  "icon": "res://assets/icons/items/health_potion.png"
}
```

**Champs spécifiques consommables :**

- `usable_in_combat` : Utilisable en combat
- `usable_in_field` : Utilisable hors combat
- `effects[]` : Liste d'effets
  - `type` : "heal", "damage", "buff", "debuff", "cleanse"
  - `target` : "self", "ally", "enemy", "all_allies", "all_enemies"
  - `value` : Valeur numérique
  - `is_percentage` : Si true, value en %

**Types d'effets :**

```gdscript
# Heal
{"type": "heal", "target": "self", "value": 50}

# Buff temporaire
{"type": "buff", "stat": "attack", "value": 10, "duration": 3}

# Cleanse (retirer statut)
{"type": "cleanse", "status": "poison"}

# Resurrection
{"type": "revive", "target": "ally", "hp_percent": 0.5}
```

### Items Équipables

**Fichier :** `data/items/weapons/iron_sword.json`

```json
{
  "id": "iron_sword",
  "name": "Épée en fer",
  "description": "Une épée solide en fer forgé",
  "category": "weapon",
  "subcategory": "sword",
  "rarity": "common",
  "value": 150,
  "weight": 3.5,
  "stackable": false,
  "max_stack": 1,
  "equippable": true,
  "equipment_slot": "main_hand",
  "stats": {
    "attack": 15,
    "strength": 2
  },
  "requirements": {
    "level": 5,
    "strength": 10
  },
  "effects": [],
  "icon": "res://assets/icons/items/iron_sword.png",
  "model": "res://assets/models/items/iron_sword.glb"
}
```

**Champs spécifiques équipables :**

- `equippable` : true
- `equipment_slot` : 
  - Armes : "main_hand", "off_hand", "two_hand"
  - Armures : "head", "chest", "legs", "feet", "hands"
  - Accessoires : "ring", "necklace", "accessory"
- `stats{}` : Bonus de stats
- `requirements{}` : Prérequis d'équipement
- `effects[]` : Effets passifs (regen, thorns, ...)
- `model` : Modèle 3D (pour affichage équipement)

**Slots d'équipement :**

```
main_hand     # Arme principale
off_hand      # Bouclier/Arme secondaire
two_hand      # Arme à 2 mains (occupe main_hand + off_hand)
head          # Casque
chest         # Armure
legs          # Jambières
feet          # Bottes
hands         # Gants
ring_1        # Anneau 1
ring_2        # Anneau 2
necklace      # Collier
accessory     # Accessoire spécial
```

### ItemDataLoader

**Fichier :** `scripts/data/loaders/item_data_loader.gd`

#### Chargement Récursif

```gdscript
const ITEMS_DIR = "res://data/items/"

var items: Dictionary = {}
var items_by_category: Dictionary = {}

func load_all_items():
    # Charge récursivement tous les .json
    items = _json_loader.load_json_directory(ITEMS_DIR, true)
    _organize_by_category()

func _organize_by_category():
    # Aplatit la hiérarchie de dossiers
    _flatten_items(items, items_by_category)
```

#### API

```gdscript
get_item(item_id: String) -> Dictionary
get_items_by_category(category: String) -> Array
```

**Exemple d'utilisation :**

```gdscript
# Chargement
var item_loader = ItemDataLoader.new()
item_loader.load_all_items()

# Récupération
var potion = item_loader.get_item("health_potion")
var all_weapons = item_loader.get_items_by_category("weapon")
```

### Système d'Inventaire (à implémenter)

**Structure proposée :**

```gdscript
class_name InventorySystem extends Node

var items: Dictionary = {}  # item_id -> quantity
var equipped: Dictionary = {}  # slot -> item_id
var max_weight: float = 100.0
var current_weight: float = 0.0

func add_item(item_id: String, quantity: int = 1) -> bool
func remove_item(item_id: String, quantity: int = 1) -> bool
func has_item(item_id: String, quantity: int = 1) -> bool
func get_quantity(item_id: String) -> int

func equip_item(item_id: String, slot: String) -> bool
func unequip_item(slot: String) -> bool
func get_equipped(slot: String) -> String

func use_item(item_id: String, target: BattleUnit3D) -> bool
func calculate_weight() -> float
```

---

## SYSTÈME D'ABILITIES

### Structure Ability

**Fichier :** `data/abilities/fireball.json`

```json
{
  "id": "fireball",
  "name": "Fireball",
  "description": "Launches a ball of fire at the enemy",
  "type": "offensive_magic",
  "cost": {
    "mp": 15,
    "cooldown": 2
  },
  "damage": {
    "base": 40,
    "scaling": "intelligence",
    "multiplier": 1.5
  },
  "range": 4,
  "area_effect": {
    "type": "circle",
    "radius": 1
  },
  "effects": [
    {
      "type": "damage",
      "element": "fire",
      "value": 40
    },
    {
      "type": "status",
      "status_id": "burning",
      "chance": 0.3,
      "duration": 3
    }
  ],
  "animation": "res://animations/abilities/fireball.tres",
  "icon": "res://assets/icons/abilities/fireball.png",
  "sound": "res://audio/sfx/fireball.ogg"
}
```

### Champs Détaillés

**Champs de base :**

```json
{
  "id": "unique_ability_id",
  "name": "Nom affiché",
  "description": "Description complète",
  "type": "offensive_magic|defensive_magic|support|physical|passive"
}
```

**Coûts :**

```json
{
  "cost": {
    "mp": 15,           // Coût en mana
    "hp": 0,            // Coût en HP (rare)
    "cooldown": 2,      // Tours de cooldown
    "charges": 3        // Nombre d'utilisations (optionnel)
  }
}
```

**Dégâts :**

```json
{
  "damage": {
    "base": 40,                    // Dégâts de base
    "scaling": "intelligence",     // Stat de scaling
    "multiplier": 1.5,             // Multiplicateur
    "type": "physical|magical"     // Type de dégâts
  }
}
```

**Portée & Zone :**

```json
{
  "range": 4,                      // Portée en cases
  "area_effect": {
    "type": "single|circle|line|cone|cross",
    "radius": 1,                   // Pour circle
    "length": 3,                   // Pour line/cone
    "width": 2                     // Pour cone
  }
}
```

**Effets :**

```json
{
  "effects": [
    {
      "type": "damage|heal|buff|debuff|status|knockback|teleport",
      "element": "fire|ice|lightning|holy|dark|nature|physical",
      "value": 40,
      "stat": "attack",              // Pour buff/debuff
      "status_id": "burning",        // Pour status
      "chance": 0.3,                 // Probabilité
      "duration": 3                  // Durée en tours
    }
  ]
}
```

**Assets :**

```json
{
  "animation": "res://path/to/animation.tres",
  "icon": "res://path/to/icon.png",
  "sound": "res://path/to/sound.ogg",
  "particle_effect": "res://path/to/particles.tscn"
}
```

### Types d'Abilities

**offensive_magic :**
- Attaques magiques (fireball, ice_storm, lightning_bolt)
- Scaling sur intelligence/magic
- Souvent AOE

**defensive_magic :**
- Boucliers, barrières (shield, ice_barrier)
- Buffs de défense

**support :**
- Soins, buffs d'équipe (heal, bless, haste)
- Peut cibler alliés

**physical :**
- Attaques physiques (heroic_strike, cleave)
- Scaling sur strength/attack

**passive :**
- Effets permanents (counter_attack, regeneration)
- Pas de coût, toujours actif

### AbilityDataLoader

**Fichier :** `scripts/data/loaders/ability_data_loader.gd`

```gdscript
const ABILITIES_DIR = "res://data/abilities/"

var abilities: Dictionary = {}  # ability_id -> ability_data

func load_all_abilities():
    abilities = _json_loader.load_json_directory(ABILITIES_DIR, false)

func get_ability(ability_id: String) -> Dictionary:
    return abilities.get(ability_id, {})

func validate_ability(data: Dictionary) -> bool:
    var required = ["id", "name", "type", "cost"]
    return _json_loader.validate_schema(data, required)
```

### Système d'Abilities (à implémenter)

**Structure proposée :**

```gdscript
class_name AbilitySystem extends Node

var ability_loader: AbilityDataLoader

func can_use_ability(unit: BattleUnit3D, ability_id: String) -> bool:
    var ability = ability_loader.get_ability(ability_id)
    return _check_cost(unit, ability) and _check_cooldown(unit, ability)

func use_ability(caster: BattleUnit3D, ability_id: String, target: BattleUnit3D):
    var ability = ability_loader.get_ability(ability_id)
    
    # Consommer coûts
    _consume_cost(caster, ability)
    
    # Appliquer effets
    for effect in ability.effects:
        _apply_effect(caster, target, effect)
    
    # Lancer animation
    _play_ability_animation(ability)
```

---

## SYSTÈME D'ENNEMIS

### Structure Ennemi

**Fichier :** `data/enemies/goblin_warrior.json`

```json
{
  "id": "goblin_warrior",
  "name": "Goblin Guerrier",
  "description": "Un goblin armé d'une épée rouillée",
  "type": "humanoid",
  "rank": "common",
  "stats": {
    "hp": 50,
    "mp": 10,
    "strength": 12,
    "defense": 8,
    "magic": 3,
    "magic_defense": 5,
    "speed": 15,
    "luck": 5
  },
  "resistances": {
    "physical": 0,
    "fire": -0.5,      // Faible au feu (-50%)
    "ice": 0,
    "lightning": 0,
    "dark": 0.2        // Résistant au dark (+20%)
  },
  "abilities": [
    "goblin_slash",
    "battle_cry"
  ],
  "ai_behavior": "aggressive_melee",
  "loot_table": {
    "gold": {"min": 5, "max": 15},
    "items": [
      {"item_id": "rusty_sword", "chance": 0.15},
      {"item_id": "leather_scraps", "chance": 0.4},
      {"item_id": "health_potion", "chance": 0.25}
    ]
  },
  "experience": 25,
  "sprite": "res://assets/sprites/enemies/goblin_warrior.png",
  "animations": {
    "idle": "res://animations/enemies/goblin_idle.tres",
    "attack": "res://animations/enemies/goblin_attack.tres",
    "hit": "res://animations/enemies/goblin_hit.tres",
    "death": "res://animations/enemies/goblin_death.tres"
  }
}
```

### Champs Détaillés

**Identité :**

```json
{
  "id": "unique_enemy_id",
  "name": "Nom affiché",
  "description": "Description",
  "type": "humanoid|beast|undead|demon|elemental|dragon",
  "rank": "common|elite|boss|miniboss|legendary"
}
```

**Stats :**

Identiques aux unités joueur, plus :
- `mp` : Mana (si utilise magie)
- `luck` : Influence critiques, drops

**Résistances :**

```json
{
  "resistances": {
    "physical": 0,     // 0 = normal
    "fire": -0.5,      // -0.5 = faible (-50% dégâts)
    "ice": 0.2,        // 0.2 = résistant (+20% dégâts)
    "lightning": -1.0, // -1.0 = vulnérable (double dégâts)
    "holy": 0,
    "dark": 1.0        // 1.0 = immunité (0 dégâts)
  }
}
```

**AI Behavior :**

```gdscript
"ai_behavior": 
    "aggressive_melee"    # Attaque au corps-à-corps
    "defensive"           # Défend position
    "ranged_kiter"        # Attaque à distance + fuite
    "support"             # Buff alliés, heal
    "berserker"           # Attaque coûte que coûte
    "tactical"            # Utilise terrain, focus cibles faibles
```

**Loot Table :**

```json
{
  "loot_table": {
    "gold": {
      "min": 5,
      "max": 15
    },
    "items": [
      {
        "item_id": "rusty_sword",
        "chance": 0.15      // 15% de drop
      },
      {
        "item_id": "health_potion",
        "chance": 0.25,
        "quantity_min": 1,
        "quantity_max": 3
      }
    ]
  },
  "experience": 25
}
```

### EnemyDataLoader

**Fichier :** `scripts/data/loaders/enemy_data_loader.gd`

```gdscript
const ENEMIES_DIR = "res://data/enemies/"

var enemies: Dictionary = {}  # enemy_id -> enemy_data

func load_all_enemies():
    enemies = _json_loader.load_json_directory(ENEMIES_DIR, true)

func get_enemy(enemy_id: String) -> Dictionary:
    return enemies.get(enemy_id, {})

func create_enemy_instance(enemy_id: String, level: int = 1) -> Dictionary:
    var base_data = get_enemy(enemy_id).duplicate(true)
    
    # Scaling stats par niveau
    for stat in base_data.stats:
        base_data.stats[stat] = _scale_stat(base_data.stats[stat], level)
    
    base_data["current_level"] = level
    return base_data

func _scale_stat(base_value: float, level: int) -> float:
    # +10% par niveau
    return base_value * (1.0 + (level - 1) * 0.1)
```

---

## FORMATS DE DONNÉES DE COMBAT

### Battle Data (complet)

**Fichier :** `data/battles/tutorial.json`

```json
{
  "battle_id": "tutorial",
  "scenario_file": "res://data/scenarios/tutorial_scenario.json",
  "name": "Combat Tutoriel",
  "description": "Apprenez les bases du combat",
  "terrain": "plains",
  "player_units": [
    {
      "name": "Knight",
      "id": "player_knight_1",
      "position": {"x": 3, "y": 7},
      "stats": {
        "hp": 100,
        "attack": 25,
        "defense": 15,
        "movement": 5,
        "range": 1
      },
      "abilities": ["basic_attack", "shield_bash"],
      "color": {"r": 0.2, "g": 0.6, "b": 0.9, "a": 1.0}
    }
  ],
  "enemy_units": [
    {
      "name": "Goblin Scout",
      "id": "enemy_goblin_1",
      "position": {"x": 15, "y": 7},
      "stats": {
        "hp": 50,
        "attack": 15,
        "defense": 8,
        "movement": 5,
        "range": 1
      },
      "abilities": ["basic_attack"],
      "color": {"r": 0.8, "g": 0.3, "b": 0.3, "a": 1.0}
    }
  ],
  "objectives": {
    "primary": [
      {
        "type": "defeat_all_enemies",
        "description": "Éliminez tous les ennemis"
      }
    ],
    "secondary": [
      {
        "type": "no_units_lost",
        "description": "Ne perdez aucune unité"
      }
    ]
  },
  "scenario": {
    "has_intro": true,
    "intro_dialogue": "tutorial_intro",
    "has_outro": true,
    "outro_victory": "tutorial_victory",
    "outro_defeat": "tutorial_defeat"
  }
}
```

### Champs Détaillés

**Structure de base :**

```json
{
  "battle_id": "unique_battle_id",
  "name": "Nom du combat",
  "description": "Description",
  "terrain": "plains|forest|mountain|castle|desert",
  "grid_size": {
    "width": 20,
    "height": 15
  }
}
```

**Unités :**

Position en objet `{"x": 3, "y": 7}` converti en `Vector2i` par CampaignManager.

```gdscript
# Conversion dans CampaignManager
unit.position = Vector2i(pos.x, pos.y)
```

**Objectifs :**

```json
{
  "objectives": {
    "primary": [
      {"type": "defeat_all_enemies"},
      {"type": "defeat_boss", "unit_id": "boss_id"},
      {"type": "survive_turns", "turns": 10},
      {"type": "reach_position", "position": {"x": 10, "y": 5}},
      {"type": "protect_unit", "unit_id": "vip_id"}
    ],
    "secondary": [
      {"type": "no_units_lost"},
      {"type": "complete_in_turns", "turns": 15}
    ]
  }
}
```

**Scénario :**

```json
{
  "scenario": {
    "has_intro": true,
    "intro_dialogue": "dialogue_id",
    "has_outro": true,
    "outro_victory": "victory_dialogue_id",
    "outro_defeat": "defeat_dialogue_id",
    "special_events": {
      "boss_half_hp": {
        "trigger": "unit_hp_below",
        "unit_id": "boss",
        "threshold": 0.5,
        "action": "summon_reinforcements"
      }
    }
  }
}
```

### Scenario Data

**Fichier :** `data/scenarios/tutorial_scenario.json`

```json
{
  "scenario_id": "tutorial",
  "intro_dialogue": [
    {"speaker": "Instructeur", "text": "Bienvenue !"},
    {"speaker": "Instructeur", "text": "Préparez-vous."}
  ],
  "turn_events": {
    "turn_3": {
      "type": "dialogue",
      "dialogue": [
        {"speaker": "Instructeur", "text": "Bien joué !"}
      ]
    }
  },
  "position_events": {
    "10,10": {
      "type": "dialogue",
      "dialogue": [
        {"speaker": "Système", "text": "Point stratégique !"}
      ]
    }
  },
  "outro_victory": [
    {"speaker": "Instructeur", "text": "Excellent !"}
  ],
  "outro_defeat": [
    {"speaker": "Instructeur", "text": "Réessayez."}
  ]
}
```

**Structure :**

- `intro_dialogue[]` : Dialogue avant combat
- `turn_events{}` : Événements par tour (clé = "turn_N")
- `position_events{}` : Événements par position (clé = "x,y")
- `outro_victory[]` : Dialogue victoire
- `outro_defeat[]` : Dialogue défaite

---

## SYSTÈME DE CAMPAIGN

### Campaign Start

**Fichier :** `data/campaign/campaign_start.json`

```json
{
  "campaign_id": "main_campaign",
  "title": "La Prophétie des Duos",
  "version": "1.0.0",
  "initial_state": {
    "chapter": 1,
    "battle_index": 0,
    "battles_won": 0,
    "unlocked_locations": ["starting_village"],
    "discovered_locations": ["starting_village"],
    "current_location": "starting_village"
  },
  "start_sequence": [
    {
      "type": "dialogue",
      "dialogue_id": "intro_prologue",
      "blocking": true
    },
    {
      "type": "notification",
      "message": "Bienvenue !",
      "duration": 2.5
    },
    {
      "type": "unlock_location",
      "location": "starting_village"
    },
    {
      "type": "transition",
      "target": "world_map",
      "fade_duration": 1.0
    }
  ],
  "chapters": [
    {
      "id": 1,
      "title": "L'Éveil",
      "description": "Le début de votre aventure",
      "battles": [
        {
          "battle_id": "tutorial",
          "required": true,
          "unlock_condition": null
        },
        {
          "battle_id": "forest_battle",
          "required": true,
          "unlock_condition": {
            "type": "battle_completed",
            "battle_id": "tutorial"
          }
        }
      ]
    }
  ],
  "initial_party": {
    "max_size": 4,
    "units": [
      {"unit_id": "knight_hero", "level": 1, "locked": false},
      {"unit_id": "archer_starter", "level": 1, "locked": false}
    ]
  },
  "initial_inventory": {
    "gold": 100,
    "items": [
      {"item_id": "health_potion", "quantity": 3},
      {"item_id": "iron_sword", "quantity": 1}
    ]
  },
  "divine_favor": {
    "astraeon": 0,
    "kharvul": 0
  }
}
```

### Séquence de Démarrage

**Types d'actions :**

```json
{
  "type": "dialogue",
  "dialogue_id": "intro_prologue",
  "blocking": true
}

{
  "type": "notification",
  "message": "Bienvenue dans Tactical RPG Duos !",
  "duration": 2.5
}

{
  "type": "unlock_location",
  "location": "starting_village"
}

{
  "type": "transition",
  "target": "world_map",
  "fade_duration": 1.0
}
```

### Chapitres

**Structure :**

```json
{
  "id": 1,
  "title": "Titre du chapitre",
  "description": "Description",
  "battles": [
    {
      "battle_id": "tutorial",
      "required": true,
      "unlock_condition": null
    },
    {
      "battle_id": "next_battle",
      "required": false,
      "unlock_condition": {
        "type": "battle_completed|chapter_completed|level_reached",
        "battle_id": "tutorial",
        "chapter_id": 1,
        "level": 5
      }
    }
  ]
}
```

### Gestion Campaign

**Dans CampaignManager :**

```gdscript
func start_new_campaign():
    var campaign_data = _load_campaign_start_from_json()
    
    # Initialiser état
    campaign_state = {
        current_chapter: campaign_data.initial_state.chapter,
        current_battle: campaign_data.initial_state.battle_index,
        battles_won: 0
    }
    
    # Lancer séquence
    for action in campaign_data.start_sequence:
        await _execute_start_action(action)
    
    EventBus.campaign_started.emit()
```

---

## SYSTÈME DE LOCATIONS & MAPS

### Location Data

**Fichier :** `data/maps/locations/starting_village.json`

```json
{
  "id": "starting_village",
  "name": "Village de Départ",
  "description": "Un paisible village",
  "type": "village",
  "population": 150,
  "actions": [
    {
      "id": "talk_to_elder",
      "type": "dialogue",
      "label": "💬 Parler à l'Ancien",
      "icon": "res://assets/icons/actions/dialogue.png",
      "dialogue_id": "village_elder",
      "unlocked_at_step": 0
    },
    {
      "id": "visit_shop",
      "type": "shop",
      "label": "🛒 Magasin",
      "icon": "res://assets/icons/actions/shop.png",
      "shop_id": "village_general_store",
      "unlocked_at_step": 0
    },
    {
      "id": "manage_team",
      "type": "team_management",
      "label": "👥 Gérer l'Équipe",
      "unlocked_at_step": 0
    }
  ],
  "npcs": [
    {
      "id": "elder_harold",
      "name": "Harold l'Ancien",
      "dialogue_id": "village_elder",
      "locations": [
        {
          "place_id": "town_square",
          "place_name": "Place du village",
          "chance": 60.0
        },
        {
          "place_id": "elder_house",
          "place_name": "Maison de l'ancien",
          "chance": 40.0
        }
      ]
    }
  ],
  "shops": [
    {
      "id": "village_general_store",
      "name": "Magasin Général",
      "inventory": [
        {"item_id": "health_potion", "stock": 10, "price": 25},
        {"item_id": "iron_sword", "stock": 2, "price": 150}
      ]
    }
  ]
}
```

### Types d'Actions

```json
// Dialogue
{
  "type": "dialogue",
  "label": "💬 Parler",
  "dialogue_id": "npc_id"
}

// Shop
{
  "type": "shop",
  "label": "🛒 Magasin",
  "shop_id": "shop_id"
}

// Battle
{
  "type": "battle",
  "label": "⚔️ Combat",
  "battle_id": "battle_id"
}

// Building (scène custom)
{
  "type": "building",
  "label": "🏰 Entrer",
  "scene": "res://scenes/world/buildings/castle.tscn"
}

// Quest Board
{
  "type": "quest_board",
  "label": "📋 Quêtes"
}

// Team Management
{
  "type": "team_management",
  "label": "👥 Équipe"
}

// Custom Event
{
  "type": "custom",
  "label": "🔍 Chercher",
  "event": {
    "type": "custom_event",
    "event_id": "event_id"
  }
}
```

### NPCs avec Probabilités

**Structure NPC :**

```json
{
  "id": "npc_id",
  "name": "Nom NPC",
  "dialogue_id": "dialogue_id",
  "locations": [
    {
      "place_id": "unique_place_id",
      "place_name": "Nom affiché",
      "chance": 60.0
    }
  ]
}
```

**Calcul de position :**

```gdscript
# Dans WorldMapDataLoader
static func _calculate_npc_position(npc: Dictionary) -> Dictionary:
    var roll = randf() * 100.0
    var cumulative = 0.0
    
    for loc in npc.locations:
        cumulative += loc.chance
        if roll <= cumulative:
            return {
                "npc": npc,
                "place_id": loc.place_id,
                "place_name": loc.place_name
            }
    
    # Fallback : première location
    return {...}
```

### World Map Data

**Fichier :** `data/maps/world_map_data.json`

```json
{
  "id": "main_world",
  "name": "Continent de Terramia",
  "grid_size": {"width": 1920, "height": 1080},
  "locations": [
    {
      "id": "starting_village",
      "name": "Village de Départ",
      "type": "village",
      "position": {"x": 400, "y": 300},
      "icon": "res://assets/icons/locations/village.png",
      "scale": 2.0,
      "color": {"r": 0.3, "g": 0.8, "b": 0.3, "a": 1.0},
      "unlocked_at_step": 0,
      "connections": ["dark_forest", "capital_city"]
    }
  ],
  "connections_visual": {
    "color": {"r": 0.7, "g": 0.7, "b": 0.7, "a": 0.8},
    "color_locked": {"r": 0.3, "g": 0.3, "b": 0.3, "a": 0.4},
    "width": 5.0,
    "dash_length": 20.0,
    "gap_length": 12.0
  },
  "connection_states": {
    "starting_village_to_dark_forest": "unlocked",
    "dark_forest_to_capital_city": "locked",
    "capital_city_to_eastern_port": "hidden"
  },
  "player": {
    "start_location": "starting_village",
    "icon": "res://icon.svg",
    "scale": 1.5,
    "bounce_speed": 1.5,
    "bounce_amount": 10.0,
    "move_speed": 300.0
  }
}
```

### WorldMapDataLoader

**Fichier :** `scripts/data/loaders/world_map_data_loader.gd`

```gdscript
const WORLD_MAP_PATH := "res://data/maps/"

static func load_world_map_data(map_id: String = "world_map_data") -> Dictionary:
    var json_path = WORLD_MAP_PATH + map_id + ".json"
    var data = json_loader.load_json_file(json_path)
    return _convert_map_positions(data)

static func load_location_data(location_id: String) -> Dictionary:
    var json_path = WORLD_MAP_PATH + "locations/" + location_id + ".json"
    return json_loader.load_json_file(json_path)

static func get_unlocked_locations(current_step: int, map_id: String) -> Array:
    var all_locations = get_all_locations(map_id)
    return all_locations.filter(
        func(loc): return loc.unlocked_at_step <= current_step
    )
```

---

## SYSTÈME DE MANA & EFFETS

### Mana Effects

**Fichier :** `data/mana/mana_effects.json`

```json
{
  "effects": [
    {
      "effect_id": "burn",
      "effect_name": "Brûlure",
      "mana_type": "FIRE",
      "duration": 3.0,
      "damage_over_time": 5,
      "stat_modifiers": {
        "defense": -5
      },
      "description": "Inflige des dégâts de feu sur la durée"
    },
    {
      "effect_id": "freeze",
      "effect_name": "Gel",
      "mana_type": "ICE",
      "duration": 2.0,
      "damage_over_time": 0,
      "stat_modifiers": {
        "movement": -2,
        "speed": -50
      },
      "description": "Ralentit significativement la cible"
    }
  ]
}
```

### Champs Effet de Mana

```json
{
  "effect_id": "unique_effect_id",
  "effect_name": "Nom affiché",
  "mana_type": "FIRE|ICE|LIGHTNING|HOLY|DARK|NATURE",
  "duration": 3.0,
  "damage_over_time": 5,        // Dégâts par tour (optionnel)
  "heal_over_time": 3,          // Soins par tour (optionnel)
  "stat_modifiers": {
    "attack": 10,               // Bonus/malus temporaires
    "defense": -5,
    "movement": -2,
    "speed": -50
  },
  "description": "Description de l'effet"
}
```

### Types de Mana

```
FIRE      → Burn (DoT), bonus attaque
ICE       → Freeze (slow), réduit mouvement
LIGHTNING → Stun (skip turn), bonus vitesse
HOLY      → Heal (HoT), bonus défense
DARK      → Curse (debuff), draine HP
NATURE    → Regen (HoT), bonus résistances
```

### Rings & Mana

**Fichier :** `data/ring/rings.json`

```json
{
  "materialization_rings": [
    {
      "ring_id": "mat_basic_line",
      "ring_name": "Anneau de Ligne Basique",
      "attack_shape": "line",
      "base_range": 3,
      "area_size": 1
    }
  ],
  "channeling_rings": [
    {
      "ring_id": "chan_fire",
      "ring_name": "Anneau de Feu",
      "mana_effect_id": "burn",
      "mana_potency": 1.0,
      "effect_duration": 3.0
    }
  ]
}
```

**Génération AttackProfile :**

```gdscript
# Dans RingSystem
var profile = generate_attack_profile("mat_basic_line", "chan_fire")
# profile = {
#   shape: "line",
#   range: 3,
#   area: 1,
#   mana_effect: "burn",
#   potency: 1.0,
#   duration: 3.0
# }
```

---

## SYSTÈME DE LOCALISATION

### Structure i18n

**Fichier :** `localization/dialogues.csv`

```csv
keys,en,fr,es
dialogue.intro.knight.001,"Prepare for battle!","Préparez-vous au combat !","¡Prepárense para la batalla!"
speaker.knight,"Sir Gaheris","Sire Gaheris","Sir Gaheris"
bark.damaged,"Ow!","Aïe !","¡Ay!"
```

### Configuration Project

**project.godot :**

```ini
[internationalization]
locale/translations=PackedStringArray(
    "res://localization/dialogues.en.translation",
    "res://localization/dialogues.fr.translation",
    "res://localization/dialogues.es.translation"
)
```

### Utilisation dans le Code

**Traduction de texte :**

```gdscript
# Clé de traduction
var text = tr("dialogue.intro.knight.001")

# Avec fallback
var text = line.get("text", "")
var text_key = line.get("text_key", "")
if text_key:
    text = tr(text_key)
```

**Convention de clés :**

```
dialogue.{context}.{character}.{number}
speaker.{character_id}
bark.{emotion}
ui.{element}.{action}
item.{item_id}.name
item.{item_id}.description
ability.{ability_id}.name
```

### Système de Langue

**LanguageManager (à implémenter) :**

```gdscript
class_name LanguageManager extends Node

const AVAILABLE_LANGUAGES = ["en", "fr", "es"]
var current_language: String = "en"

func set_language(lang: String):
    if lang in AVAILABLE_LANGUAGES:
        TranslationServer.set_locale(lang)
        current_language = lang
        EventBus.language_changed.emit(lang)

func get_current_language() -> String:
    return TranslationServer.get_locale()
```

---

## SCHÉMAS DE VALIDATION

### Validation des Données au Démarrage

**Dans DataValidationModule :**

```gdscript
const DATA_PATHS = {
    "rings": "res://data/ring/rings.json",
    "mana_effects": "res://data/mana/mana_effects.json",
    "units": "res://data/team/available_units.json",
    "abilities": "res://data/abilities/",  # Dossier
    "enemies": "res://data/enemies/",      # Dossier
    "items": "res://data/items/"           # Dossier
}

func validate_all_data() -> ValidationReport:
    var report = ValidationReport.new()
    
    _validate_rings_file(report)
    _validate_mana_effects_file(report)
    _validate_units_file(report)
    _validate_abilities_directory(report)
    _validate_enemies_directory(report)
    _validate_items_directory(report)
    
    return report
```

### Champs Requis par Type

**Rings :**

```gdscript
const REQUIRED_FIELDS = {
    "materialization_ring": [
        "ring_id", "ring_name", "attack_shape", "base_range"
    ],
    "channeling_ring": [
        "ring_id", "ring_name", "mana_effect_id"
    ]
}
```

**Mana Effects :**

```gdscript
const REQUIRED_FIELDS = {
    "mana_effect": [
        "effect_id", "mana_type"
    ]
}
```

**Items :**

```gdscript
const REQUIRED_FIELDS = {
    "item": [
        "id", "name", "category", "value"
    ]
}
```

**Abilities :**

```gdscript
const REQUIRED_FIELDS = {
    "ability": [
        "id", "name", "type", "cost"
    ]
}
```

**Enemies :**

```gdscript
const REQUIRED_FIELDS = {
    "enemy": [
        "id", "name", "stats", "ai_behavior"
    ]
}
```

### Validation Détaillée

**Exemple : Validation Ring :**

```gdscript
func validate_rings(rings: Array, ring_type: String) -> Array[String]:
    var errors: Array[String] = []
    var required = REQUIRED_FIELDS.get(ring_type, [])
    
    for i in range(rings.size()):
        var ring = rings[i]
        
        # Vérifier champs requis
        for field in required:
            if not ring.has(field):
                errors.append("[%d] Champ requis manquant: %s" % [i, field])
        
        # Vérifications spécifiques
        if ring_type == "materialization_ring":
            if ring.has("attack_shape"):
                var valid_shapes = ["line", "cone", "circle", "cross", "area"]
                if ring.attack_shape not in valid_shapes:
                    errors.append("[%d] attack_shape invalide" % i)
    
    return errors
```

---

## CHECKLIST D'INTÉGRATION

### ✅ Systèmes de Base

- [x] EventBus
- [x] SceneLoader & SceneRegistry
- [x] GameManager
- [x] GlobalLogger
- [x] DebugOverlay

### ✅ Systèmes de Combat

- [x] BattleMapManager3D
- [x] TerrainModule3D
- [x] UnitManager3D
- [x] MovementModule3D (A*)
- [x] ActionModule3D
- [x] AIModule3D
- [x] ObjectiveModule
- [x] DuoSystem
- [x] RingSystem
- [x] CommandHistory
- [x] BattleStateMachine

### ✅ Managers de Données

- [x] BattleDataManager
- [x] CampaignManager
- [x] TeamManager
- [x] Dialogue_Manager

### ✅ Data Loaders

- [x] JSONDataLoader
- [x] DialogueDataLoader
- [x] WorldMapDataLoader
- [ ] AbilityDataLoader *(fichier présent, non utilisé)*
- [ ] EnemyDataLoader *(fichier présent, non utilisé)*
- [ ] ItemDataLoader *(fichier présent, non utilisé)*

### ⚠️ Systèmes UI

- [x] DialogueBox
- [x] BarkSystem
- [x] WorldMapLocation
- [x] WorldMapConnection
- [x] WorldMapPlayer
- [ ] InventoryUI *(à implémenter)*
- [ ] ShopUI *(à implémenter)*
- [ ] TeamRosterUI *(partiellement implémenté)*
- [ ] AbilityMenu *(à implémenter)*

### ⚠️ Systèmes Gameplay

- [x] DialogueData
- [ ] AbilitySystem *(à implémenter)*
- [ ] InventorySystem *(à implémenter)*
- [ ] StatusEffectSystem *(à implémenter)*
- [ ] LootSystem *(à implémenter)*
- [ ] ShopSystem *(à implémenter)*
- [ ] QuestSystem *(à implémenter)*

### ⚠️ Validation & Testing

- [x] DataValidationModule
- [x] BattleDataValidator
- [x] Validator (générique)
- [ ] ItemValidator *(à créer)*
- [ ] AbilityValidator *(à créer)*
- [ ] EnemyValidator *(à créer)*

### 📊 Données JSON

**Présentes et valides :**
- [x] abilities/fireball.json
- [x] battles/tutorial.json, forest_battle.json, village_defense.json, boss_fight.json
- [x] campaign/campaign_start.json
- [x] dialogues/intro_prologue.json, village_elder.json
- [x] enemies/goblin_warrior.json
- [x] items/consumables/health_potion.json
- [x] items/weapons/iron_sword.json
- [x] mana/mana_effects.json
- [x] maps/locations/*.json
- [x] maps/world_map_data.json
- [x] ring/rings.json
- [x] scenarios/tutorial_scenario.json
- [x] team/available_units.json

**Manquantes (pour production) :**
- [ ] Plus d'abilities (heal, shield, lightning, etc.)
- [ ] Plus d'ennemis (orcs, dragons, boss)
- [ ] Plus d'items (armures, accessoires, scrolls)
- [ ] Plus de locations
- [ ] Plus de dialogues
- [ ] Plus de scenarios

---

## INDEX GLOBAL DES SYSTÈMES

### Hiérarchie Complète

```
AUTOLOADS (Godot)
├── EventBus
├── GameManager
│   ├── SceneLoader
│   └── CampaignManager
├── Dialogue_Manager
├── BattleDataManager
├── TeamManager
├── GlobalLogger
├── DebugOverlay
└── Version_Manager

SINGLETONS (Classes)
├── SceneRegistry (static)
└── WorldMapDataLoader (static)

SYSTÈMES DE COMBAT
├── BattleMapManager3D (scene root)
│   ├── TerrainModule3D
│   ├── UnitManager3D
│   ├── MovementModule3D
│   ├── ActionModule3D
│   ├── AIModule3D
│   ├── ObjectiveModule
│   ├── JSONScenarioModule
│   ├── BattleStatsTracker
│   ├── DuoSystem
│   ├── RingSystem
│   ├── DataValidationModule
│   ├── CommandHistory
│   └── BattleStateMachine
└── BattleUnit3D (instances)

SYSTÈMES UI
├── DialogueBox
├── BarkSystem
├── WorldMapLocation
├── WorldMapConnection
├── WorldMapPlayer
└── TeamRosterUI

DATA LOADERS
├── JSONDataLoader (générique)
├── AbilityDataLoader
├── DialogueDataLoader
├── EnemyDataLoader
├── ItemDataLoader
└── WorldMapDataLoader

VALIDATION
├── Validator (base)
├── ValidationRule
├── ValidationResult
├── BattleDataValidator
└── DataValidationModule

UTILITAIRES
├── Command (pattern)
├── CommandHistory
├── StateMachine (générique)
├── BattleStateMachine
└── Version_Manager
```

### Flow Complet d'une Partie

```
1. DÉMARRAGE
   ├── Godot _ready() → Autoloads initialisés
   ├── GameManager._ready()
   │   ├── SceneLoader créé
   │   ├── SceneRegistry validé
   │   ├── CampaignManager créé
   │   └── load_scene(MAIN_MENU)
   └── DataValidationModule.validate_all_data()

2. NOUVELLE PARTIE
   ├── User clique "Nouvelle Partie"
   ├── GameManager._on_game_started()
   ├── CampaignManager.start_new_campaign()
   │   ├── Load campaign_start.json
   │   ├── Initialiser campaign_state
   │   └── Exécuter start_sequence
   │       ├── DialogueBox.play(intro_prologue)
   │       ├── EventBus.notify("Bienvenue!")
   │       └── EventBus.change_scene(WORLD_MAP)
   └── WorldMap affichée avec starting_village déverrouillé

3. EXPLORATION
   ├── WorldMap.populate_locations()
   │   └── WorldMapDataLoader.load_world_map_data()
   ├── User clique sur location
   ├── WorldMapLocation._on_clicked()
   │   └── WorldMapDataLoader.load_location_data(location_id)
   ├── LocationMenu affiche actions disponibles
   └── User sélectionne action
       ├── Type "dialogue" → Dialogue_Manager.start_dialogue()
       ├── Type "shop" → ShopUI.open(shop_id)
       ├── Type "battle" → CampaignManager.start_battle(battle_id)
       └── Type "team_management" → TeamRosterUI.show()

4. COMBAT
   ├── CampaignManager.start_battle(battle_id)
   │   ├── Load battle data (JSON)
   │   ├── Merge avec TeamManager.get_current_team()
   │   ├── BattleDataManager.set_battle_data(data)
   │   └── EventBus.change_scene(BATTLE)
   │
   ├── BattleMapManager3D._ready()
   │   ├── await _initialize_modules()
   │   └── initialize_battle(BattleDataManager.get_battle_data())
   │       ├── _load_terrain()
   │       ├── _load_objectives()
   │       ├── _load_scenario()
   │       ├── _spawn_units()
   │       └── _start_battle()
   │
   ├── TOUR JOUEUR
   │   ├── unit_manager.reset_player_units()
   │   ├── User sélectionne unité (raycasting)
   │   ├── Menu d'actions ouvert
   │   ├── User choisit "Attack"
   │   │   └── DuoSystem.try_form_duo() (optionnel)
   │   ├── ActionModule3D.execute_attack()
   │   │   ├── calculate_damage()
   │   │   ├── target.take_damage()
   │   │   └── DamageNumber spawned
   │   └── User clique "End Turn"
   │
   ├── TOUR ENNEMI
   │   ├── unit_manager.reset_enemy_units()
   │   ├── AIModule3D.execute_enemy_turn()
   │   │   ├── evaluate_unit_action()
   │   │   ├── find_best_attack_target()
   │   │   └── execute_ai_action()
   │   └── current_turn++
   │
   ├── VICTOIRE
   │   ├── ObjectiveModule.all_objectives_completed()
   │   ├── _end_battle(true)
   │   │   ├── award_xp_to_survivors()
   │   │   ├── stats_tracker.get_final_stats()
   │   │   ├── _calculate_rewards()
   │   │   └── EventBus.battle_ended.emit(results)
   │   ├── BattleDataManager.clear_battle_data()
   │   └── EventBus.change_scene(BATTLE_RESULTS)
   │
   └── DÉFAITE
       └── Similaire mais without rewards

5. PROGRESSION
   ├── CampaignManager._on_battle_ended(results)
   ├── if victory:
   │   ├── campaign_state.battles_won++
   │   └── _advance_campaign()
   ├── TeamManager.add_xp(units)
   │   └── _level_up() si seuil atteint
   └── EventBus.change_scene(WORLD_MAP)
```

---

## CONVENTIONS DE NOMMAGE

### Fichiers JSON

```
data/
├── {category}/
│   ├── {item_id}.json          # Minuscules, underscore
│   └── {subcategory}/
│       └── {item_id}.json

Exemples:
data/abilities/fireball.json
data/items/weapons/iron_sword.json
data/enemies/goblin_warrior.json
data/maps/locations/starting_village.json
```

### IDs dans JSON

```json
{
  "id": "category_name"          // Minuscules, underscore
}

Exemples:
"fireball"
"health_potion"
"iron_sword"
"goblin_warrior"
"starting_village"
```

### Clés de Localisation

```
{context}.{element}.{number}

Exemples:
dialogue.intro.knight.001
speaker.knight
bark.damaged
ui.button.confirm
item.health_potion.name
ability.fireball.description
```

### Scripts GDScript

```
snake_case          # Variables, fonctions, fichiers
PascalCase          # Classes, types
UPPER_SNAKE_CASE    # Constantes

Exemples:
var health_potion: Item
const MAX_INVENTORY_SIZE: int = 100
func calculate_damage() -> int
class_name ItemDataLoader
```

---

## POINTS D'ATTENTION FINAUX

### ⚠️ Conversions de Types

**JSON → Godot toujours en float :**

```gdscript
# ❌ MAUVAIS
var hp = data.hp  # Type float

# ✅ BON
var hp = int(data.hp)  # Converti en int

# Position
if data.position is Array:
    position = Vector2i(int(pos[0]), int(pos[1]))
else:
    position = data.position  # Déjà Vector2i
```

### ⚠️ Gestion des Ressources

**Chargement d'assets :**

```gdscript
# ❌ MAUVAIS - Bloquer thread principal
var texture = load("res://path/to/texture.png")

# ✅ BON - Chargement asynchrone
ResourceLoader.load_threaded_request(path)
var texture = ResourceLoader.load_threaded_get(path)
```

### ⚠️ Validation au Runtime

**Toujours valider données externes :**

```gdscript
func load_item(item_id: String) -> Dictionary:
    var item = item_loader.get_item(item_id)
    
    # Validation
    if item.is_empty():
        push_error("Item introuvable: " + item_id)
        return {}
    
    if not item.has("category"):
        push_error("Item invalide (pas de category): " + item_id)
        return {}
    
    return item
```

### ⚠️ Sauvegarde

**Format de sauvegarde (proposition) :**

```json
{
  "version": "1.0.0",
  "timestamp": 1706542800,
  "campaign": {
    "chapter": 2,
    "battles_won": 5,
    "current_location": "capital_city"
  },
  "team": {
    "roster": [...],
    "current_team": [...]
  },
  "inventory": {
    "gold": 500,
    "items": {...}
  },
  "progression": {
    "unlocked_locations": [...],
    "completed_battles": [...],
    "discovered_npcs": [...]
  }
}
```

---

## CONCLUSION GÉNÉRALE

### Documentation Complète

**PART1 :** UI, Dialogues, World Map  
**PART2 :** Combat, Modules, Systèmes Avancés  
**PART3 :** Formats JSON, Items, Localisation *(ce fichier)*

### Systèmes Implémentés ✅

- ✅ Combat tactique 3D complet
- ✅ Système de duo
- ✅ Système d'anneaux (rings)
- ✅ Gestion d'équipe (roster)
- ✅ Système de dialogue
- ✅ World map avec locations
- ✅ Campaign manager
- ✅ Data loaders (JSON)
- ✅ Validation de données
- ✅ Localisation (i18n)
- ✅ Debug overlay
- ✅ Logging système
- ✅ Command pattern (undo/redo)
- ✅ State machine

### Systèmes à Implémenter 🚧

- 🚧 Inventaire complet
- 🚧 Système de shop
- 🚧 Système d'abilities en combat
- 🚧 Système de loot
- 🚧 Système de quêtes
- 🚧 Effets de statut en combat
- 🚧 VFX & particules
- 🚧 Audio système complet
- 🚧 Sauvegarde persistante
- 🚧 UI polish (transitions, animations)

### Données à Compléter 📝

**Priorité Haute :**
- Plus d'abilities (10-20 minimum)
- Plus d'ennemis (15-20 types)
- Plus d'items (30-50 items)
- Plus de dialogues (campagne complète)
- Plus de locations (5-10 locations)

**Priorité Moyenne :**
- Plus de scénarios de combat
- Plus de rings (combo matérialisation/canalisation)
- Plus d'effets de mana
- Assets visuels (icônes, sprites)
- Assets audio (musiques, SFX)

### Architecture Robuste

**Points forts :**
✅ Séparation claire des responsabilités  
✅ Event-driven (EventBus)  
✅ Data-driven (JSON)  
✅ Validation au démarrage  
✅ Patterns éprouvés (Command, State Machine)  
✅ Logging & debug intégrés  
✅ Modularité (chaque système indépendant)  

**Axes d'amélioration :**
⚠️ Tests unitaires (absents)  
⚠️ Documentation code (comments)  
⚠️ Performance profiling  
⚠️ Memory management (pooling)  
⚠️ Error recovery (crash handling)  

---

**Fichier créé :** `/mnt/user-data/outputs/ARCHITECTURE_PART3.md`

**Navigation :**
- [← PART1 : UI, Dialogues, World Map](./ARCHITECTURE_PART1.md)
- [← PART2 : Combat & Modules](./ARCHITECTURE_PART2.md)
- [PART3 : Formats JSON & Systèmes Finaux] (ce fichier)

---

**🎉 DOCUMENTATION COMPLÈTE !**

Le projet **Tactical RPG Duos** est maintenant entièrement documenté sur 3 parties couvrant :
- 22 systèmes principaux
- 40+ classes et modules
- 15+ formats de données JSON
- 100+ fonctions critiques

Cette documentation constitue une base solide pour le développement, la maintenance et l'extension du projet.
