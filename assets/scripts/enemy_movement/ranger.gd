extends Node

@export var speed: float = 45.0
@export var preferred_distance: float = 80.0
@export var attack_range: float = 120.0
@export var fire_cooldown: float = 1.2
@export var projectile_speed: float = 120.0

var _enemy: CharacterBody2D
var _projectile_template: Area2D
var _cooldown_left: float = 0.0
var _active: bool = true


func setup(enemy: CharacterBody2D) -> void:
	_enemy = enemy
	_projectile_template = enemy.get_node_or_null("Projectile") as Area2D
	if _projectile_template != null:
		_projectile_template.visible = false
		_projectile_template.monitoring = false
		_projectile_template.set_physics_process(false)


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
		return

	var to_player: Vector2 = player.global_position - _enemy.global_position
	var distance: float = to_player.length()
	var direction: Vector2 = to_player.normalized() if distance > 0.001 else Vector2.ZERO

	if distance < preferred_distance * 0.85:
		_enemy.velocity = -direction * speed
		_enemy.call("play_directional_animation", "walking", -direction)
	elif distance > preferred_distance * 1.15:
		_enemy.velocity = direction * speed
		_enemy.call("play_directional_animation", "walking", direction)
	else:
		_enemy.velocity = Vector2.ZERO
		_enemy.call("play_directional_animation", "walking", Vector2.ZERO)

	if distance <= attack_range and _cooldown_left <= 0.0 and direction != Vector2.ZERO:
		_cooldown_left = fire_cooldown
		_enemy.call("set_attacking", true)
		_enemy.call("play_directional_animation", "attacking", direction)
		_fire(direction)
	elif distance > attack_range:
		_enemy.call("set_attacking", false)


func _fire(direction: Vector2) -> void:
	if _projectile_template == null:
		return
	var bolt: Area2D = _projectile_template.duplicate() as Area2D
	_enemy.get_parent().add_child(bolt)
	bolt.global_position = _enemy.global_position
	if bolt.has_method("launch"):
		bolt.launch(direction, projectile_speed)
