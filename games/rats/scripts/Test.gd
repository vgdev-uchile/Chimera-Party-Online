extends KinematicBody2D

onready var initial_position = position

var acc = 0

func _physics_process(delta: float) -> void:
	position.y = initial_position.y + 200 * sin(acc)
	acc += delta
