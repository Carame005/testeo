extends Node

@export var speed: float = 45.0
## Distance kept on the shooting axis (caution / preferred spacing).
@export var preferred_distance: float = 80.0
@export var attack_range: float = 120.0
@export var fire_cooldown: float = 1.2
@export var projectile_speed: float = 120.0
## How close to an axis counts as "aligned" for shooting.
@export var axis_align_tolerance: float = 8.0

var _enemy: CharacterBody2D
var _projectile_template: Area2D
var _cooldown_left: float = 0.0
var _active: bool = true


func setup(enemy: CharacterBody2D) -> void:
	_enemy = enemy
	# Solid vs walls/doors/other enemies; no solid push vs player.
	_enemy.collision_layer = 1 << 2 # enemy
	_enemy.collision_mask = (1 << 0) | (1 << 2) | (1 << 3) # world + enemy + door_enemy
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
	var aligned_h := absf(to_player.y) <= axis_align_tolerance
	var aligned_v := absf(to_player.x) <= axis_align_tolerance
	var axis_aligned := aligned_h or aligned_v

	if axis_aligned:
		_update_aligned(to_player, aligned_h)
	else:
		_update_seek_alignment(player.global_position)


func _update_aligned(to_player: Vector2, aligned_horizontal: bool) -> void:
	var axis_dir := Vector2.ZERO
	var axis_distance := 0.0

	if aligned_horizontal:
		axis_distance = absf(to_player.x)
		axis_dir = Vector2(signf(to_player.x), 0.0) if to_player.x != 0.0 else Vector2.RIGHT
	else:
		axis_distance = absf(to_player.y)
		axis_dir = Vector2(0.0, signf(to_player.y)) if to_player.y != 0.0 else Vector2.DOWN

	# Keep preferred distance on the shooting axis only.
	if axis_distance < preferred_distance * 0.85:
		_enemy.velocity = -axis_dir * speed
		_enemy.call("play_directional_animation", "walking", -axis_dir)
		_enemy.call("set_attacking", false)
	elif axis_distance > preferred_distance * 1.15:
		_enemy.velocity = axis_dir * speed
		_enemy.call("play_directional_animation", "walking", axis_dir)
		_enemy.call("set_attacking", false)
	else:
		_enemy.velocity = Vector2.ZERO
		_enemy.call("play_directional_animation", "walking", Vector2.ZERO)

	if axis_distance <= attack_range and _cooldown_left <= 0.0 and axis_dir != Vector2.ZERO:
		_cooldown_left = fire_cooldown
		_enemy.call("set_attacking", true)
		_enemy.call("play_directional_animation", "attacking", axis_dir)
		_fire(axis_dir)
	elif axis_distance > attack_range:
		_enemy.call("set_attacking", false)


func _update_seek_alignment(player_pos: Vector2) -> void:
	_enemy.call("set_attacking", false)
	var target := _pick_alignment_spot(player_pos)
	var to_target: Vector2 = target - _enemy.global_position
	if to_target.length() <= 4.0:
		_enemy.velocity = Vector2.ZERO
		_enemy.call("play_directional_animation", "walking", Vector2.ZERO)
		return

	# Move on one axis at a time so we never "slide" diagonally into a shot.
	var move_dir := Vector2.ZERO
	if absf(to_target.x) >= absf(to_target.y):
		move_dir = Vector2(signf(to_target.x), 0.0)
	else:
		move_dir = Vector2(0.0, signf(to_target.y))

	_enemy.velocity = move_dir * speed
	_enemy.call("play_directional_animation", "walking", move_dir)


func _pick_alignment_spot(player_pos: Vector2) -> Vector2:
	var enemy_pos := _enemy.global_position
	var side_x := signf(enemy_pos.x - player_pos.x)
	if side_x == 0.0:
		side_x = 1.0
	var side_y := signf(enemy_pos.y - player_pos.y)
	if side_y == 0.0:
		side_y = 1.0

	# Same Y as player, caution distance on X → horizontal shot.
	var horizontal_spot := Vector2(player_pos.x + side_x * preferred_distance, player_pos.y)
	# Same X as player, caution distance on Y → vertical shot.
	var vertical_spot := Vector2(player_pos.x, player_pos.y + side_y * preferred_distance)

	# Prefer the spot that needs less travel from the current position.
	if enemy_pos.distance_squared_to(horizontal_spot) <= enemy_pos.distance_squared_to(vertical_spot):
		return horizontal_spot
	return vertical_spot


func _fire(direction: Vector2) -> void:
	if _projectile_template == null:
		return
	var bolt: Area2D = _projectile_template.duplicate() as Area2D
	_enemy.get_parent().add_child(bolt)
	bolt.global_position = _enemy.global_position
	if bolt.has_method("launch"):
		bolt.launch(direction, projectile_speed, _enemy)
