extends Area2D

func _ready():
	var _error = connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body: Node2D):
	if body.is_in_group("Pac-Partier"):
		body.global_position = $Out.global_position
