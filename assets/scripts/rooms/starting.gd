class_name StartingRoom
extends Room

## Run start: four cardinal doors; south is sealed and leads to the boss.
## Put this script on the room ROOT (not a child node).

@export var door_north: Door
@export var door_east: Door
@export var door_south: Door
@export var door_west: Door
@export var boss_door_area: Area2D

var _boss_hint_connected: bool = false


func _ready() -> void:
	super._ready()
	_seal_boss_door()
	_setup_boss_hint()


func on_player_entered(_player: Node2D) -> void:
	_seal_boss_door()
	_setup_boss_hint()


func _seal_boss_door() -> void:
	var south := door_south
	if south == null:
		south = _guess_south_door()
	if south != null:
		south.set_open(false)


func _setup_boss_hint() -> void:
	if boss_door_area == null:
		boss_door_area = get_node_or_null("BossArea") as Area2D
	if boss_door_area == null or _boss_hint_connected:
		return

	# Detect player layer only.
	boss_door_area.collision_layer = 0
	boss_door_area.collision_mask = 1 << 1
	boss_door_area.monitoring = true
	boss_door_area.monitorable = false
	if not boss_door_area.body_entered.is_connected(_on_boss_area_body_entered):
		boss_door_area.body_entered.connect(_on_boss_area_body_entered)
	_boss_hint_connected = true


func _on_boss_area_body_entered(body: Node) -> void:
	if not is_active():
		return
	if body == null or not body.is_in_group("player"):
		return
	# Placeholder until real UI messaging exists.
	print("[StartingRoom] Boss door is sealed. Come back later.")


func _guess_south_door() -> Door:
	var door2 := get_node_or_null("Door2")
	if door2 is Door:
		return door2
	return null
