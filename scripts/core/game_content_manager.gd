# scripts/game/game_content_manager.gd
extends Node
class_name GameContentManager

## Gestionnaire centralisé pour tout le contenu du jeu chargé depuis Lua

# Loaders
var dialogue_loader: DialogueDataLoader
var item_loader: ItemDataLoader
var ability_loader: AbilityDataLoader
var enemy_loader: EnemyDataLoader

# Caches centralisés
var loaded_dialogues: Dictionary = {}
var loaded_items: Dictionary = {}
var loaded_abilities: Dictionary = {}
var loaded_enemies: Dictionary = {}

func _ready():
	_initialize_loaders()
	_preload_essential_content()

func _initialize_loaders():
	print("[GameContentManager] Initialisation des loaders...")
	
	dialogue_loader = DialogueDataLoader.new()
	item_loader = ItemDataLoader.new()
	ability_loader = AbilityDataLoader.new()
	enemy_loader = EnemyDataLoader.new()
	
	add_child(dialogue_loader)
	add_child(item_loader)
	add_child(ability_loader)
	add_child(enemy_loader)
	
	print("[GameContentManager] ✅ Loaders initialisés")

func _preload_essential_content():
	print("[GameContentManager] Préchargement du contenu essentiel...")
	
	# Précharger les dialogues d'introduction
	dialogue_loader.preload_dialogues(["intro"])
	
	# Précharger tous les items
	loaded_items = item_loader.load_all_items()
	
	# Précharger toutes les capacités
	loaded_abilities = ability_loader.load_all_abilities()
	
	# Précharger tous les ennemis
	loaded_enemies = enemy_loader.load_all_enemies()
	
	print("[GameContentManager] ✅ Contenu préchargé")
	print("  - Dialogues : ", dialogue_loader.get_available_dialogues().size())
	print("  - Items : ", loaded_items.size())
	print("  - Capacités : ", loaded_abilities.size())
	print("  - Ennemis : ", loaded_enemies.size())

# ===================
# DIALOGUES
# ===================

func play_dialogue(dialogue_id: String):
	var dialogue = dialogue_loader.load_dialogue(dialogue_id)
	
	if dialogue.is_empty():
		push_error("[GameContentManager] Dialogue introuvable : ", dialogue_id)
		return
	
	# Envoyer au système de dialogue
	EventBus.play_dialogue.emit(dialogue)

func get_dialogue_sequence(dialogue_id: String, sequence_id: String) -> Dictionary:
	return dialogue_loader.get_sequence(dialogue_id, sequence_id)

# ===================
# ITEMS
# ===================

func get_item(item_id: String) -> Dictionary:
	if loaded_items.has(item_id):
		return loaded_items[item_id]
	
	return item_loader.load_item(item_id)

func create_item_instance(item_id: String, quantity: int = 1) -> Dictionary:
	return item_loader.create_item_instance(item_id, quantity)

func get_items_by_category(category: String) -> Array:
	return item_loader.get_items_by_category(category)

func use_item(item_id: String, user: Node, target: Node) -> bool:
	var item = get_item(item_id)
	
	if item.is_empty():
		return false
	
	# Vérifier si l'item est consommable
	if item.type != "consumable":
		print("[GameContentManager] Cet item n'est pas consommable")
		return false
	
	# Appliquer les effets
	for effect in item.effects:
		_apply_item_effect(effect, user, target)
	
	# Déclencher l'événement d'utilisation
	EventBus.item_used.emit(item_id, user, target)
	
	return true

func _apply_item_effect(effect: Dictionary, user: Node, target: Node):
	match effect.type:
		"heal":
			if target.has_method("heal"):
				target.heal(effect.amount)
		
		"damage":
			if target.has_method("take_damage"):
				target.take_damage(effect.amount, effect.get("element", "physical"))
		
		"buff":
			if target.has_method("apply_buff"):
				target.apply_buff(effect.stat, effect.amount, effect.duration)
		
		"remove_status":
			if target.has_method("remove_status"):
				target.remove_status(effect.status)

