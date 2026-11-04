extends Node

@export var speed: float = 65.0
@export var flee_range: float = 100.0
@export var catch_range: float = 14.0

var _enemy: CharacterBody2D
var _active: bool = true
var _catching: bool = false


func setup(enemy: CharacterBody2D) -> void:
	_enemy = enemy


func set_active(active: bool) -> void:
	_active = active


func physics_update(_delta: float) -> void:
	if not _active or _enemy == null or _catching:
		return

	var player: Node2D = _enemy.get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		_enemy.velocity = Vector2.ZERO
		_play_walk(Vector2.ZERO)
		return

	var away: Vector2 = _enemy.global_position - player.global_position
	var distance: float = away.length()

	if distance <= catch_range:
		_start_catch()
		return

	if distance <= flee_range and distance > 0.001:
		var direction: Vector2 = away.normalized()
		_enemy.velocity = direction * speed
		_play_walk(direction)
	else:
		_enemy.velocity = Vector2.ZERO
		_play_walk(Vector2.ZERO)


func _play_walk(direction: Vector2) -> void:
	if _enemy.has_method("play_walk_animation"):
		_enemy.call("play_walk_animation", direction)
	elif _enemy.has_method("play_directional_animation"):
		_enemy.call("play_directional_animation", "walking", direction)


func _start_catch() -> void:
	_catching = true
	_enemy.velocity = Vector2.ZERO
	if _enemy.has_method("play_gather"):
		_enemy.call("play_gather")
