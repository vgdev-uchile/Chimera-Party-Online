extends StaticBody2D

var delta_acc = 0

var rats = []

puppet var puppet_rotation = 0

onready var length = $CollisionShape2D.shape.extents.x * 2

func _ready() -> void:
	$Area2D.connect("body_entered", self, "on_body_entered")
	$Area2D.connect("body_exited", self, "on_body_exited")

func _physics_process(delta: float) -> void:
	var trot = 0
	for rat in rats:
		var rat_node = get_node(rat)
		var local_pos = rat_node.global_position - global_position
		trot += $Top.position.cross(local_pos) / length
	if trot == 0:
		rotation = lerp(rotation, 0, 0.001)
	else:
		rotation += trot / 100 * delta
	if is_network_master():
		rset("puppet_rotation", rotation)
	else:
		rotation = lerp(rotation, puppet_rotation, 0.5)
		puppet_rotation = rotation

sync func add_rat(rat):
	rats.push_back(rat)

sync func erase_rat(rat):
	rats.erase(rat)

func on_body_entered(body: Node):
	if body.is_network_master() and body.is_in_group("rat") and not body.get_path() in rats:
		rpc("add_rat", body.get_path())
		body.rset("on_seesaw", true)

func on_body_exited(body: Node):
	if body.is_network_master() and body.is_in_group("rat") and body.get_path() in rats:
		rpc("erase_rat", body.get_path())
		body.rset("on_seesaw", false)

func push(pos: Vector2):
	var local_pos = pos - global_position
	var force = $Top.position.cross(local_pos)
