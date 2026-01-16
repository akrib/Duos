# 🚀 QUICKSTART - Système de Chargement de Scènes

## ⚡ Installation Express (5 minutes)

### 1️⃣ Copier les fichiers

```
tactical-rpg-duos/
├── scripts/
│   └── core/
│       ├── event_bus.gd          ← Copier ici
│       ├── game_manager.gd       ← Copier ici
│       ├── scene_loader.gd       ← Copier ici
│       └── scene_registry.gd     ← Copier ici
│
└── project.godot                 ← Copier/fusionner ici
```

### 2️⃣ Configurer les Autoloads

**Dans Godot** : `Project → Project Settings → Autoload`

| Ordre | Nom | Path | Activé |
|-------|-----|------|--------|
| 1 | EventBus | `res://scripts/core/event_bus.gd` | ✅ |
| 2 | GameManager | `res://scripts/core/game_manager.gd` | ✅ |

### 3️⃣ Éditer le SceneRegistry

Ouvrez `scene_registry.gd` et ajoutez vos scènes :

```gdscript
const SCENE_PATHS: Dictionary = {
    SceneID.MAIN_MENU: "res://scenes/menus/main_menu.tscn",
    SceneID.BATTLE: "res://scenes/battle/battle.tscn",
    # ... vos scènes ici
}
```

### 4️⃣ Créer votre première scène

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

## ✅ Test Rapide

Dans n'importe quel script, testez :

```gdscript
func _ready():
    print(EventBus)        # Doit afficher l'objet EventBus
    print(GameManager)     # Doit afficher l'objet GameManager
    
    # Charger une scène
    EventBus.change_scene(SceneRegistry.SceneID.MAIN_MENU)
```

---

## 📚 Documentation Complète

- **README.md** : Vue d'ensemble du système
- **GUIDE_UTILISATION.md** : Guide détaillé avec exemples
- **DIAGRAMMES.md** : Flux et architecture visuels

---

## 🔥 Commandes Essentielles

```gdscript
# Changer de scène
EventBus.change_scene(SceneRegistry.SceneID.BATTLE)

# Émettre un événement
EventBus.duo_formed.emit(unit_a, unit_b)

# Écouter un événement
EventBus.safe_connect("unit_attacked", _on_unit_attacked)

# Notification
EventBus.notify("Combat terminé !", "success")

# Recharger la scène
GameManager.reload_current_scene()
```

---

## 🎯 Exemple Complet : Menu Principal

**main_menu.gd**
```gdscript
extends Control

@onready var start_btn: Button = $VBoxContainer/StartButton
@onready var options_btn: Button = $VBoxContainer/OptionsButton
@onready var quit_btn: Button = $VBoxContainer/QuitButton

func _get_signal_connections() -> Array:
    return [
        {"source": start_btn, "signal_name": "pressed", "target": self, "method": "_start"},
        {"source": options_btn, "signal_name": "pressed", "target": self, "method": "_options"},
        {"source": quit_btn, "signal_name": "pressed", "target": self, "method": "_quit"},
    ]

func _start() -> void:
    EventBus.game_started.emit()
    EventBus.change_scene(SceneRegistry.SceneID.WORLD_MAP)

func _options() -> void:
    EventBus.change_scene(SceneRegistry.SceneID.OPTIONS_MENU)

func _quit() -> void:
    EventBus.quit_game_requested.emit()
```

---

## 🎮 Intégration avec votre Tactical RPG

### Formation de Duos

```gdscript
func form_duo(unit_a: Unit, unit_b: Unit) -> void:
    if _are_adjacent(unit_a, unit_b):
        # Logique locale
        current_duo = [unit_a, unit_b]
        
        # Notifier le système
        EventBus.form_duo(unit_a, unit_b)
        
        # Points divins (Astraeon = Stabilité)
        EventBus.add_divine_points("Astraeon", 1)
```

### Attaque en Duo

```gdscript
func duo_attack(duo: Array, target: Unit, damage: int) -> void:
    target.take_damage(damage)
    
    # Notifier
    EventBus.attack(duo[0], target, damage)
    
    # Menace
    EventBus.threat_level_changed.emit(duo, 1.0)
    
    # Points divins
    EventBus.add_divine_points("Astraeon", 2)
```

### Last Man Stand

```gdscript
func last_man_stand(unit: Unit) -> void:
    var damage = unit.calculate_explosion_damage()
    
    # Explosion
    for enemy in get_adjacent_enemies(unit):
        enemy.take_damage(damage)
        EventBus.attack(unit, enemy, damage)
    
    # Points divins (Chaos)
    EventBus.add_divine_points("Kharvûl", 3)
```

---

## 🐛 Problèmes Courants

### ❌ "EventBus n'existe pas"
→ Vérifiez que l'autoload est bien configuré

### ❌ "Scène introuvable"
→ Vérifiez le chemin dans `SceneRegistry.SCENE_PATHS`

### ❌ "Signal non connecté"
→ Vérifiez que `_get_signal_connections()` retourne un Array valide

### ❌ "Écran noir après transition"
→ Activez `scene_loader.debug_mode = true` pour voir les logs

---

## 🎉 C'est Parti !

Vous êtes maintenant prêt à développer votre Tactical RPG avec un système de chargement :

✅ **Totalement découplé**
✅ **Auto-connexion des signaux**
✅ **Communication via EventBus**
✅ **Scènes indépendantes et interchangeables**

**Bon développement ! 🎮**
