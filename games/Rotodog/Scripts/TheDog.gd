extends Spatial

export (Color) var color
var material: Material
var player
var playerNode
var score = 0
remotesync var current_dance = 0
var dances_1 = [
	"Rumba",
	"CanCan",
	"Salsa",
	"Samba",
	"Samba2",
	"Samba3",
	"Samba4",
	"Swing"
]
var n_dances_1 = dances_1.size()

var dances_2 = [
	"BellyDancing",
	"ArmsHipHop",
	"BreakDanceFreeze",
	"BreakDanceFreeze3",
	"RoboHipHop",
	"SnakeHipHop"
]
var n_dances_2 = dances_2.size()

var end_poses = [
	"FemalePose1",
	"FemalePose2",
	"FemalePose3",
	"FemalePose4",
	"FemalePose5",
	"BreakDanceEnding1"
]
var n_endings = end_poses.size() - 1

var colors = [
	Color.green,
	Color.red,
	Color.yellow,
	Color.blue
]

onready var label_holder = $RootNode/LabelHolder
onready var name_label = label_holder.get_node("NameLabel/Name")
onready var rot_label = label_holder.get_node("NameLabel/Rotations")


func _ready():
	material = $RootNode/Object_3_Mesh_0.get_surface_material(0).duplicate()
	$RootNode/Object_3_Mesh_0.set_surface_material(0, material)
	material = $RootNode/Object_3_Mesh_0.get_surface_material(0)
	$RootNode/AnimationPlayer.play("Rumba")
	$AnimationPlayer.play("rotate")
	name_label.set("custom_fonts/normal_font",
		name_label.get_font("normal_font").duplicate())
	rot_label.set("custom_fonts/normal_font",
		rot_label.get_font("normal_font").duplicate())


func init(p: Player):
	player = p
	set_network_master(p.nid)
	color = colors[p.color]
	name_label.get_font("normal_font").outline_color = color
	rot_label.get_font("normal_font").outline_color = color
	name_label.parse_bbcode(
		"[center][rainbow freq=0.1 sat=0.7 val=1]{name}[/rainbow][/center]".format(
			{"name": p.name}))
	name = p.nid
	material.albedo_color = color
	if is_network_master():
		playerNode.init(p, self)


func _physics_process(delta):
	var pos = label_holder.global_transform.origin
	var cam = get_tree().get_root().get_camera()
	var screenpos = cam.unproject_position(pos) + Vector2(-100, -94)
	label_holder.get_node("NameLabel").set_position(screenpos)


remotesync func add_score(s):
	score += s
	update_score_label()


func update_score_label():
	rot_label.parse_bbcode(
		"[center][rainbow freq=0.1 sat=0.7 val=1]{score}[/rainbow][/center]".format(
			{"score": score}
		))

func change_dance(n):
	if is_network_master():
		match n:
			0:
				rpc("dance", dances_1[randi() % n_dances_1])
			1:
				if $RootNode/AnimationPlayer.current_animation in end_poses:
					rpc("dance", "BellyDancing")
				else:
					rpc("dance", dances_2[randi() % n_dances_2])
			2:
				rpc("dance", "FemalePose4")
			3:
				rpc("dance", end_poses[randi() % n_endings])
			4:
				rpc("dance", end_poses[n_endings])
			

remotesync func dance(d):
	$RootNode/AnimationPlayer.play(d)
