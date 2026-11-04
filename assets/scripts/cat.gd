class_name Cat
extends CharacterBody2D

signal caught

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var switchable: Node2D = $Switchable

var _movement: Node = null
var _active: bool = true
var _is_caught: bool = false


func _ready() -> void:
	add_to_group("cat")
	# Catchable by proximity; no solid push vs player.
	collision_layer = 0
	collision_mask = (1 << 0) | (1 << 3) # world + door_enemy
	_movement = get_node_or_null("Runner")
	if _movement and _movement.has_method("setup"):
		_movement.setup(self)
	if switchable.has_signal("mode_changed"):
		switchable.mode_changed.connect(_on_mode_changed)
		_on_mode_changed(switchable.get_mode())


func _physics_process(delta: float) -> void:
	if _is_caught:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if not _active or _movement == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _movement.has_method("physics_update"):
		_movement.physics_update(delta)
	move_and_slide()


func is_active() -> bool:
	return _active and not _is_caught


func play_walk_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		animated_sprite.stop()
		return
	if abs(direction.x) > abs(direction.y):
		animated_sprite.play("walking_sides")
		animated_sprite.flip_h = direction.x < 0
	elif direction.y < 0:
		animated_sprite.play("walking_up")
		animated_sprite.flip_h = false
	else:
		animated_sprite.play("walking_down")
		animated_sprite.flip_h = false


func play_gather() -> void:
	_is_caught = true
	velocity = Vector2.ZERO
	if animated_sprite.sprite_frames.has_animation("gather"):
		animated_sprite.sprite_frames.set_animation_loop("gather", false)
		animated_sprite.play("gather")
		await animated_sprite.animation_finished
	caught.emit()
	# Advantage grant is intentionally deferred beyond this signal.
	queue_free()


func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func _on_mode_changed(index: int) -> void:
	_active = index == 0
	if _movement and _movement.has_method("set_active"):
		_movement.set_active(_active)
	if not _active:
		velocity = Vector2.ZERO
		animated_sprite.stop()
