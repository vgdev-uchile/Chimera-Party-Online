extends KinematicBody2D

var _player
var rats

onready var playback = $AnimationTree.get("parameters/playback")

enum State {
	NORMAL, # normal movement
	STICKED, # moves with another object (no gravitiy)
}

var state = State.NORMAL setget set_state
func set_state(value):
	match state:
		State.STICKED:
			sticked_obj = null
	state = value
func normal():
	self.state = State.NORMAL
func sticked(obj):
	sticked_obj = obj
	self.state = State.STICKED
	


var sticked_obj: Node2D = null

sync var on_seesaw = false

var linear_vel = Vector2()
var target_vel = 0
var SPEED = 400
var SPEED_SQUARED = SPEED * SPEED

var INERTIA = 10

var facing_right = true

sync var stopped = true

var dead = false

var cheese_collected = false

var on_floor = false

var can_jump = false
var MAX_JUMP_TIME = 0.1
var jump_time = 0

var jumping = false
var did_jump = false

var snap = Vector2.DOWN * 13

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
#	$Label.text = name
	
	puppet_pos = position
	

sync func jump():
	linear_vel.y = -1.5 * SPEED
	jumping = true
	position.y -= 10

sync func crushed():
	dead = true
	rats.dead(self)
	playback.travel("crushed")
	set_physics_process(false)

sync func spiked(height):
	dead = true
	rats.dead(self)
	global_position.y = height
	playback.travel("spiked")
	set_physics_process(false)

sync func poisoned():
	dead = true
	collision_layer = 4
	collision_mask = 6
	rats.dead(self)
	playback.travel("spiked")

sync func death():
	dead = true
	rats.dead(self)
	set_physics_process(false)
	call_deferred("disable_collision", true)


func test():
	linear_vel = move_and_slide(linear_vel, Vector2.UP)

func _physics_process(delta):
	match state:
		State.NORMAL:
			move(delta)
		State.STICKED:
			move_sticked(delta)

func move(delta):
#	print(can_jump)
	if dead:
		linear_vel.x = lerp(linear_vel.x, 0, 0.5)
		linear_vel.y += 3 * SPEED * delta
		linear_vel = move_and_slide(linear_vel, Vector2.UP, false, 4, PI/4, false)
	else:
		if is_network_master():
			target_vel = Input.get_action_strength(move_right) - Input.get_action_strength(move_left)
			rset("puppet_target_vel", target_vel)
		else:
			target_vel = puppet_target_vel
		
		if stopped:
			target_vel = 0
		linear_vel.x = lerp(linear_vel.x, target_vel * SPEED, 0.5)
		linear_vel.y += 3 * SPEED * delta
		linear_vel = move_and_slide_with_snap(linear_vel, snap, Vector2.UP, false, 4, PI/4, false)
		on_floor = is_on_floor()
		
		# check stomp
		if is_network_master():
			for i in get_slide_count():
				var collision = get_slide_collision(i)
				if collision.collider.has_method("bump"):
					collision.collider.bump()
				if Vector2.UP.dot(collision.normal) == 1:
					if collision.collider.has_method("stomp"):
						collision.collider.stomp(self)
				if collision.collider is RigidBody2D:
					var rb: RigidBody2D = collision.collider
					rb.apply_impulse(collision.position - rb.global_position, -collision.normal * INERTIA)
				## TODO make the condition with an area enter and not here
				if collision.collider.is_in_group("seesaw") and on_seesaw:
					linear_vel.y += 17 * SPEED * delta
					collision.collider.push(collision.position)
		# TODO? the case where a pile of rats is crushed is missing
		# If this is addressed, the death animation must be changed
		# now it only plays the animation and stops physics
		# so the rats on top will not fall
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
			jump_time += delta
			if on_floor:
				can_jump = true
				jump_time = 0
				snap = Vector2.DOWN * 13
			if jump_time > MAX_JUMP_TIME:
				can_jump = false
			if can_jump and Input.is_action_just_pressed(move_up) and not stopped:
				rpc("jump")
				snap = Vector2.ZERO
				can_jump = false
		
		if dead:
			return
		
		# Animation
		animation()


func animation():
	
	
	if abs(target_vel) > 0:
		playback.travel("run")
	else:
		playback.travel("idle")
	
	if target_vel < 0 and facing_right:
		flip()
	if target_vel > 0 and not facing_right:
		flip()

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
#	stop()
#	normal()
	position = pos
	puppet_pos = pos
#	reset()
#	cheese_collected = false
#	dead = false

func flip():
	facing_right = !facing_right
	$Sprite.scale.x *= -1

func stop():
	target_vel = 0
	puppet_target_vel = 0
	linear_vel = Vector2()

func reset():
	$Sprite.position = Vector2(0, -13)
	$Sprite.scale = Vector2(4, 4)
	if not facing_right:
		facing_right = true
	playback.travel("idle")
	

func disable_collision(value):
	$CollisionShape2D.disabled = value
	$CollisionShape2D2.disabled = value


