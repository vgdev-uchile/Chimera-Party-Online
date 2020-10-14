extends KinematicBody2D

var _player
var rats

onready var playback = $AnimationTree.get("parameters/playback")

enum State {
	NORMAL, # normal movement
	STICKED # moves with another object (no gravitiy)
}

var state = State.NORMAL setget set_state
func set_state(value):
	state = value
func normal():
	sticked_obj = null
	self.state = State.NORMAL
func sticked(obj):
	sticked_obj = obj
	self.state = State.STICKED

var sticked_obj = null

var linear_vel = Vector2()
var target_vel = 0
var SPEED = 400
var SPEED_SQUARED = SPEED * SPEED

var facing_right = true

sync var stopped = true


var dead = false

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

#onready var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	puppet_pos = position

func init(player: Player, index, rats):
	_player = player
	self.rats = rats
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
	linear_vel.y = -1.5 * SPEED

sync func crushed():
	dead = true
	playback.travel("crushed")

func test():
	linear_vel = move_and_slide(linear_vel, Vector2.UP)

func _physics_process(delta):
	match state:
		State.NORMAL:
			move(delta)
		State.STICKED:
			move_sticked(delta)

func move(delta):
	if not dead:
		if is_network_master():
			target_vel = Input.get_action_strength(move_right) - Input.get_action_strength(move_left)
			rset("puppet_target_vel", target_vel)
		else:
			target_vel = puppet_target_vel
		
		if stopped:
			target_vel = 0
		
		linear_vel.x = lerp(linear_vel.x, target_vel * SPEED, 0.5)
		linear_vel.y += 3 * SPEED * delta
		linear_vel = move_and_slide(linear_vel, Vector2.UP)

		
		# check stomp
		if is_network_master():
			for i in get_slide_count():
				var collision = get_slide_collision(i)
				if Vector2.UP.dot(collision.normal) == 1:
					if collision.collider.has_method("stomp"):
						collision.collider.stomp(self)
			
		
		# check crushed
		if is_network_master():
			var ss = get_world_2d().direct_space_state
			var query = Physics2DShapeQueryParameters.new()
			query.set_shape($Above.shape)
			query.transform.origin = $Above.global_position
			query.exclude = [self]
			query.collision_layer = 2
			var result = ss.intersect_shape(query)
			$Below.force_raycast_update()
			if result.size() > 0 and $Below.is_colliding():
				rpc("crushed")
		
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
		
		if dead:
			return
		
		# Animation
		animation()


func animation():
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

func move_sticked(delta):
	if is_network_master():
		target_vel = Input.get_action_strength(move_right) - Input.get_action_strength(move_left)
		rset("puppet_target_vel", target_vel)
	else:
		target_vel = puppet_target_vel
	
	if stopped:
		target_vel = 0
	
	linear_vel.x = lerp(linear_vel.x, target_vel * SPEED, 0.5)
	linear_vel = move_and_slide(linear_vel, Vector2.UP)
	
	global_position.y = sticked_obj.global_position.y - $Bottom.position.y
	
	if is_network_master():
		if Input.is_action_just_pressed(move_up) and not stopped:
			rpc("jump")
			normal()
	
	animation()
			
func teleport(pos):
	position = pos
	puppet_pos = pos
	puppet_target_vel = 0
	normal()
