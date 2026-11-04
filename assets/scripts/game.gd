extends Node2D


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch") and not event.is_echo():
		for node in get_tree().get_nodes_in_group("switchable"):
			if node.has_method("toggle"):
				node.toggle()
