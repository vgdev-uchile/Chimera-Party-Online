extends KinematicBody2D

# Misc
export (bool) var is_pac = false

# API
var _player
var slot

# Movement Input
var move_left  = "move_left"
var move_right = "move_right"
var move_up    = "move_up"
var move_down  = "move_down"
var action_a   = "action_a"
var action_b   = "action_b"

# Multiplayer
puppet var puppet_mov = Vector2(0,0)
var _init_position

# Properties
const SPEED = 1


func init(player: Player, init_position: Vector2, should_be_pac):
	_player = player
	set_network_master(player.nid)
	var ks = str(player.keyset)
	move_left  = "move_left_"  + ks
	move_right = "move_right_" + ks
	move_up    = "move_up_"    + ks
	move_down  = "move_down_"  + ks
	action_a   = "action_a_"   + ks
	action_b   = "action_b_"   + ks
	name = "%d - %d" % [player.nid, player.local]
	slot = player.slot
	_init_position = init_position
	is_pac = should_be_pac
	# cambiar color
	$Sprite.modulate = Party.get_colors()[_player.color]

func _ready() -> void:
	position = _init_position

func _physics_process(delta: float) -> void:
	# Obtener input
	var target_mov
	if is_network_master():
		target_mov = get_input(delta)
		rset_unreliable("puppet_mov", target_mov)
	else:
		target_mov = puppet_mov
	# Procesar input
	target_mov = target_mov.normalized()
	move_and_collide(target_mov * SPEED * delta)
#	rotate_cam(delta,target_rot[0],target_rot[1],target_rot[2])
	# Revisar si gana
	if is_network_master():
		pass

func get_input(_delta):
	return Vector2(Input.get_action_strength(move_right) - Input.get_action_strength(move_left),
					Input.get_action_strength(move_down) - Input.get_action_strength(move_up))
