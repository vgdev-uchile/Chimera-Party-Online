extends Node2D

signal check_next

onready var cheese_counter = Party.get_players().size() * 2

func _ready() -> void:
	$Options/Cheese.counter = cheese_counter
	if is_network_master():
		$Options/Cheese.connect("collected", self, "emit_check_next")
	randomize()
	var indices = range(4)
	indices.shuffle()
	for i in $Options.get_child_count():
		$Options.get_child(i).global_position = $OptionsPositions.get_child(indices[i]).global_position

func emit_check_next():
	emit_signal("check_next")
