# ARCHITECTURE DU PROJET - PARTIE 1 : UI, DIALOGUES & WORLD MAP

## 📋 Vue d'ensemble

**Type de projet** : Tactical RPG 3D (Godot 4.x)  
**Langage principal** : GDScript  
**Architecture** : Event-driven avec systèmes découplés

---

## 🎯 Systèmes analysés dans cette partie

1. **Menu Principal** (`scenes/menu/`)
2. **Système de Dialogue** (`scenes/dialogue/`, `scenes/ui/dialogue_box`)
3. **World Map** (`scenes/world/`)
4. **Interface de Combat** (`scenes/battle/battle_3d.tscn`)
5. **Narrative/Intro** (`scenes/narrative/`)

---

## 🏗️ STRUCTURE DES DOSSIERS

```
scenes/
├── battle/              # Scènes de combat 3D
│   ├── battle_3d.tscn          # Scène principale du combat
│   └── damage_number.tscn       # Affichage des dégâts
├── dialogue/            # Système de dialogue
│   ├── bark_label.gd/tscn      # Messages courts flottants
│   ├── bark_system.gd          # Gestionnaire de barks
│   ├── dialogue_data.gd        # Format de données dialogues
│   └── effects/                # Effets BBCode (shake, wave, rainbow)
├── menu/                # Menu principal
│   ├── main_menu.gd/tscn
├── narrative/           # Scènes narratives
│   └── intro_dialogue.gd/tscn
├── team/               # Gestion d'équipe
│   └── team_roster_ui.tscn
├── ui/                 # Composants UI réutilisables
│   └── dialogue_box.gd/tscn    # Boîte de dialogue principale
└── world/              # World map
    ├── world_map.gd/tscn
    ├── world_map_location.gd
    ├── world_map_connection.gd
    └── world_map_player.gd
```

---

## 🔧 SYSTÈMES PRINCIPAUX

### 1. EVENT BUS (EventBus)

**Architecture centrale** : Communication événementielle découplée

#### Signaux utilisés
```gdscript
# Gestion de scènes
EventBus.change_scene(scene_id)

# Notifications
EventBus.notify(message, type)  # type: "info", "warning", "error"
EventBus.notification_posted.emit(message, type)

# Jeu
EventBus.game_started.emit()
EventBus.game_loaded.emit(save_name)
EventBus.game_paused.emit(paused)
EventBus.quit_game_requested.emit()

# World Map
EventBus.location_discovered.emit(location_id)

# Custom events
EventBus.emit_event(event_type, [event_data])
```

#### Pattern de connexion sécurisée
```gdscript
EventBus.safe_connect("signal_name", callback)
EventBus.disconnect_all(self)  # Dans _exit_tree()
```

---

### 2. SCENE LOADER (SceneLoader)

**Gestion des transitions** entre scènes avec système de registre

#### SceneRegistry (SceneRegistry.SceneID)
```gdscript
enum SceneID {
    MAIN_MENU,
    WORLD_MAP,
    BATTLE,
    OPTIONS_MENU,
    CREDITS,
    # ... autres scènes
}
```

#### Utilisation
```gdscript
EventBus.change_scene(SceneRegistry.SceneID.WORLD_MAP)
```

#### Auto-connexion des signaux
Les scènes peuvent implémenter :
```gdscript
func _get_signal_connections() -> Array:
    return [
        {
            "source": button,
            "signal_name": "pressed",
            "target": self,
            "method": "_on_button_pressed"
        }
    ]
```

---

### 3. SYSTÈME DE DIALOGUE

#### DialogueData (Resource)
Format de données pour les dialogues

**Structure d'une ligne** :
```gdscript
{
    "speaker": "Nom du personnage",
    "speaker_key": "clé_i18n",  # Pour i18n
    "text": "Texte affiché",
    "text_key": "dialogue.key.01",
    "portrait": "res://portraits/knight.png",
    "emotion": "happy",  # happy, sad, angry, neutral
    "voice_sfx": "res://sfx/voice_male.ogg",
    "speed": 50.0,  # Override vitesse
    "auto_advance": false,  # ⚠️ false par défaut
    "auto_delay": 2.0,
    "effects": ["shake", "rainbow"],  # Effets BBCode
    "choices": [],  # Pour choix multiples
    "event": {},  # Événement à déclencher
}
```

#### Effets BBCode disponibles
- `[shake rate=20 level=5]` - Tremblement
- `[wave amp=50 freq=2]` - Ondulation
- `[rainbow freq=0.2]` - Arc-en-ciel

