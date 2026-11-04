extends Node

@export var speed: float = 60.0
@export var initial_direction: Vector2 = Vector2(1, 1)

var _enemy: CharacterBody2D
var _direction: Vector2 = Vector2.RIGHT
var _active: bool = true


func setup(enemy: CharacterBody2D) -> void:
	_enemy = enemy
	_direction = initial_direction.normalized()
	if _direction == Vector2.ZERO:
		_direction = Vector2.RIGHT
	_play_float()


func set_active(active: bool) -> void:
	_active = active
	if active:
		_play_float()


func physics_update(_delta: float) -> void:
	if not _active or _enemy == null:
		return

	for i in _enemy.get_slide_collision_count():
		var collision: KinematicCollision2D = _enemy.get_slide_collision(i)
		_direction = _direction.bounce(collision.get_normal()).normalized()
		break

	_enemy.velocity = _direction * speed
	_play_float()


func _play_float() -> void:
	if _enemy == null:
		return
	var sprite := _enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return
	sprite.play("floating")
	sprite.flip_h = _direction.x < 0
