extends Node

signal pushed
signal released

var total
var counter = 0

func _ready() -> void:
	total = get_child_count()
	for small_button in get_children():
		small_button.connect("pushed", self, "on_pushed")
		small_button.connect("released", self, "on_released")

func on_pushed():
	counter += 1
	emit_signal("pushed")

func on_released():
	counter -= 1
	if counter == 0:
		emit_signal("released")
