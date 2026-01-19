# Guide d'Intégration - Système de Combat Tactique 3D

## 🎯 Vue d'Ensemble

Votre système de combat tactique a été converti en 3D avec les fonctionnalités suivantes :

- ✅ **Terrain 3D** avec cases cubiques
- ✅ **Unités en billboard** (sprites toujours face à la caméra)
- ✅ **Rotation de caméra** avec les touches A/E
- ✅ **Raycasting 3D** pour les interactions
- ✅ **Coloration des cases** pour mouvement/attaque
- ✅ **Toutes les fonctionnalités gameplay** préservées

## 📁 Fichiers Créés

### Scènes
- `battle_3d.tscn` - Scène principale du combat en 3D

### Scripts
- `battle_map_manager_3d.gd` - Gestionnaire principal
- `terrain_module_3d.gd` - Génération du terrain 3D
- `battle_unit_3d.gd` - Unités avec sprites billboard
- `unit_manager_3d.gd` - Gestion des unités
- `movement_module_3d.gd` - Déplacements
- `action_module_3d.gd` - Attaques et actions
- `ai_module_3d.gd` - Intelligence artificielle

## 🚀 Installation

### Étape 1: Copier les Fichiers

Copiez tous les fichiers générés dans votre projet :

```
scenes/battle/
├── battle_3d.tscn                  ← Nouvelle scène 3D
├── battle_map_manager_3d.gd
├── terrain_module_3d.gd
├── battle_unit_3d.gd
├── unit_manager_3d.gd
├── movement_module_3d.gd
├── action_module_3d.gd
└── ai_module_3d.gd
```

### Étape 2: Enregistrer la Scène

Dans `scripts/core/scene_registry.gd`, ajoutez ou modifiez :

```gdscript
const SCENE_PATHS: Dictionary = {
	# ...
	SceneID.BATTLE: "res://scenes/battle/battle_3d.tscn",  # ← Pointez vers battle_3d.tscn
	# ...
}
```

### Étape 3: Configurer les Actions de Input Map

Ajoutez les actions d'input dans Project Settings > Input Map :

- `ui_home` : Touche A (rotation caméra gauche)
- `ui_end` : Touche E (rotation caméra droite)

Ou modifiez directement dans `BattleMapManager3D._input()` pour utiliser d'autres touches.

## 🎮 Fonctionnement

### Architecture 3D

```
BattleMap3D (Node3D)
├── GridContainer (Node3D)
│   └── TerrainModule3D
│       └── MeshInstance3D × N (cases du terrain)
│
├── UnitsContainer (Node3D)
│   └── UnitManager3D
│       └── BattleUnit3D × N
│           ├── Sprite3D (billboard)
│           ├── SelectionRing (MeshInstance3D)
│           ├── HPBar (MeshInstance3D)
│           └── Area3D (pour raycasting)
│
├── CameraRig (Node3D) ← Rotation avec A/E
│   └── Camera3D
│
└── UILayer (CanvasLayer)
    └── Interface 2D identique
```

### Interactions

#### Clic Souris
1. **Raycasting** : La caméra projette un rayon 3D
2. **Détection** :
   - Collision avec Area3D d'une unité → Sélection
   - Collision avec StaticBody3D du terrain → Déplacement
3. **Actions** :
   - Clic sur unité alliée → Sélection + highlight des cases
   - Clic sur case → Déplacement (si dans la portée)
   - Clic sur unité ennemie → Attaque (si dans la portée)

#### Rotation Caméra
- **Touche A** : Rotation -90° (gauche)
- **Touche E** : Rotation +90° (droite)
- Animation progressive sur 1 seconde

### Coloration des Cases

Les cases sont colorées via les matériaux StandardMaterial3D :

```gdscript
# Mouvement : bleu translucide
terrain_module.highlight_tiles(positions, Color(0.3, 0.6, 1.0, 0.5))

# Attaque : rouge translucide
terrain_module.highlight_tiles(positions, Color(1.0, 0.3, 0.3, 0.5))

# Effacer
terrain_module.clear_all_highlights()
```

## 🎨 Personnalisation

### Modifier l'Apparence des Unités

Dans `battle_unit_3d.gd`, la fonction `_create_unit_texture()` génère une texture simple. Pour utiliser vos propres sprites :

```gdscript
func _create_visuals_3d() -> void:
	# ...
	sprite_3d = Sprite3D.new()
	sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# Chargez votre texture
	sprite_3d.texture = load("res://sprites/units/knight.png")
	
	sprite_3d.pixel_size = 0.005
	sprite_3d.position.y = sprite_height
	add_child(sprite_3d)
	# ...
```

### Modifier les Couleurs du Terrain

Dans `terrain_module_3d.gd` :