# ===================
# ABILITIES
# ===================

func get_ability(ability_id: String) -> Dictionary:
	if loaded_abilities.has(ability_id):
		return loaded_abilities[ability_id]
	
	return ability_loader.load_ability(ability_id)

func get_abilities_by_class(class_name: String) -> Array:
	return ability_loader.get_abilities_by_class(class_name)

func can_use_ability(unit_data: Dictionary, ability_id: String) -> bool:
	return ability_loader.can_use_ability(unit_data, ability_id)

func use_ability(user: Node, ability_id: String, targets: Array) -> bool:
	var ability = get_ability(ability_id)
	
	if ability.is_empty():
		return false
	
	# Vérifier si l'unité peut utiliser la capacité
	if not can_use_ability(user.data, ability_id):
		print("[GameContentManager] Impossible d'utiliser cette capacité")
		return false
	
	# Déduire le coût
	if ability.has("cost"):
		if ability.cost.has("mana"):
			user.mana -= ability.cost.mana
	
	# Appliquer les effets sur chaque cible
	for target in targets:
		for effect in ability.effects:
			_apply_ability_effect(effect, user, target, ability)
	
	# Déclencher l'animation et le son
	if ability.has("animation"):
		_play_ability_animation(user, ability)
	
	# Déclencher l'événement
	EventBus.ability_used.emit(ability_id, user, targets)
	
	return true

func _apply_ability_effect(effect: Dictionary, user: Node, target: Node, ability: Dictionary):
	match effect.type:
		"damage":
			if target.has_method("take_damage"):
				var damage = _calculate_ability_damage(effect, user, ability)
				target.take_damage(damage, effect.get("element", "physical"))
		
		"heal":
			if target.has_method("heal"):
				var heal_amount = _calculate_ability_heal(effect, user)
				target.heal(heal_amount)
		
		"buff":
			if target.has_method("apply_buff"):
				target.apply_buff(effect.stat, effect.amount, effect.duration)
		
		"apply_status":
			if target.has_method("apply_status"):
				var roll = randi_range(1, 100)
				if roll <= effect.get("chance", 100):
					target.apply_status(effect.status, effect.get("duration", 1))

func _calculate_ability_damage(effect: Dictionary, user: Node, ability: Dictionary) -> int:
	var damage = effect.get("base_damage", 0)
	
	# Appliquer le scaling
	if effect.has("scaling") and user.has("stats"):
		var scaling = effect.scaling
		var stat_value = user.stats.get(scaling.stat, 0)
		var ratio = scaling.get("ratio", 1.0)
		damage += int(stat_value * ratio)
	
	return damage

func _calculate_ability_heal(effect: Dictionary, user: Node) -> int:
	var heal = effect.get("base_amount", 0)
	
	# Appliquer le scaling
	if effect.has("scaling") and user.has("stats"):
		var scaling = effect.scaling
		var stat_value = user.stats.get(scaling.stat, 0)
		var ratio = scaling.get("ratio", 1.0)
		heal += int(stat_value * ratio)
	
	return heal

func _play_ability_animation(user: Node, ability: Dictionary):
	if ability.has("animation") and user.has_method("play_animation"):
		user.play_animation(ability.animation)
	
	if ability.has("sound"):
		AudioManager.play_sfx(ability.sound)
	
	if ability.has("particle_effect"):
		_spawn_particle_effect(user, ability.particle_effect)

func _spawn_particle_effect(user: Node, effect_path: String):
	# Implémenter le système de particules
	pass

# ===================
# ENEMIES
# ===================

func get_enemy(enemy_id: String) -> Dictionary:
	if loaded_enemies.has(enemy_id):
		return loaded_enemies[enemy_id]
	
	return enemy_loader.load_enemy(enemy_id)

