extends Node2D

signal next

func _ready() -> void:
	$Cheese.counter = Party.get_players().size() * 2
	$Cheese.connect("collected", self, "on_collected")

func on_collected():
	emit_signal("next")

func start():
	$Cheese.enable()
