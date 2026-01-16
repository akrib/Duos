# 🎮 Tactical RPG en Duos - Système de Chargement Modulaire

## 📖 Vue d'ensemble

Système de chargement de scènes **totalement découplé** pour Godot 4.5, conçu pour un Tactical RPG avec mécaniques de duos. Ce système permet :

✅ **Chargement asynchrone** avec transitions
✅ **Auto-connexion dynamique** des signaux
✅ **Communication découplée** via EventBus
✅ **Scènes 100% indépendantes** et interchangeables
✅ **Registre centralisé** de toutes les scènes

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────┐
│                      AUTOLOADS                           │
│  ┌─────────────┐              ┌─────────────┐          │
│  │  EventBus   │◄────────────►│ GameManager │          │
│  │  (Global)   │              │  (Global)   │          │
│  └─────────────┘              └──────┬──────┘          │
│                                       │                  │
│                         ┌─────────────▼──────────┐      │
│                         │    SceneLoader         │      │
│                         │  (Chargement async)    │      │
│                         └────────────────────────┘      │
│                                       │                  │
│                         ┌─────────────▼──────────┐      │
│                         │   SceneRegistry        │      │
│                         │  (Catalogue scènes)    │      │
│                         └────────────────────────┘      │
└──────────────────────────────────────────────────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │    Scènes Individuelles    │
                    │  (Menu, Combat, Monde...)  │
                    └────────────────────────────┘
```

---

## 📂 Structure des Fichiers

```
tactical-rpg-duos/
│
├── scripts/
│   └── core/
│       ├── event_bus.gd          # Autoload - Communication globale
│       ├── game_manager.gd       # Autoload - Orchestrateur principal
│       ├── scene_loader.gd       # Chargeur de scènes asynchrone
│       └── scene_registry.gd     # Registre des scènes
│
├── scenes/
│   ├── menus/
│   │   ├── main_menu.tscn
│   │   ├── options_menu.tscn
│   │   └── pause_menu.tscn
│   │
│   ├── world/
│   │   ├── world_map.tscn
│   │   ├── town.tscn
│   │   └── castle.tscn
│   │
│   ├── battle/
│   │   ├── battle.tscn
│   │   ├── battle_preparation.tscn
│   │   └── battle_results.tscn
│   │
│   └── narrative/
│       ├── dialogue.tscn
│       └── cutscene.tscn
│
├── project.godot              # Configuration du projet
├── GUIDE_UTILISATION.md       # Guide complet (À LIRE)
└── README.md                  # Ce fichier
```

---

## 🚀 Quick Start

### 1. Installation

1. Copiez tous les fichiers dans votre projet Godot 4.5
2. Configurez les **Autoloads** dans `Project → Project Settings → Autoload` :
   - `EventBus` : `res://scripts/core/event_bus.gd` ✅
   - `GameManager` : `res://scripts/core/game_manager.gd` ✅

### 2. Configuration du registre

Éditez `scene_registry.gd` pour lister vos scènes :

```gdscript
const SCENE_PATHS: Dictionary = {
    SceneID.MAIN_MENU: "res://scenes/menus/main_menu.tscn",
    SceneID.BATTLE: "res://scenes/battle/battle.tscn",
    # ... ajoutez vos scènes
}
```

### 3. Utilisation dans vos scènes

```gdscript
extends Control

# Auto-connexion des signaux
func _get_signal_connections() -> Array:
    return [
        {
            "source": $PlayButton,
            "signal_name": "pressed",
            "target": self,
            "method": "_on_play_pressed"
        }
    ]

func _on_play_pressed() -> void:
    # Changer de scène via EventBus
    EventBus.change_scene(SceneRegistry.SceneID.WORLD_MAP)
```

---

## ✨ Fonctionnalités Principales

### 🔄 Chargement Asynchrone

```gdscript
# Chargement avec transition
GameManager.load_scene_by_id(SceneRegistry.SceneID.BATTLE)

# Chargement immédiat
GameManager.load_scene_by_id(SceneRegistry.SceneID.BATTLE, false)
```

### 🔌 Auto-Connexion des Signaux

Les scènes définissent leurs connexions de signaux, qui sont automatiquement établies et détruites par le `SceneLoader` :

```gdscript
func _get_signal_connections() -> Array:
    return [
        {"source": button, "signal_name": "pressed", "target": self, "method": "callback"}
    ]
```

### 📡 EventBus Global

Communication totalement découplée entre scènes :

```gdscript
# Émettre un événement
EventBus.duo_formed.emit(unit_a, unit_b)

# Écouter un événement
EventBus.safe_connect("duo_formed", _on_duo_formed)

func _on_duo_formed(unit_a, unit_b):
    print("Duo formé !")
```

### 📚 SceneRegistry

Catalogue centralisé avec métadonnées :

