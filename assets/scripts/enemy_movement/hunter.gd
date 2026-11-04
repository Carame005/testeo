extends Node

@export var speed: float = 55.0
@export var attack_range: float = 28.0
@export var attack_cooldown: float = 0.8

var _enemy: CharacterBody2D
var _cooldown_left: float = 0.0
var _active: bool = true


func setup(enemy: CharacterBody2D) -> void:
	_enemy = enemy


func set_active(active: bool) -> void:
	_active = active
	_cooldown_left = 0.0


func physics_update(delta: float) -> void:
	if not _active or _enemy == null:
		return

	_cooldown_left = maxf(_cooldown_left - delta, 0.0)

	var player: Node2D = _enemy.get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		_enemy.velocity = Vector2.ZERO
		_enemy.call("play_directional_animation", "walking", Vector2.ZERO)
		return

	var to_player: Vector2 = player.global_position - _enemy.global_position
	var distance: float = to_player.length()
	var direction: Vector2 = to_player.normalized() if distance > 0.001 else Vector2.ZERO

	if distance <= attack_range:
		_enemy.velocity = Vector2.ZERO
		_enemy.call("set_attacking", true)
		_enemy.call("play_directional_animation", "attacking", direction)
		if _cooldown_left <= 0.0:
			_cooldown_left = attack_cooldown
			# Player damage is intentionally deferred.
	else:
		_enemy.call("set_attacking", false)
		_enemy.velocity = direction * speed
		_enemy.call("play_directional_animation", "walking", direction)
