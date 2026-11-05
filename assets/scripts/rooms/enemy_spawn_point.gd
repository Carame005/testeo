class_name EnemySpawnPoint
extends Marker2D

## Designer-placed spawn: assign an enemy PackedScene and position the marker.

@export var enemy_scene: PackedScene
@export var respawn_on_reenter: bool = false

var _instance: Node = null


func spawn(parent: Node) -> Node:
	if enemy_scene == null or parent == null:
		return null
	if is_instance_valid(_instance) and not respawn_on_reenter:
		return _instance
	if is_instance_valid(_instance) and respawn_on_reenter:
		_instance.queue_free()
		_instance = null

	_instance = enemy_scene.instantiate()
	parent.add_child(_instance)
	if _instance is Node2D:
		(_instance as Node2D).global_position = global_position
	return _instance


func get_instance() -> Node:
	if is_instance_valid(_instance):
		return _instance
	return null


func clear_instance() -> void:
	if is_instance_valid(_instance):
		_instance.queue_free()
	_instance = null
