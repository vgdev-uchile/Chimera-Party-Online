extends RigidBody2D

var sprites = [
	preload("res://games/extinct/sprites/Dino/DinoSprites - vita.png"),
	preload("res://games/extinct/sprites/Dino/DinoSprites - mort.png"),
	preload("res://games/extinct/sprites/Dino/DinoSprites - tard.png"),
	preload("res://games/extinct/sprites/Dino/DinoSprites - doux.png")]

var SPEED = 2000
var SPEED_SQUARED = 4000000

sync var dead = false setget set_dead
func set_dead(value):
	dead = value
	print(dead)
	if dead:
		playback.travel("dead")
		linear_damp *= 5
#		$CollisionShape2D.disabled = true
		emit_signal("died", _player)
signal died
var stopped = false

# networking
puppet var puppet_pos = Vector2()
puppet var puppet_target_vel = Vector2()
puppet var puppet_linear_vel = Vector2()
puppet var puppet_kick = false

onready var playback = $AnimationTree.get("parameters/playback")

# Inputs

var move_left = "move_left"
var move_right = "move_right"
var move_up = "move_up"
var move_down = "move_down"
var action_a = "action_a"
var action_b = "action_b"

var _player

func _ready() -> void:
	puppet_pos = position

func init(player: Player):
	_player = player
	set_network_master(player.nid)
	$shadow_2/Sprite.texture = sprites[player.color]
	var ks = str(player.keyset)
	move_left = "move_left_" + ks
	move_right = "move_right_" + ks
	move_up = "move_up_" + ks
	move_down = "move_down_" + ks
	action_a = "action_a_" + ks
	action_b = "action_b_" + ks
	name = "%d - %d" % [player.nid, player.local]

func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	
	
	if dead:
		return
		
	var delta = state.step
	
	# Movement
	
	var target_vel
	if is_network_master():
		target_vel = Vector2(
			Input.get_action_strength(move_right) - Input.get_action_strength(move_left),
			Input.get_action_strength(move_down) - Input.get_action_strength(move_up))
		rset_unreliable("puppet_target_vel", target_vel)
	else:
		target_vel = puppet_target_vel
	if target_vel.length_squared() > 1:
		target_vel = target_vel.normalized()
	if stopped:
		target_vel = Vector2()
	if is_network_master():
		apply_central_impulse(target_vel * SPEED * delta)
	
	# fix position
	if is_network_master():
		rset("puppet_pos", position)
		rset_unreliable("puppet_linear_vel", state.linear_velocity)
	else:
		var pvel = (puppet_pos - position) * delta
		state.linear_velocity = lerp(state.linear_velocity, puppet_linear_vel + pvel, 0.5)
		puppet_linear_vel = state.linear_velocity
		state.transform.origin = lerp(position, puppet_pos, 0.5)
		puppet_pos = state.transform.origin
	
	# Actions
	var kick
	if is_network_master():
		kick = Input.is_action_just_pressed(action_a)
		rset("puppet_kick", kick)
	else:
		kick = puppet_kick
	
	# Animation
	if kick:
		playback.travel("kick")
		if target_vel != Vector2.ZERO:
			apply_central_impulse(target_vel * 20 * SPEED * delta)
	else:
		if linear_velocity.length_squared() > 300:
			playback.travel("run")
			$AnimationTree.set("parameters/run/TimeScale/scale", 0.5 + 10 * linear_velocity.length_squared() / SPEED_SQUARED)
		else:
			playback.travel("idle")
	
	if target_vel.x < 0:
		$shadow_2/Sprite.flip_h = true
	if target_vel.x > 0:
		$shadow_2/Sprite.flip_h = false

func stop():
	linear_damp *= 10
	stopped = true
