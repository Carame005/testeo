extends Node2D

signal damaged(amount: int, current_health: int)
signal died

@export var max_health: int = 3

var health: int


func _ready() -> void:
	health = max_health


func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	health = maxi(health - amount, 0)
	damaged.emit(amount, health)
	if health <= 0:
		died.emit()
