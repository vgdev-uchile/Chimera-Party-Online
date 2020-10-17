extends Node2D

var rats = []

export var counter = 1 setget set_counter
func set_counter(value):
	counter = value
	$Label.text = "%d/%d" % [get_rats_clamped(), counter]

signal pushed
signal released

var is_pushed = false

var target_scale = 1
var min_scale = 0.5

onready var max_area_position = $Area2D.position.y

var move_rate = 2

onready var bi = $ButtonInteract
onready var a2d = $Area2D

func _ready() -> void:
	$Area2D.connect("body_entered", self, "on_body_entered")
	$Area2D.connect("body_exited", self, "on_body_exited")

func _physics_process(delta: float) -> void:
#	if Input.is_action_just_pressed("action_a"):
#		rpc("push")
#	if Input.is_action_just_pressed("action_b"):
#		rpc("release")
	if bi.scale.y != target_scale:
		var new_scale = bi.scale.y
		var dif = bi.scale.y - target_scale
		var dir = sign(dif)
		if abs(dif) > move_rate * delta:
			new_scale -= dir * move_rate * delta
		else:
			new_scale = target_scale
			$Label.text = "%d/%d" % [get_rats_clamped(), counter]
			if is_network_master():
				if get_rats_clamped() == counter and not is_pushed:
					is_pushed = true
					emit_signal("pushed")
					Debug.print("pushed_emited")
		bi.scale.y = new_scale
		a2d.position.y = max_area_position * new_scale


sync func add_rat(rat):
	rats.push_back(rat)
	push(rat)

sync func erase_rat(rat):
	rats.erase(rat)
	release(rat)

func on_body_entered(body: Node):
#	return
	print(body.global_position.y, " ", a2d.global_position.y)
	if body.is_network_master() and body.is_in_group("rat") and not body.get_path() in rats and not body.sticked_obj:
		rpc("add_rat", body.get_path())

func on_body_exited(body: Node):
	if body.is_network_master() and body.is_in_group("rat") and body.get_path() in rats:
		rpc("erase_rat", body.get_path())

func push(rat):
	var rat_node = get_node(rat)
	rat_node.sticked(a2d)
	target_scale = lerp(1, min_scale, 1.0 * get_rats_clamped()/counter)

sync func release(rat):
	if  rats.size() + 1 == counter and is_pushed:
		is_pushed = false
		emit_signal("released")
		Debug.print("released_emited")
	var rat_node = get_node(rat)
	rat_node.normal()
	target_scale = lerp(1, min_scale, 1.0 * get_rats_clamped()/counter)
	$Label.text = "%d/%d" % [get_rats_clamped(), counter]

func get_rats_clamped():
	return min(counter, rats.size())
