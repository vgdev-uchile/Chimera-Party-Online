extends Node2D

signal check_next

onready var cheese_counter = Party.get_players().size() * 2 - 2

func _ready() -> void:
	$Cheese.counter = cheese_counter
	if is_network_master():
		$Cheese.connect("collected", self, "emit_check_next")

func emit_check_next():
	emit_signal("check_next")
