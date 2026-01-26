extends Node
class_name CommandHistory
## Gestionnaire d'historique de commandes avec undo/redo

signal command_executed(command: Command)
signal command_undone(command: Command)

var history: Array[Command] = []
var current_index: int = -1
var max_history_size: int = 50

func execute_command(command: Command) -> bool:
	"""Exécute une commande et l'ajoute à l'historique"""
	if not command.execute():
		return false
	
	# Supprimer les commandes "redo" si on exécute une nouvelle commande
	if current_index < history.size() - 1:
		history = history.slice(0, current_index + 1)
	
	# Ajouter à l'historique
	history.append(command)
	current_index += 1
	
	# Limiter la taille
	if history.size() > max_history_size:
		history.pop_front()
		current_index -= 1
	
	command_executed.emit(command)
	print("[CommandHistory] ✅ Commande : ", command.get_description())
	
	return true

func can_undo() -> bool:
	return current_index >= 0 and current_index < history.size()

func can_redo() -> bool:
	return current_index < history.size() - 1

func undo() -> bool:
	if not can_undo():
		return false
	
	var command = history[current_index]
	
	if command.undo():
		current_index -= 1
		command_undone.emit(command)
		print("[CommandHistory] ↩️ Undo : ", command.get_description())
		return true
	
	return false

func redo() -> bool:
	if not can_redo():
		return false
	
	current_index += 1
	var command = history[current_index]
	
	if command.execute():
		command_executed.emit(command)
		print("[CommandHistory] ↪️ Redo : ", command.get_description())
		return true
	else:
		current_index -= 1
		return false

func clear_history() -> void:
	history.clear()
	current_index = -1

func get_history_summary() -> Array[String]:
	var summary: Array[String] = []
	
	for i in range(history.size()):
		var prefix = "  "
		if i == current_index:
			prefix = "→ "
		
		summary.append(prefix + history[i].get_description())
	
	return summary