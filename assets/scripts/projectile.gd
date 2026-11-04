extends Area2D

@export var speed: float = 120.0
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var _alive: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = false
	visible = false
	set_physics_process(false)


func launch(dir: Vector2, launch_speed: float = -1.0) -> void:
	direction = dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT
	if launch_speed > 0.0:
		speed = launch_speed
	visible = true
	monitoring = true
	_alive = true
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Player damage is intentionally deferred.
		queue_free()
		return
	if body is StaticBody2D or body is TileMap:
		queue_free()
