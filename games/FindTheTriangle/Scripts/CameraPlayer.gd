extends Spatial

export var invert_x = false
export var invert_y = false

var sensitivity = 1
# Inputs

var rotate_left  = "move_left"
var rotate_right = "move_right"
var rotate_up    = "move_up"
var rotate_down  = "move_down"
var rotate_ccw   = "action_a"
var rotate_cw    = "action_b"

var available_colors = [Color("00ff00"), Color("ff0000"), Color("ffff00"), Color("0000ff")]

var _player
var slot
var this_win
var this_crosshair
var has_win = false
signal win

onready var RCFront = get_node("Gimbal_rot/Front")
onready var RCUp    = get_node("Gimbal_rot/Up")

puppet var puppet_rot = [0,0,0]
#puppet var puppet_target_rot

func init(player: Player, crosshair, win, namelabel):
	_player = player
	set_network_master(player.nid)
	var ks = str(player.keyset)
	rotate_left  = "move_left_"  + ks
	rotate_right = "move_right_" + ks
	rotate_up    = "move_up_"    + ks
	rotate_down  = "move_down_"  + ks
	rotate_ccw   = "action_a_"   + ks
	rotate_cw    = "action_b_"   + ks
	name = "%d - %d" % [player.nid, player.local]
	slot = player.slot
	this_crosshair = crosshair
	this_win = win
	namelabel.set_text(player.name)
	namelabel.set("custom_colors/font_color", available_colors[player.color])
	namelabel.show()


func _physics_process(delta: float) -> void:
	# Obtener input
	var target_rot
	if is_network_master():
		if not has_win:
			target_rot = get_input(delta)
		else:
			target_rot = [0,0,0]
		rset("puppet_rot", target_rot)
	else:
		target_rot = puppet_rot
	# Rotar personaje
	rotate_cam(delta,target_rot[0],target_rot[1],target_rot[2])
	# Revisar si gana
	if is_network_master():
		RCFront.force_raycast_update()
		RCUp.force_raycast_update()
		if RCFront.is_colliding() and RCUp.is_colliding():
			if RCFront.get_collider().is_in_group("Front") and RCUp.get_collider().is_in_group("Up") and not has_win:
				rpc("just_win")

func get_input(delta):
	# Obtener los inputs del jugador
	var h_rot = Input.get_action_strength(rotate_right) - Input.get_action_strength(rotate_left)
	var v_rot = Input.get_action_strength(rotate_down)  - Input.get_action_strength(rotate_up)
	var p_rot = Input.get_action_strength(rotate_ccw)   - Input.get_action_strength(rotate_cw)
	return [h_rot,v_rot,p_rot]

func rotate_cam(delta,h_rot,v_rot,p_rot):
	# Rotar los gimbals correspondientes
	$Gimbal_rot.rotate_object_local(Vector3.UP, -h_rot * delta * sensitivity)
	$Gimbal_rot.rotate_object_local(Vector3.RIGHT, -v_rot * delta * sensitivity)
	$Gimbal_rot.rotate_object_local(-Vector3.FORWARD, p_rot * delta * sensitivity)

remotesync func just_win():
	has_win = true
	this_crosshair.hide()
	this_win.show()
	emit_signal("win",slot)
