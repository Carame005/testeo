class_name ParkourRoom
extends Room

## Closed exit until the challenge is done. Falling into the void resets to start.
## Forces dream mode and locks switching to nightmare while inside.

@export var exit_door: Door
@export var respawn_point: Marker2D
@export var void_area: Area2D
@export var keep_exit_closed: bool = true

var _void_connected: bool = false


func _ready() -> void:
	super._ready()
	if exit_door != null and keep_exit_closed:
		exit_door.set_open(false)
	_setup_void_area()


func on_player_entered(_player: Node2D) -> void:
	_force_dream_and_lock()
	if exit_door != null and keep_exit_closed:
		exit_door.set_open(false)
	_setup_void_area()


func on_player_exited(_player: Node2D) -> void:
	_unlock_switchables()


func _setup_void_area() -> void:
	if void_area == null or _void_connected:
		return
	void_area.monitoring = true
	void_area.body_entered.connect(_on_void_body_entered)
	_void_connected = true


func _on_void_body_entered(body: Node) -> void:
	if not is_active():
		return
	if body == null or not body.is_in_group("player"):
		return
	_respawn_player(body as Node2D)


func _respawn_player(player: Node2D) -> void:
	if respawn_point == null:
		return
	player.global_position = respawn_point.global_position
	if player is CharacterBody2D:
		(player as CharacterBody2D).velocity = Vector2.ZERO


func _force_dream_and_lock() -> void:
	for node in get_tree().get_nodes_in_group("switchable"):
		if node.has_method("set_mode"):
			node.set_mode(1) # MODE_SUENO
		if node.has_method("set_locked"):
			node.set_locked(true)


func _unlock_switchables() -> void:
	for node in get_tree().get_nodes_in_group("switchable"):
		if node.has_method("set_locked"):
			node.set_locked(false)
