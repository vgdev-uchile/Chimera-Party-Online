extends Node2D

signal check_next

onready var cheese_counter = Party.get_players().size() * 2

func _ready() -> void:
	$Options/Cheese.counter = cheese_counter
	$Options/PoisonCheese.counter = cheese_counter
	$Options/PoisonCheese2.counter = cheese_counter
	$Options/PoisonCheese3.counter = cheese_counter
	if is_network_master():
		$Options/Cheese.connect("collected", self, "emit_check_next")
		$Options/PoisonCheese.connect("collected", self, "emit_check_next_poison")
		$Options/PoisonCheese2.connect("collected", self, "emit_check_next_poison")
		$Options/PoisonCheese3.connect("collected", self, "emit_check_next_poison")
	randomize()
	var indices = range(4)
	indices.shuffle()
	for i in $Options.get_child_count():
		$Options.get_child(i).global_position = $OptionsPositions.get_child(indices[i]).global_position

func emit_check_next():
	cheese_counter -= 1
	for cheese in $Options.get_children():
		cheese.counter = cheese_counter
	emit_signal("check_next")

func emit_check_next_poison():
	emit_signal("check_next")
