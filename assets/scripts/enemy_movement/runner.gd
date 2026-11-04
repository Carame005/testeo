extends Node

@export var speed: float = 65.0
@export var flee_range: float = 100.0

var _enemy: CharacterBody2D
var _active: bool = true


func setup(enemy: CharacterBody2D) -> void:
	_enemy = enemy


func set_active(active: bool) -> void:
	_active = active


func physics_update(_delta: float) -> void:
	if not _active or _enemy == null:
		return

	var player: Node2D = _enemy.get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		_enemy.velocity = Vector2.ZERO
		_enemy.call("play_directional_animation", "walking", Vector2.ZERO)
		return

	var away: Vector2 = _enemy.global_position - player.global_position
	var distance: float = away.length()
	if distance <= flee_range and distance > 0.001:
		var direction: Vector2 = away.normalized()
		_enemy.velocity = direction * speed
		_enemy.call("play_directional_animation", "walking", direction)
	else:
		_enemy.velocity = Vector2.ZERO
		_enemy.call("play_directional_animation", "walking", Vector2.ZERO)
	# TODO: grant player advantages on contact.