```gdscript
# Accès type-safe aux scènes
var path = SceneRegistry.get_scene_path(SceneRegistry.SceneID.BATTLE)

# Métadonnées
var metadata = SceneRegistry.get_scene_metadata(SceneRegistry.SceneID.BATTLE)
# { "category": "battle", "music": "res://...", "pausable": true }
```

---

## 📋 Signaux EventBus Disponibles

### Combat
- `battle_started(battle_data: Dictionary)`
- `battle_ended(results: Dictionary)`
- `duo_formed(unit_a: Node, unit_b: Node)`
- `duo_broken(unit_a: Node, unit_b: Node)`
- `unit_attacked(attacker: Node, target: Node, damage: int)`

### Statistiques
- `stats_updated(unit: Node, stat_name: String, value: float)`
- `threat_level_changed(duo: Array, new_threat: float)`
- `legend_gained(duo: Array, legend_type: String)`
- `mvp_awarded(unit: Node, battle_id: String)`

### Divinités (Système de Foi)
- `divine_points_gained(god_name: String, points: int)`
- `divine_threshold_reached(god_name: String, threshold: int)`

### Navigation
- `scene_change_requested(scene_id: int)`
- `return_to_menu_requested()`
- `quit_game_requested()`

### Système
- `game_paused(paused: bool)`
- `notification_posted(message: String, type: String)`

**Voir `event_bus.gd` pour la liste complète !**

---

## 🎯 Exemples Concrets

### Exemple 1 : Menu Principal

```gdscript
extends Control

func _get_signal_connections() -> Array:
    return [
        {"source": $StartButton, "signal_name": "pressed", "target": self, "method": "_start_game"}
    ]

func _start_game() -> void:
    EventBus.game_started.emit()
    EventBus.change_scene(SceneRegistry.SceneID.WORLD_MAP)
```

### Exemple 2 : Combat - Formation de Duo

```gdscript
extends Node2D

func form_duo(unit_a: Unit, unit_b: Unit) -> void:
    if _are_adjacent(unit_a, unit_b):
        # Logique locale
        var duo = [unit_a, unit_b]
        
        # Notifier le système global
        EventBus.form_duo(unit_a, unit_b)
        
        # Points divins pour Astraeon (Stabilité)
        EventBus.add_divine_points("Astraeon", 1)
```

### Exemple 3 : UI - Notifications

```gdscript
extends Control

func _ready() -> void:
    EventBus.safe_connect("notification_posted", _show_notification)

func _show_notification(message: String, type: String) -> void:
    $Label.text = message
    # Animation...
```

---

## 🛠️ Best Practices

### ✅ À FAIRE

1. **Toujours utiliser SceneRegistry** pour les chemins de scènes
2. **Communiquer via EventBus** plutôt que `get_node()`
3. **Implémenter `_get_signal_connections()`** dans toutes vos scènes
4. **Se déconnecter proprement** dans `_exit_tree()`

### ❌ À ÉVITER

1. ~~Hardcoder les chemins de scènes~~
2. ~~Référencer directement d'autres scènes~~
3. ~~Connecter manuellement des signaux dans l'éditeur~~
4. ~~Oublier de déconnecter les signaux~~

---

## 🐛 Debug

### Lister les connexions actives

```gdscript
# Dans le jeu (mode debug)
EventBus.debug_list_connections()
```

### Vérifier l'état du GameManager

```gdscript
print("Scène actuelle : ", GameManager.current_scene_id)
print("En chargement : ", GameManager.is_loading())
```

### Activer les logs

```gdscript
# Dans game_manager.gd
scene_loader.debug_mode = true
```

---

## 📚 Documentation Complète

👉 **Lisez le [GUIDE_UTILISATION.md](GUIDE_UTILISATION.md)** pour :
- Installation détaillée
- Tutoriels pas à pas
- Exemples complets
- Référence API

---

## 🎮 Intégration avec votre GDD

Ce système est conçu pour votre Tactical RPG et intègre nativement :

- ✅ **Système de duos** (signaux dédiés)
- ✅ **Statistiques persistantes** (via EventBus)
- ✅ **Système divin** (Astraeon, Kharvûl, Myrr, Etrius)
- ✅ **Menace & Légende** (tracking automatique)
- ✅ **Narration systémique** (événements découplés)

---

## 🤝 Contribution

Pour ajouter une nouvelle scène :

1. Créez votre `.tscn` dans `scenes/`
2. Ajoutez-la au `SceneRegistry`
3. Implémentez `_get_signal_connections()` si nécessaire
4. Utilisez `EventBus` pour communiquer

---

## 📝 License

Ce système est fourni pour votre projet Tactical RPG. Libre d'utilisation et de modification.

---

## 🎉 Résultat

**Vous avez maintenant un système de chargement :**

- 🚀 **Performant** (asynchrone)
- 🔌 **Découplé** (EventBus)
- 🧩 **Modulaire** (scènes indépendantes)
- 🔧 **Maintenable** (auto-connexion)
- 📦 **Scalable** (ajout facile de nouvelles scènes)

**Bon développement ! 🎮**
