extends CharacterBody2D

const SPEED := 75.0

@export var dream_acceleration: float = 220.0
@export var dream_max_speed: float = 95.0
@export var dream_friction: float = 140.0
@export var dream_brake: float = 280.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bubble: Node2D = $Bubble
@onready var switchable: Node2D = $Switchable
@onready var damageable: Node2D = $Damageable
@onready var attack: Node2D = $Attack

@export var hurt_anim_time: float = 0.55

## Last non-zero move facing used by attacks.
var facing: Vector2 = Vector2.DOWN
var _in_dream: bool = false
var _knockback: Vector2 = Vector2.ZERO
var _hurt_lock: float = 0.0
var _anim_before_hurt: StringName = &""
var _flip_before_hurt: bool = false
var _playing_before_hurt: bool = false


func _ready() -> void:
	add_to_group("player")
	# world + enemy + door_player (open doors omit this layer)
	collision_layer = 1 << 1
	collision_mask = (1 << 0) | (1 << 2) | (1 << 4)
	if switchable.has_signal("mode_changed"):
		switchable.mode_changed.connect(_on_mode_changed)
		_on_mode_changed(switchable.get_mode())
	if attack.has_method("setup"):
		attack.setup(self)
	# Prototype: hits are feedback only — no HP gate / death.
	damageable.immortal = true
	if float(damageable.invulnerability_time) <= 0.0:
		damageable.invulnerability_time = maxf(hurt_anim_time, 0.55)
	if damageable.has_signal("damaged"):
		damageable.damaged.connect(_on_damaged)
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	_ensure_hurt_anims_once()


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		facing = _cardinal_from(direction)

	if _hurt_lock > 0.0:
		_hurt_lock = maxf(_hurt_lock - delta, 0.0)
		if _hurt_lock <= 0.0:
			_restore_anim_after_hurt()

	if _knockback.length() > 5.0:
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, 600.0 * delta)
	elif _in_dream:
		_move_dream(direction, delta)
	else:
		_move_nightmare(direction)

	var attacking: bool = attack != null and attack.has_method("is_busy") and bool(attack.call("is_busy"))
	if _hurt_lock <= 0.0 and not attacking and _knockback.length() <= 5.0:
		if direction:
			_play_walk_animation(direction)
		elif velocity.length() < 8.0:
			animated_sprite.stop()
			animated_sprite.frame = 0

	move_and_slide()


func _on_damaged(_amount: int, _current_health: int) -> void:
	if _hurt_lock <= 0.0:
		_anim_before_hurt = animated_sprite.animation
		_flip_before_hurt = animated_sprite.flip_h
		_playing_before_hurt = animated_sprite.is_playing()
	_hurt_lock = hurt_anim_time
	play_hurt_animation(facing)


func play_hurt_animation(direction: Vector2) -> void:
	var dir := direction if direction != Vector2.ZERO else Vector2.DOWN
	var anim_name := &"hurt_down"
	if absf(dir.x) > absf(dir.y):
		anim_name = &"hurt_sides"
		animated_sprite.flip_h = dir.x < 0.0
	elif dir.y < 0.0:
		anim_name = &"hurt_up"
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = false

	var frames := animated_sprite.sprite_frames
	if frames != null and frames.has_animation(anim_name):
		frames.set_animation_loop(anim_name, false)

	animated_sprite.animation = anim_name
	animated_sprite.frame = 0
	animated_sprite.play(anim_name)


func _on_animation_finished() -> void:
	if _hurt_lock <= 0.0:
		return
	if not str(animated_sprite.animation).begins_with("hurt"):
		return
	_hurt_lock = 0.0
	_restore_anim_after_hurt()


func _restore_anim_after_hurt() -> void:
	var prev := _anim_before_hurt
	_anim_before_hurt = &""
	if prev == &"" or str(prev).begins_with("hurt"):
		return
	animated_sprite.flip_h = _flip_before_hurt
	animated_sprite.animation = prev
	if _playing_before_hurt:
		animated_sprite.play(prev)
	else:
		animated_sprite.stop()
		animated_sprite.frame = 0


func _ensure_hurt_anims_once() -> void:
	var frames := animated_sprite.sprite_frames
	if frames == null:
		return
	for anim_name in [&"hurt_down", &"hurt_sides", &"hurt_up"]:
		if frames.has_animation(anim_name):
			frames.set_animation_loop(anim_name, false)


func apply_knockback(direction: Vector2, force: float) -> void:
	if direction == Vector2.ZERO:
		return
	_knockback = direction.normalized() * force


func play_attack_animation(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		animated_sprite.play("attack_sides")
		animated_sprite.flip_h = direction.x < 0
	elif direction.y < 0:
		animated_sprite.play("attack_up")
		animated_sprite.flip_h = false
	else:
		animated_sprite.play("attack_down")
		animated_sprite.flip_h = false


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
	# Attacks only in nightmare (index 0).
	if attack != null and attack.has_method("set_enabled"):
		attack.set_enabled(not _in_dream)


func _play_walk_animation(direction: Vector2) -> void:
	var cardinal := _cardinal_from(direction)
	if abs(cardinal.x) > abs(cardinal.y):
		animated_sprite.play("walk_sides")
		animated_sprite.flip_h = cardinal.x < 0
	elif cardinal.y < 0:
		animated_sprite.play("walk_up")
		animated_sprite.flip_h = false
	else:
		animated_sprite.play("walk_down")
		animated_sprite.flip_h = false


func _cardinal_from(direction: Vector2) -> Vector2:
	if direction == Vector2.ZERO:
		return facing if facing != Vector2.ZERO else Vector2.DOWN
	if absf(direction.x) >= absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP
