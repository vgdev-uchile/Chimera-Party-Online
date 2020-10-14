extends Area2D

# This code sync all the players but later only host state is consulted
# Maybe it should only update the host for data and the client for visuals

signal collected

var rats = []

export var counter = 7 setget set_counter
func set_counter(value):
	counter = value
	$Label.text = "x%d" % value

func _ready() -> void:
	connect("body_entered", self, "on_body_entered")

func on_body_entered(body: Node):
	if body.is_network_master() and body.is_in_group("rat") and not body.get_path() in rats:
		rpc("add_rat", body.get_path())

sync func add_rat(rat):
	rats.push_back(rat)
	self.counter -= 1
	var rat_node = get_node(rat)
	rat_node.rats.cheese += 1
	if counter == 0:
		emit_signal("collected")
		queue_free()
