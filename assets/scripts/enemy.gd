class_name Enemy
extends CharacterBody2D

@export var contact_damage: int = 1
@export var contact_cooldown: float = 0.65
@export var contact_knockback: float = 100.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damageable: Node2D = $Damageable
@onready var switchable: Node2D = $Switchable

var _movement: Node = null
var _active: bool = true
var _attacking: bool = false
var _contact_cd: float = 0.0
var _hurtboxes: Array[Area2D] = []


func _ready() -> void:
	add_to_group("enemy")
	# world + player + door_enemy (doors always block enemies)
	collision_layer = 1 << 2
	collision_mask = (1 << 0) | (1 << 1) | (1 << 3)
	_configure_areas()
	_movement = _find_movement()
	if _movement and _movement.has_method("setup"):
		_movement.setup(self)
	if damageable.has_signal("died"):
		damageable.died.connect(_on_died)
	if switchable.has_signal("mode_changed"):
		switchable.mode_changed.connect(_on_mode_changed)
		_on_mode_changed(switchable.get_mode())


func _physics_process(delta: float) -> void:
	_contact_cd = maxf(_contact_cd - delta, 0.0)
	if not _active or _movement == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _movement.has_method("physics_update"):
		_movement.physics_update(delta)
	if _uses_generic_contact():
		_try_hurtbox_contact()
	move_and_slide()


func is_active() -> bool:
	return _active


func set_attacking(value: bool) -> void:
	_attacking = value


func play_directional_animation(prefix: String, direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		if not _attacking:
			animated_sprite.play("idle")
		return
	if abs(direction.x) > abs(direction.y):
		animated_sprite.play("%s_sides" % prefix)
		animated_sprite.flip_h = direction.x < 0
	elif direction.y < 0:
		animated_sprite.play("%s_up" % prefix)
		animated_sprite.flip_h = false
	else:
		animated_sprite.play("%s_down" % prefix)
		animated_sprite.flip_h = false


func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


## Hit the player (damage + knockback). Shared by contact, attacks, and projectiles.
func deal_player_hit(player: Node2D, amount: int = -1, knockback_force: float = -1.0) -> bool:
	if not _active or player == null or not player.is_in_group("player"):
		return false
	if _contact_cd > 0.0:
		return false

	var dmg_amount := contact_damage if amount < 0 else amount
	var force := contact_knockback if knockback_force < 0.0 else knockback_force

	var dmg := player.get_node_or_null("Damageable")
	if dmg == null or not dmg.has_method("take_damage"):
		return false

	_contact_cd = contact_cooldown
	dmg.take_damage(dmg_amount)
	if player.has_method("apply_knockback") and force > 0.0:
		var away: Vector2 = player.global_position - global_position
		if away == Vector2.ZERO:
			away = Vector2.DOWN
		player.apply_knockback(away.normalized(), force)
	return true


## Optional elite/shielded hit hook. Falls back to flat damage.
func try_receive_hit(amount: int, hit_origin: Vector2) -> bool:
	if _movement != null and _movement.has_method("try_receive_hit"):
		return bool(_movement.call("try_receive_hit", amount, hit_origin))
	if damageable != null and damageable.has_method("take_damage"):
		damageable.take_damage(amount)
		return true
	return false


func _uses_generic_contact() -> bool:
	# Elite has its own contact / attack damage paths.
	return get_node_or_null("Elite") == null


func _try_hurtbox_contact() -> void:
	if _contact_cd > 0.0 or _hurtboxes.is_empty():
		return
	for area in _hurtboxes:
		if area == null or not area.monitoring:
			continue
		for body in area.get_overlapping_bodies():
			if body != null and body.is_in_group("player"):
				deal_player_hit(body as Node2D)
				return


func _find_movement() -> Node:
	for child_name in ["Hunter", "Ranger", "Roamer", "Bouncer", "Runner", "Elite"]:
		var node := get_node_or_null(child_name)
		if node != null and node.get_script() != null:
			return node
	return null


func _on_mode_changed(index: int) -> void:
	_active = index == 0
	if _movement and _movement.has_method("set_active"):
		_movement.set_active(_active)
	_set_hitboxes_enabled(_active)
	if not _active:
		velocity = Vector2.ZERO
		_attacking = false
		if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation("inactive"):
			animated_sprite.play("inactive")


func _set_hitboxes_enabled(enabled: bool) -> void:
	var body_shape := _find_body_shape()
	if body_shape != null:
		body_shape.disabled = not enabled

	for child in get_children():
		if child is Area2D and child.name != "Projectile":
			var area := child as Area2D
			area.monitoring = enabled
			area.monitorable = false
			for shape in area.get_children():
				if shape is CollisionShape2D:
					shape.disabled = not enabled


func _find_body_shape() -> CollisionShape2D:
	var named := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if named != null:
		return named
	return get_node_or_null("Hitbox") as CollisionShape2D


func _configure_areas() -> void:
	_hurtboxes.clear()
	_configure_area_tree(self)


func _configure_area_tree(node: Node) -> void:
	for child in node.get_children():
		if child is Area2D:
			var area := child as Area2D
			if area.name == "Projectile":
				area.collision_layer = 0
				area.collision_mask = (1 << 0) | (1 << 1)
			else:
				area.collision_layer = 0
				area.collision_mask = 1 << 1
				area.monitoring = true
				area.monitorable = false
				var lname := area.name.to_lower()
				if lname.contains("hurt") or lname.contains("shield"):
					area.add_to_group("hurtbox")
					if lname.contains("hurt") and area not in _hurtboxes:
						_hurtboxes.append(area)
		_configure_area_tree(child)


func _on_died() -> void:
	queue_free()
