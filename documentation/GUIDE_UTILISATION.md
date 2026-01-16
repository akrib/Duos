# 🎮 Guide d'Utilisation - Système de Chargement de Scènes

## 📋 Table des Matières

1. [Architecture Générale](#architecture-générale)
2. [Installation](#installation)
3. [Utilisation Basique](#utilisation-basique)
4. [Auto-Connexion des Signaux](#auto-connexion-des-signaux)
5. [EventBus - Communication Découplée](#eventbus---communication-découplée)
6. [Exemples Pratiques](#exemples-pratiques)
7. [Best Practices](#best-practices)

---

## 🏗️ Architecture Générale

Votre système repose sur 4 composants principaux :

```
┌─────────────────┐
│  GameManager    │  ← Autoload principal (orchestre tout)
│  (Autoload)     │
└────────┬────────┘
         │
         ├─→ ┌──────────────┐
         │   │ SceneLoader  │  ← Gère le chargement asynchrone
         │   └──────────────┘
         │
         ├─→ ┌──────────────────┐
         │   │ SceneRegistry    │  ← Catalogue des scènes
         │   └──────────────────┘
         │
         └─→ ┌──────────────┐
             │  EventBus    │  ← Communication globale (Autoload)
             │  (Autoload)  │
             └──────────────┘
```

---

## 📦 Installation

### 1. Structure de dossiers recommandée

```
res://
├── scripts/
│   ├── core/
│   │   ├── game_manager.gd        (Autoload)
│   │   ├── scene_loader.gd
│   │   ├── scene_registry.gd
│   │   └── event_bus.gd           (Autoload)
│   │
│   ├── ui/
│   ├── combat/
│   └── world/
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
└── project.godot
```

### 2. Configuration des Autoloads

Dans **Project Settings → Autoload** :

1. **EventBus** : `res://scripts/core/event_bus.gd` ✅ Activé
2. **GameManager** : `res://scripts/core/game_manager.gd` ✅ Activé

⚠️ **Ordre important** : EventBus AVANT GameManager

### 3. Mise à jour du SceneRegistry

Éditez `scene_registry.gd` pour correspondre à votre structure :

```gdscript
const SCENE_PATHS: Dictionary = {
    SceneID.MAIN_MENU: "res://scenes/menus/main_menu.tscn",
    SceneID.WORLD_MAP: "res://scenes/world/world_map.tscn",
    # ... etc
}
```

---

## 🚀 Utilisation Basique

### Charger une scène

```gdscript
# Méthode 1 : Via SceneID (recommandé)
GameManager.load_scene_by_id(SceneRegistry.SceneID.BATTLE)

# Méthode 2 : Via EventBus (découplé)
EventBus.change_scene(SceneRegistry.SceneID.WORLD_MAP)

# Méthode 3 : Par chemin direct (rare)
GameManager.load_scene_by_path("res://scenes/custom/special.tscn")
```

### Transitions

```gdscript
# Avec transition (fade par défaut)
GameManager.load_scene_by_id(SceneRegistry.SceneID.BATTLE, true)

# Sans transition (immédiat)
GameManager.load_scene_by_id(SceneRegistry.SceneID.BATTLE, false)
```

### Recharger la scène actuelle

```gdscript
GameManager.reload_current_scene()
```

---

## 🔌 Auto-Connexion des Signaux

### Comment ça marche ?

Chaque scène peut définir une méthode `_get_signal_connections()` qui retourne une liste de connexions à établir automatiquement.

### Template pour vos scènes

```gdscript
extends Control

@onready var play_button: Button = $PlayButton
@onready var quit_button: Button = $QuitButton

## Auto-connexion : définir les signaux à connecter
func _get_signal_connections() -> Array:
    if not is_node_ready():
        return []
    
    return [
        {
            "source": play_button,
            "signal_name": "pressed",
            "target": self,
            "method": "_on_play_pressed"
        },
        {
            "source": quit_button,
            "signal_name": "pressed",
            "target": self,
            "method": "_on_quit_pressed"
        },
    ]

func _on_play_pressed() -> void:
    EventBus.change_scene(SceneRegistry.SceneID.WORLD_MAP)

func _on_quit_pressed() -> void:
    EventBus.quit_game_requested.emit()
```

### Avantages

✅ **Aucune connexion manuelle dans l'éditeur**
✅ **Code lisible et centralisé**
✅ **Déconnexion automatique au changement de scène**
✅ **Indépendance totale des scènes**

---

## 📡 EventBus - Communication Découplée

### Principe

L'EventBus permet à **n'importe quelle scène** de communiquer avec **n'importe quelle autre** sans avoir de référence directe.

### Émission d'événements

```gdscript
# Dans votre scène de combat
extends Node2D

func _on_unit_attacked(attacker: Node, target: Node, damage: int) -> void:
    # Émettre un événement global
    EventBus.unit_attacked.emit(attacker, target, damage)
    
    # Ou via helper
    EventBus.attack(attacker, target, damage)
```

### Écoute d'événements

```gdscript
# Dans votre UI de statistiques
extends Control

func _ready() -> void:
    # S'abonner aux événements
    EventBus.safe_connect("unit_attacked", _on_unit_attacked)
    EventBus.safe_connect("battle_ended", _on_battle_ended)

func _on_unit_attacked(attacker: Node, target: Node, damage: int) -> void:
    print("Dégâts infligés : ", damage)

func _on_battle_ended(results: Dictionary) -> void:
    print("Combat terminé !")

func _exit_tree() -> void:
    # Déconnexion automatique, mais vous pouvez aussi le faire manuellement
    EventBus.disconnect_all(self)
```

### Signaux disponibles

Voir `event_bus.gd` pour la liste complète. Exemples :

- **Combat** : `battle_started`, `unit_attacked`, `duo_formed`, `duo_broken`
- **Statistiques** : `stats_updated`, `threat_level_changed`, `legend_gained`
- **Divinités** : `divine_points_gained`, `divine_threshold_reached`
- **Monde** : `dialogue_started`, `cutscene_ended`, `location_discovered`
- **Système** : `game_paused`, `scene_change_requested`, `quit_game_requested`

---

## 🎯 Exemples Pratiques

### Exemple 1 : Menu Principal

```gdscript
extends Control

func _get_signal_connections() -> Array:
    return [
        {"source": $StartButton, "signal_name": "pressed", "target": self, "method": "_on_start"},
        {"source": $OptionsButton, "signal_name": "pressed", "target": self, "method": "_on_options"},
    ]

func _on_start() -> void:
    EventBus.game_started.emit()
    EventBus.change_scene(SceneRegistry.SceneID.WORLD_MAP)

func _on_options() -> void:
    EventBus.change_scene(SceneRegistry.SceneID.OPTIONS_MENU)
```

### Exemple 2 : Système de Combat

```gdscript
extends Node2D

var current_duo: Array = []

func form_duo(unit_a: Unit, unit_b: Unit) -> void:
    current_duo = [unit_a, unit_b]
    
    # Notifier le système global
    EventBus.duo_formed.emit(unit_a, unit_b)
    
    # Mettre à jour les stats
    EventBus.stats_updated.emit(unit_a, "in_duo", true)
    EventBus.stats_updated.emit(unit_b, "in_duo", true)

func attack(target: Unit, damage: int) -> void:
    if current_duo.is_empty():
        push_error("Impossible d'attaquer sans duo !")
        return
    
    # Attaque
    target.take_damage(damage)
    
    # Notifier
    EventBus.unit_attacked.emit(current_duo[0], target, damage)
    
    # Incrémenter menace
    EventBus.threat_level_changed.emit(current_duo, 1.0)
```

### Exemple 3 : UI de Notifications

```gdscript
extends Control

@onready var notification_label: Label = $NotificationLabel

func _ready() -> void:
    EventBus.safe_connect("notification_posted", _show_notification)

func _show_notification(message: String, type: String) -> void:
    notification_label.text = message
    notification_label.modulate = _get_color_for_type(type)
    
    # Animer
    var tween = create_tween()
    tween.tween_property(notification_label, "modulate:a", 1.0, 0.3)
    tween.tween_interval(2.0)
    tween.tween_property(notification_label, "modulate:a", 0.0, 0.3)

func _get_color_for_type(type: String) -> Color:
    match type:
        "success": return Color.GREEN
        "error": return Color.RED
        "warning": return Color.YELLOW
        _: return Color.WHITE
```

---

## ✅ Best Practices

### 1. Toujours utiliser SceneRegistry

❌ **Mauvais** :
```gdscript
GameManager.load_scene_by_path("res://scenes/battle/battle.tscn")
```

✅ **Bon** :
```gdscript
GameManager.load_scene_by_id(SceneRegistry.SceneID.BATTLE)
```

### 2. Préférer EventBus pour la communication

❌ **Mauvais** (couplage fort) :
```gdscript
# Dans SceneA
var scene_b = get_node("/root/SceneB")
scene_b.do_something()
```

✅ **Bon** (découplage) :
```gdscript
# Dans SceneA
EventBus.something_happened.emit()

# Dans SceneB
func _ready():
    EventBus.safe_connect("something_happened", _on_something_happened)
```

### 3. Implémenter `_get_signal_connections()` partout

✅ Permet l'auto-connexion
✅ Centralise la logique des signaux
✅ Facilite la maintenance

### 4. Toujours se déconnecter proprement

```gdscript
func _exit_tree() -> void:
    EventBus.disconnect_all(self)
```

### 5. Utiliser les helpers de l'EventBus

```gdscript
# Au lieu de :
EventBus.unit_attacked.emit(attacker, target, damage)

# Utilisez :
EventBus.attack(attacker, target, damage)
```

---

## 🐛 Debug

### Lister toutes les connexions actives

Dans le jeu, appuyez sur **Home** (en mode debug) :

```gdscript
EventBus.debug_list_connections()
```

### Vérifier l'état du GameManager

Appuyez sur **End** (en mode debug) :

```gdscript
# Affiche :
# - Scène actuelle
# - État de chargement
# - Progression
```

### Activer les logs du SceneLoader

```gdscript
# Dans game_manager.gd
scene_loader.debug_mode = true
```

---

## 🎓 Résumé

| Composant | Rôle | Usage |
|-----------|------|-------|
| **GameManager** | Orchestre tout | `GameManager.load_scene_by_id()` |
| **SceneLoader** | Charge les scènes | Automatique via GameManager |
| **SceneRegistry** | Catalogue les scènes | `SceneRegistry.SceneID.XXX` |
| **EventBus** | Communication globale | `EventBus.signal_name.emit()` |

---

## 🚀 Prochaines Étapes

1. Créer vos scènes dans `res://scenes/`
2. Enregistrer leurs chemins dans `SceneRegistry`
3. Implémenter `_get_signal_connections()` dans chaque scène
4. Utiliser `EventBus` pour la communication
5. Tester avec `GameManager.load_scene_by_id()`

**Votre système est maintenant 100% découplé et modulaire !** 🎉