func spawn_enemy(enemy_id: String, position: Vector2i, level_modifier: int = 0) -> Node:
	var enemy_data = enemy_loader.create_enemy_instance(enemy_id, level_modifier)
	
	if enemy_data.is_empty():
		push_error("[GameContentManager] Impossible de créer l'ennemi : ", enemy_id)
		return null
	
	# Créer l'entité ennemi
	var enemy = preload("res://scenes/units/enemy_3d.tscn").instantiate()
	enemy.initialize(enemy_data)
	enemy.grid_position = position
	
	return enemy

func get_enemies_by_level(level: int) -> Array:
	return enemy_loader.get_enemies_by_level(range)

func generate_enemy_loot(enemy_id: String) -> Dictionary:
	return enemy_loader.generate_random_loot(enemy_id)

# ===================
# UTILITAIRES
# ===================

func reload_all_content():
	print("[GameContentManager] Rechargement de tout le contenu...")
	
	# Vider les caches
	dialogue_loader.clear_cache()
	item_loader.clear_cache()
	ability_loader.clear_cache()
	enemy_loader.clear_cache()
	
	# Recharger
	_preload_essential_content()
	
	print("[GameContentManager] ✅ Contenu rechargé")

func get_content_statistics() -> Dictionary:
	return {
		"dialogues": dialogue_loader.get_available_dialogues().size(),
		"items": loaded_items.size(),
		"abilities": loaded_abilities.size(),
		"enemies": loaded_enemies.size()
	}

func validate_all_content() -> Dictionary:
	print("[GameContentManager] Validation du contenu...")
	
	var validation_results = {
		"items": {"valid": 0, "invalid": 0, "errors": []},
		"abilities": {"valid": 0, "invalid": 0, "errors": []},
		"enemies": {"valid": 0, "invalid": 0, "errors": []}
	}
	
	# Valider les items
	for item_id in loaded_items:
		var item = loaded_items[item_id]
		if _validate_item(item):
			validation_results.items.valid += 1
		else:
			validation_results.items.invalid += 1
			validation_results.items.errors.append("Item invalide : " + item_id)
	
	# Valider les capacités
	for ability_id in loaded_abilities:
		var ability = loaded_abilities[ability_id]
		if _validate_ability(ability):
			validation_results.abilities.valid += 1
		else:
			validation_results.abilities.invalid += 1
			validation_results.abilities.errors.append("Capacité invalide : " + ability_id)
	
	# Valider les ennemis
	for enemy_id in loaded_enemies:
		var enemy = loaded_enemies[enemy_id]
		if _validate_enemy(enemy):
			validation_results.enemies.valid += 1
		else:
			validation_results.enemies.invalid += 1
			validation_results.enemies.errors.append("Ennemi invalide : " + enemy_id)
	
	print("[GameContentManager] ✅ Validation terminée")
	_print_validation_results(validation_results)
	
	return validation_results

func _validate_item(item: Dictionary) -> bool:
	var required_fields = ["id", "name", "type", "category"]
	for field in required_fields:
		if not item.has(field):
			return false
	return true

func _validate_ability(ability: Dictionary) -> bool:
	var required_fields = ["id", "name", "type", "category"]
	for field in required_fields:
		if not ability.has(field):
			return false
	return true

func _validate_enemy(enemy: Dictionary) -> bool:
	var required_fields = ["id", "name", "stats", "type", "faction"]
	for field in required_fields:
		if not enemy.has(field):
			return false
	return true

func _print_validation_results(results: Dictionary):
	print("==========================================")
	print("RÉSULTATS DE VALIDATION")
	print("==========================================")
	
	for category in results:
		var data = results[category]
		print("\n", category.to_upper(), ":")
		print("  ✅ Valides : ", data.valid)
		print("  ❌ Invalides : ", data.invalid)
		
		if data.errors.size() > 0:
			print("  Erreurs :")
			for error in data.errors:
				print("    - ", error)
	
	print("\n==========================================")
