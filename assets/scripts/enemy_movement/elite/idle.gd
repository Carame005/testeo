extends EliteState

## Waits until the player enters aggro range.

@export var aggro_range: float = 110.0


func enter(_from: StringName = &"") -> void:
	if brain == null:
		return
	brain.get_enemy().velocity = Vector2.ZERO
	brain.set_shield_active(true)
	brain.play_defense_anim()


func physics_update(_delta: float) -> void:
	if brain == null:
		return
	brain.get_enemy().velocity = Vector2.ZERO
	brain.play_defense_anim()
	var player: Node2D = brain.get_player()
	if player == null:
		return
	var dist: float = brain.get_enemy().global_position.distance_to(player.global_position)
	if dist <= aggro_range:
		brain.change_state(&"aggressive")
