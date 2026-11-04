class_name Enemy
extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damageable: Node2D = $Damageable
@onready var switchable: Node2D = $Switchable

var _movement: Node = null
var _active: bool = true
var _attacking: bool = false


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
	if not _active or _movement == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _movement.has_method("physics_update"):
		_movement.physics_update(delta)
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


func _find_movement() -> Node:
	for child_name in ["Hunter", "Ranger", "Roamer", "Bouncer", "Runner"]:
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
		animated_sprite.play("inactive")


func _set_hitboxes_enabled(enabled: bool) -> void:
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape != null:
		body_shape.disabled = not enabled

	for child in get_children():
		if child is Area2D and child.name != "Projectile":
			var area := child as Area2D
			area.monitoring = enabled
			area.monitorable = enabled
			for shape in area.get_children():
				if shape is CollisionShape2D:
					shape.disabled = not enabled


func _configure_areas() -> void:
	for child in get_children():
		if not (child is Area2D):
			continue
		var area := child as Area2D
		if area.name == "Projectile":
			# world + player
			area.collision_layer = 0
			area.collision_mask = (1 << 0) | (1 << 1)
		else:
			# Detect player only.
			area.collision_layer = 0
			area.collision_mask = 1 << 1


func _on_died() -> void:
	queue_free()