#### DialogueBox (Control)
**Composant UI réutilisable**

**Signaux** :
```gdscript
text_reveal_started
text_reveal_completed
choice_selected(index)
```

**Méthodes publiques** :
```gdscript
show_dialogue_box()
hide_dialogue_box()
display_line(line: Dictionary)
display_choices(choices: Array)
complete_text()  # Skip typewriter
```

**Input** :
- Clic gauche / Espace / Entrée : Avancer
- Si texte en révélation : complète le texte
- Sinon : passe à la ligne suivante
- Navigation choix : Haut/Bas

#### Dialogue_Manager (Singleton)
**Gestionnaire global des dialogues**

```gdscript
Dialogue_Manager.start_dialogue(dialogue_data, dialogue_box)
Dialogue_Manager.advance_dialogue()
Dialogue_Manager.select_choice(index)

# Signaux
Dialogue_Manager.dialogue_ended
```

#### BarkSystem (Node2D)
**Messages courts flottants** (non-bloquants)

```gdscript
bark_system.show_bark(speaker, text, world_position, duration)
bark_system.show_bark_3d(speaker, text, world_pos_3d, camera, duration)
```

#### Chargement des données
```gdscript
# JSON
var dialogue = DialogueData.from_json("res://data/dialogues/intro.json")

# CSV
var dialogue = DialogueData.from_csv("res://data/dialogues/lines.csv", "dialogue_id")

# Quick creation
var dialogue = DialogueData.quick_dialogue("test_id", [
    ["Knight", "Hello!"],
    ["Wizard", "Welcome!"]
])
```

---

### 4. WORLD MAP

#### Architecture
- **WorldMap** : Nœud principal (Node2D)
- **WorldMapLocation** : Points d'intérêt
- **WorldMapConnection** : Lignes de connexion entre locations
- **WorldMapPlayer** : Sprite du joueur

#### WorldMapLocation (Node2D)
**Représente une location interactive**

**Propriétés** :
```gdscript
location_id: String
location_name: String
is_unlocked: bool
```

**Signaux** :
```gdscript
clicked(location)
hovered(location)
unhovered(location)
```

**Données attendues** :
```gdscript
{
    "id": "village_north",
    "name": "Village du Nord",
    "position": {"x": 400, "y": 300},  # ou Vector2i
    "icon": "res://icons/town.png",  # Optionnel, rond jaune par défaut
    "scale": 1.5,
    "connections": ["castle_central"],
    "unlocked_at_step": 0
}
```

#### WorldMapConnection (Node2D)
**Lignes pointillées entre locations avec état**

**États** :
```gdscript
enum ConnectionState {
    UNLOCKED,   # Accessible
    LOCKED,     # Visible mais bloqué (+ croix rouge)
    HIDDEN      # Invisible
}
```

**Configuration globale** (variables de classe statiques) :
```gdscript
WorldMapConnection.default_line_width = 4.0
WorldMapConnection.default_dash_length = 15.0
WorldMapConnection.default_color_unlocked = Color(0.7, 0.7, 0.7, 0.8)
WorldMapConnection.default_color_locked = Color(0.3, 0.3, 0.3, 0.4)
```

**API publique** :
```gdscript
world_map.unlock_connection(from_id, to_id)
world_map.lock_connection(from_id, to_id)
world_map.hide_connection(from_id, to_id)
world_map.reveal_connection(from_id, to_id, locked=true)
```

#### WorldMapPlayer (Node2D)
**Sprite du joueur avec animation bounce**

**Configuration** :
```gdscript
bounce_speed: 1.5
bounce_amount: 10.0
bounce_offset: 75.0  # Offset vertical permanent
move_speed: 300.0
```

**Méthodes** :
```gdscript
move_to_location(target_location)  # Avec animation
set_location(location)  # Sans animation

# Signaux
movement_started
movement_completed
```

#### Actions sur les locations
Les locations peuvent avoir des **actions** définies dans les données :

**Types d'actions** :
- `"battle"` : Lance un combat
- `"dialogue"` : Démarre un dialogue
- `"exploration"` : Exploration
- `"building"` : Entrée dans un bâtiment
- `"shop"` : Magasin
- `"quest_board"` : Panneau de quêtes
- `"team_management"` : Gestion d'équipe
- `"custom"` : Événement personnalisé

