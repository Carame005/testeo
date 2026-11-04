extends CharacterBody2D

const SPEED := 75.0

@export var dream_acceleration: float = 220.0
@export var dream_max_speed: float = 95.0
@export var dream_friction: float = 140.0
@export var dream_brake: float = 280.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bubble: Node2D = $Bubble
@onready var switchable: Node2D = $Switchable

var _in_dream: bool = false


func _ready() -> void:
	add_to_group("player")
	if switchable.has_signal("mode_changed"):
		switchable.mode_changed.connect(_on_mode_changed)
		_on_mode_changed(switchable.get_mode())


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if _in_dream:
		_move_dream(direction, delta)
	else:
		_move_nightmare(direction)

	if direction:
		_play_walk_animation(direction)
	elif velocity.length() < 8.0:
		animated_sprite.stop()
		animated_sprite.frame = 0

	move_and_slide()


func _move_nightmare(direction: Vector2) -> void:
	if direction:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)


func _move_dream(direction: Vector2, delta: float) -> void:
	if direction:
		# Accelerate like a hamster ball; opposite input brakes harder.
		var aligning := velocity.dot(direction)
		var accel := dream_acceleration if aligning >= 0.0 else dream_brake
		velocity += direction * accel * delta
		if velocity.length() > dream_max_speed:
			velocity = velocity.limit_length(dream_max_speed)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, dream_friction * delta)


func _on_mode_changed(index: int) -> void:
	_in_dream = index == 1
	bubble.visible = _in_dream
	if not _in_dream:
		velocity = Vector2.ZERO


func _play_walk_animation(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		animated_sprite.play("walk_sides")
		animated_sprite.flip_h = direction.x < 0
	elif direction.y < 0:
		animated_sprite.play("walk_up")
		animated_sprite.flip_h = false
	else:
		animated_sprite.play("walk_down")
		animated_sprite.flip_h = false
