extends KinematicBody2D


var sprites = [
	preload("res://games/hexfall/sprites/Dino/DinoSprites - vita.png"),
	preload("res://games/hexfall/sprites/Dino/DinoSprites - mort.png"),
	preload("res://games/hexfall/sprites/Dino/DinoSprites - tard.png"),
	preload("res://games/hexfall/sprites/Dino/DinoSprites - doux.png")]

var linear_vel = Vector2()
var SPEED = 400
var SPEED_SQUARED = SPEED * SPEED

var friction = 0.2
var delta_acc = 0

sync var dead = false setget set_dead
func set_dead(value):
	dead = value
	if dead:
		playback.travel("dead")
		$CollisionPolygon2D.disabled = true
		$Shadow.hide()
		emit_signal("died", _player)
var stopped = false
signal died

# networking
puppet var puppet_pos = Vector2()
puppet var puppet_target_vel = Vector2()

# TODO: Future feature, make dino able to jump
# there must be an height variable 
# and only dinos whithin certain height diff must collide
#var in_air = false

onready var playback = $AnimationTree.get("parameters/playback")

# Inputs

var move_left = "move_left"
var move_right = "move_right"
var move_up = "move_up"
var move_down = "move_down"
var action_a = "action_a"
var action_b = "action_b"

var _player

func _ready():
	puppet_pos = position

func init(player: Player):
	_player = player
	set_network_master(player.nid)
	name = str("%s - %s" % [player.nid, player.local])
	$Sprite.texture = sprites[player.color]
	var ks = str(player.keyset)
	move_left = "move_left_" + ks
	move_right = "move_right_" + ks
	move_up = "move_up_" + ks
	move_down = "move_down_" + ks
	action_a = "action_a_" + ks
	action_b = "action_b_" + ks
	
	puppet_pos = position
#	set_physics_process(true)
	
func check_death():
	var space_state = get_world_2d().direct_space_state
	var result_left = space_state.intersect_point($FloorCheckLeft.global_position, 1, [], 2)
	var result_right = space_state.intersect_point($FloorCheckRight.global_position, 1, [], 2)
	return not result_left and not result_right


func _physics_process(delta):
	if dead:
		linear_vel = linear_vel.linear_interpolate(Vector2.ZERO, 0.2)
		linear_vel = move_and_slide(linear_vel)
		delta_acc += 3 * delta
		var scale_factor = 4 - delta_acc
		if z_index == 0 and scale_factor < 3:
			z_index = -1
		$Sprite.scale = Vector2.ONE * max(0, scale_factor)
	else:
		if is_network_master():
			var res = check_death()
			if res:
				rset("dead", true)
				return
		
		# movement
		var target_vel
		if is_network_master():
			target_vel = Vector2(
				Input.get_action_strength(move_right) - Input.get_action_strength(move_left),
				Input.get_action_strength(move_down) - Input.get_action_strength(move_up))
			rset("puppet_target_vel", target_vel)
		else:
			target_vel = puppet_target_vel
		if target_vel.length_squared() > 1:
			target_vel = target_vel.normalized()
		if stopped:
			target_vel = Vector2()
		var speed = SPEED
		if playback.get_current_node() == "kick":
			speed *= 0.5
		
		linear_vel = linear_vel.linear_interpolate(target_vel * speed, 0.2)
		linear_vel = move_and_slide(linear_vel)
		
		# fix position
		if is_network_master():
			rset("puppet_pos", position)
		else:
			position = lerp(position, puppet_pos, 0.5)
			puppet_pos = position
		
		# actions
	#	var jump = Input.is_action_just_pressed(action_a)
		var kick = Input.is_action_just_pressed(action_a)
		
	#	if jump:
	#		playback.travel("jump")
	#		in_air = true
		
	#	if kick and not in_air:
		if kick:
			playback.travel("kick")
	
		# Animation
		
	#	if not in_air and not kick:
		if not kick:
			if linear_vel.length_squared() > 10 :
				playback.travel("run")
				$AnimationTree.set("parameters/run/TimeScale/scale", 0.5 + linear_vel.length_squared() / SPEED_SQUARED)
			else:
				playback.travel("idle")
		
		if target_vel.x < 0:
			$Sprite.flip_h = true
		if target_vel.x > 0:
			$Sprite.flip_h = false

func stop():
	stopped = true