**Format d'action** :
```json
{
    "id": "action_battle_01",
    "type": "battle",
    "label": "⚔️ Combat d'entraînement",
    "icon": "res://icons/battle.png",
    "unlocked_at_step": 0,
    "battle_id": "training_battle_01"
}
```

#### Chargement des données
```gdscript
# WorldMapDataLoader (singleton supposé)
var world_data = WorldMapDataLoader.load_world_map_data("world_map_data", true)
var location_data = WorldMapDataLoader.load_location_data(location_id)
```

**Structure world_map_data** :
```gdscript
{
    "name": "Monde Principal",
    "locations": [...],  # Array de location data
    "connections_visual": {
        "width": 4.0,
        "dash_length": 15.0,
        "color": {"r": 0.7, "g": 0.7, "b": 0.7, "a": 0.8},
        "color_locked": {"r": 0.3, "g": 0.3, "b": 0.3, "a": 0.4}
    },
    "connection_states": {
        "village_to_castle": "unlocked",
        "castle_to_port": "locked"
    },
    "player": {
        "start_location": "village_north",
        "icon": "res://sprites/player_icon.png",
        "scale": 1.0,
        "bounce_speed": 1.5
    }
}
```

---

### 5. MENU PRINCIPAL

#### MainMenu (Control)
**Point d'entrée du jeu**

**Boutons** :
- Nouvelle Partie → `EventBus.change_scene(WORLD_MAP)`
- Continuer → Charge dernière sauvegarde
- Options → (à implémenter)
- Crédits → (à implémenter)
- Quitter → `EventBus.quit_game_requested.emit()`

**Pattern** : Auto-connexion via `_get_signal_connections()`

---

### 6. INTRO DIALOGUE / NARRATIVE

#### IntroDialogue (Control)
**Séquence narrative pilotée par données JSON**

#### campaign_start.json
**Structure de démarrage de campagne** :

```json
{
    "start_sequence": [
        {
            "type": "dialogue",
            "dialogue_id": "intro_001",
            "blocking": true
        },
        {
            "type": "notification",
            "message": "Bienvenue !",
            "duration": 2.0
        },
        {
            "type": "unlock_location",
            "location": "village_north"
        },
        {
            "type": "transition",
            "target": "world_map",
            "fade_duration": 1.0
        }
    ]
}
```

**Types d'étapes** :
- `dialogue` : Affiche un dialogue
- `notification` : Notification temporaire
- `unlock_location` : Déverrouille une location
- `transition` : Change de scène

---

### 7. BATTLE DATA

#### BattleDataManager (Singleton supposé)
**Stockage des données de combat**

```gdscript
BattleDataManager.set_battle_data(battle_data)
```

**Format battle_data.json** :
```json
{
    "id": "training_battle_01",
    "name": "Combat d'entraînement",
    "grid_size": {"width": 10, "height": 8},
    "player_units": [
        {
            "unit_id": "knight_01",
            "position": [1, 4],
            "hp": 100,
            "stats": {"atk": 15, "def": 10}
        }
    ],
    "enemy_units": [...],
    "terrain_obstacles": [
        {
            "type": "rock",
            "position": [5, 5]
        }
    ]
}
```

**⚠️ Conversion de types nécessaire** :
- JSON `position: [x, y]` → `Vector2i(x, y)`
- JSON `grid_size: {width, height}` → `Vector2i(width, height)`
- JSON floats → int pour HP/stats

**Fonction helper** dans WorldMap :
```gdscript
_convert_battle_json_to_godot_types(battle_data: Dictionary)
```

---

## 🎨 CONVENTIONS DE CODE

### Nommage
- **Scènes** : snake_case (`world_map.tscn`)
- **Classes** : PascalCase (`WorldMapLocation`)
- **Variables** : snake_case (`location_id`)
- **Constantes** : UPPER_SNAKE_CASE (`MAX_LOCATIONS`)
- **Signaux** : snake_case (`location_discovered`)

### Organisation des fichiers
- **1 classe = 1 fichier**
- Script et scène portent le même nom
- Scripts dans `scenes/` à côté de leur .tscn

