extends Node2D

## Marks a room and exposes its camera bounds from the Pesadilla tilemap.


func _ready() -> void:
	add_to_group("rooms")


func get_camera_bounds() -> Rect2:
	var tilemap := get_node_or_null("Switchable/Pesadilla") as TileMap
	if tilemap == null or tilemap.tile_set == null:
		return Rect2()

	var used: Rect2i = tilemap.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return Rect2()

	var tile_size := Vector2(tilemap.tile_set.tile_size)
	var top_left_local: Vector2 = tilemap.map_to_local(used.position) - tile_size * 0.5
	var bottom_right_local: Vector2 = (
		tilemap.map_to_local(used.position + used.size - Vector2i.ONE) + tile_size * 0.5
	)
	var top_left: Vector2 = tilemap.to_global(top_left_local)
	var bottom_right: Vector2 = tilemap.to_global(bottom_right_local)
	return Rect2(top_left, bottom_right - top_left)


func contains_world_point(point: Vector2, margin: float = 8.0) -> bool:
	var bounds := get_camera_bounds()
	if bounds.size == Vector2.ZERO:
		return false
	return bounds.grow(margin).has_point(point)
