extends KinematicBody2D

var _player

onready var playback = $AnimationTree.get("parameters/playback")

var linear_vel = Vector2()
var SPEED = 400
var SPEED_SQUARED = SPEED * SPEED

var facing_right = true

sync var stopped = true

# networking
puppet var puppet_pos = Vector2()
puppet var puppet_target_vel = 0

# Inputs

var move_left = "move_left"
var move_right = "move_right"
var move_up = "move_up"
var move_down = "move_down"
var action_a = "action_a"
var action_b = "action_b"

func _ready():
	puppet_pos = position

func init(player: Player, index):
	_player = player
	set_network_master(player.nid)
#	$Sprite.texture = sprites[player.color]
	$Sprite.modulate = Party.get_colors()[player.color]
	$Label.text = player.name
	var ks = str(player.keyset)
	move_left = "move_left_" + ks
	move_right = "move_right_" + ks
	move_up = "move_up_" + ks
	move_down = "move_down_" + ks
	action_a = "action_a_" + ks
	action_b = "action_b_" + ks
	name = str("%d - %d - %d" % [player.nid, player.local, index])
	
	puppet_pos = position
	

sync func jump():
	linear_vel.y = -SPEED
	

func _physics_process(delta):
	
	var target_vel
	if is_network_master():
		target_vel = Input.get_action_strength(move_right) - Input.get_action_strength(move_left)
		rset("puppet_target_vel", target_vel)
	else:
		target_vel = puppet_target_vel
	
	if stopped:
		target_vel = 0
	
	linear_vel.x = lerp(linear_vel.x, target_vel * SPEED, 0.5)
	linear_vel.y += 2 * SPEED * delta
	linear_vel = move_and_slide(linear_vel, Vector2.UP)
	
	# fix position
	if is_network_master():
		rset("puppet_pos", position)
	else:
		position = lerp(position, puppet_pos, 0.5)
		puppet_pos = position
	
	if is_network_master():
		var on_floor = is_on_floor()
		if on_floor and Input.is_action_just_pressed(move_up) and not stopped:
			rpc("jump")
	
	# Animation
	if abs(linear_vel.x) > 10:
		playback.travel("run")
	else:
		playback.travel("idle")
	
	if target_vel < 0 and facing_right:
		facing_right = false
		scale.x = -1
	if target_vel > 0 and not facing_right:
		facing_right = true
		scale.x = -1


	