### Structure d'un script
```gdscript
extends Node2D
## Documentation de la classe
class_name ClassName

# ============================================================================
# SIGNAUX
# ============================================================================
signal signal_name()

# ============================================================================
# PROPRIÉTÉS / CONFIGURATION
# ============================================================================
@export var property: int = 0
var internal_var: String = ""

# ============================================================================
# RÉFÉRENCES
# ============================================================================
@onready var node_ref: Node = $NodePath

# ============================================================================
# INITIALISATION
# ============================================================================
func _ready() -> void:
    pass

# ============================================================================
# MÉTHODES PUBLIQUES
# ============================================================================
func public_method() -> void:
    pass

# ============================================================================
# MÉTHODES PRIVÉES
# ============================================================================
func _private_method() -> void:
    pass

# ============================================================================
# NETTOYAGE
# ============================================================================
func _exit_tree() -> void:
    EventBus.disconnect_all(self)
```

---

## 🔗 DÉPENDANCES ENTRE MODULES

### Hiérarchie de dépendances
```
EventBus (core)
    ↓
SceneLoader, SceneRegistry
    ↓
GameManager, Dialogue_Manager
    ↓
WorldMap, DialogueBox, MainMenu
    ↓
WorldMapLocation, DialogueData
```

### Singletons/Autoloads supposés
- `EventBus` : Bus d'événements global
- `SceneLoader` : Chargement de scènes
- `SceneRegistry` : Registre des scènes
- `GameManager` : Gestion état du jeu
- `Dialogue_Manager` : Gestionnaire de dialogues
- `BattleDataManager` : Données de combat
- `WorldMapDataLoader` : Chargeur de données world map
- `DialogueDataLoader` : Chargeur de dialogues
- `JSONDataLoader` : Chargeur JSON générique

---

## 📦 FORMATS DE DONNÉES

### Localisation (i18n)
**Système prévu** :
- Clés `speaker_key` et `text_key` dans DialogueData
- Fonction `tr(key)` pour traduction
- Fallback sur texte direct si clé absente

### JSON vs CSV
- **JSON** : Dialogues complexes, données de combat, world map
- **CSV** : Dialogues simples (lignes séquentielles)

---

## 🐛 POINTS D'ATTENTION POUR LE DEBUG

### DialogueBox
- **Auto-advance désactivé par défaut** : `"auto_advance": false`
- Indicateur de continuation visible seulement quand texte complètement révélé
- Input géré dans `_input()`, pas dans les boutons

### WorldMap
- Les locations créent un **rond jaune par défaut** si pas d'icône
- Player sprite placé avec **bounce_offset** de 75px au-dessus
- Connexions créées une seule fois par paire (évite doublons)
- Area2D avec `collision_layer = 2` pour clics

### Conversions de types
- JSON arrays → Vector2i nécessite conversion manuelle
- Floats JSON → int pour stats

### EventBus
- **Toujours déconnecter** dans `_exit_tree()`
- Utiliser `safe_connect()` pour éviter doublons

---

## ✅ CHECKLIST : Ce dont j'ai besoin pour débugger/créer

### Pour débugger un dialogue
- [ ] DialogueData (format JSON ou code)
- [ ] ID du dialogue
- [ ] Scène avec DialogueBox
- [ ] Connexion à Dialogue_Manager

### Pour débugger la World Map
- [ ] world_map_data.json
- [ ] location_data JSON pour chaque location
- [ ] Liste des connexions attendues
- [ ] Step de progression actuel

### Pour débugger un combat
- [ ] battle_data JSON
- [ ] Liste des unités (player + enemy)
- [ ] Grid size
- [ ] Obstacles terrain

### Informations générales toujours utiles
- [ ] Version de Godot
- [ ] Liste des autoloads/singletons actifs
- [ ] Structure complète des dossiers `data/`
- [ ] Stacktrace d'erreur complète
- [ ] État du GameManager (si existant)

---

## 📝 NOTES POUR LA SUITE

**Systèmes non couverts dans cette partie** :
- Système de combat tactique complet
- Gestion de l'équipe (team roster)
- Système d'inventaire
- Gestion des stats/classes des unités
- Système de sauvegarde
- Audio/Musique
- Effets visuels (VFX)

**Attente des parties suivantes** pour compléter l'architecture globale.

---

## 🔍 QUESTIONS POUR CLARIFICATIONS FUTURES

1. **GameManager** : Structure complète ? État global ?
2. **Sauvegarde** : Format ? Quoi sauvegarder ?
3. **Combat** : Flow complet ? Turn-based ? Actions disponibles ?
4. **Stats** : Système de classes ? Progression ?
5. **Inventaire** : Items équipables ? Consommables ?

---

*Document généré pour la Partie 1 - À compléter avec les parties suivantes*