```gdscript
const TILE_COLORS: Dictionary = {
	TileType.GRASS: Color(0.2, 0.8, 0.2),      # Plus vert
	TileType.FOREST: Color(0.1, 0.4, 0.1),     # Forêt sombre
	# ...
}
```

### Ajuster la Caméra

Dans `battle_map_manager_3d.gd` :

```gdscript
const CAMERA_DISTANCE: float = 20.0    # Distance de la caméra
const CAMERA_HEIGHT: float = 15.0      # Hauteur
const CAMERA_ANGLE: float = 60.0       # Angle (en degrés)
const CAMERA_ROTATION_SPEED: float = 120.0  # Vitesse de rotation
```

### Hauteur des Terrains

Dans `terrain_module_3d.gd`, ajustez la hauteur des différents types de terrain :

```gdscript
const TILE_HEIGHTS: Dictionary = {
	TileType.GRASS: 0.0,
	TileType.FOREST: 0.15,      # Plus haut
	TileType.MOUNTAIN: 0.8,     # Très haut
	TileType.WATER: -0.2,       # Sous le niveau
	# ...
}
```

## 🔧 Configuration Avancée

### Ajouter des Animations de Sprites

Pour des sprites animés, modifiez `BattleUnit3D` :

```gdscript
var animated_sprite: AnimatedSprite3D

func _create_visuals_3d() -> void:
	# Remplacer Sprite3D par AnimatedSprite3D
	animated_sprite = AnimatedSprite3D.new()
	animated_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# Configurer SpriteFrames
	var frames = SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_frame("idle", load("res://sprites/knight_idle_1.png"))
	frames.add_frame("idle", load("res://sprites/knight_idle_2.png"))
	
	animated_sprite.sprite_frames = frames
	animated_sprite.play("idle")
	
	add_child(animated_sprite)
```

### Optimisation pour Beaucoup d'Unités

Si vous avez beaucoup d'unités, utilisez MultiMesh :

```gdscript
# Dans terrain_module_3d.gd
var multi_mesh_instance: MultiMeshInstance3D

func _create_visuals() -> void:
	multi_mesh_instance = MultiMeshInstance3D.new()
	var multi_mesh = MultiMesh.new()
	multi_mesh.mesh = box_mesh
	multi_mesh.instance_count = grid_width * grid_height
	# ...
```

## 🎯 Données de Combat

Le format des données reste identique à la version 2D :

```gdscript
var battle_data = {
	"battle_id": "forest_battle_123",
	"terrain": "forest",  # ou Dictionary personnalisé
	
	"player_units": [
		{
			"name": "Chevalier",
			"position": Vector2i(5, 7),
			"stats": {
				"hp": 120,
				"attack": 28,
				"defense": 22,
				"movement": 4,
				"range": 1
			},
			"color": Color(0.2, 0.3, 0.8),  # Optionnel
			"abilities": ["Shield Bash"]
		}
	],
	
	"enemy_units": [ /* ... */ ],
	"objectives": { /* ... */ },
	"scenario": { /* ... */ }
}

# Lancer le combat
EventBus.start_battle(battle_data)
EventBus.change_scene(SceneRegistry.SceneID.BATTLE)
```

## 🐛 Dépannage

### Les unités ne sont pas cliquables

Vérifiez que :
1. Les Area3D ont le bon collision_layer (2)
2. Le raycasting utilise le bon collision_mask (3)
3. Les métadonnées "unit" sont bien définies

### La caméra ne tourne pas

Vérifiez que :
1. Les actions ui_home et ui_end sont configurées
2. `_process()` est actif
3. `is_camera_rotating` se met à true

### Les cases ne se colorent pas

Vérifiez que :
1. `tile_materials` est bien rempli
2. Les StandardMaterial3D sont assignés aux meshes
3. La fonction `highlight_tile()` est appelée

### Les collisions ne fonctionnent pas

Vérifiez dans Project Settings > Layer Names (3D Physics) :
- Layer 1: Terrain
- Layer 2: Units

## 📚 Ressources Utiles

### Conversion 2D → 3D

| 2D | 3D |
|----|-----|
| Node2D | Node3D |
| ColorRect | MeshInstance3D |
| Sprite2D | Sprite3D |
| Area2D | Area3D |
| Vector2 | Vector3 |
| Camera2D | Camera3D |
| position.x, .y | position.x, .z (Y = hauteur) |

### Godot 3D Resources

- [Godot 3D Introduction](https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html)
- [3D Physics](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html)
- [3D Camera](https://docs.godotengine.org/en/stable/classes/class_camera3d.html)

## 🎉 Prochaines Étapes

1. **Testez** la scène battle_3d.tscn directement
2. **Ajoutez** vos propres sprites et textures
3. **Personnalisez** les couleurs et la caméra
4. **Étendez** avec des effets visuels (particules, shaders)

Bon développement ! 🚀
