extends Node2D

signal check_next

func _ready() -> void:
	$Cheese.counter = Party.get_players().size() * 2
	if is_network_master():
		$Cheese.connect("collected", self, "emit_check_next")

func emit_check_next():
	emit_signal("check_next")
