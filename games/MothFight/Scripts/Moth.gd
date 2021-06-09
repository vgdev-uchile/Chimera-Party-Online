extends RigidBody2D

export (int) var max_speed
export (int) var acceleration #10
export (int) var player_index
export (int, "Verde", "Rojo", "Amarillo", "Azul") var player_color
var score_counter = null

var move_left = "move_left"
var move_right = "move_right"
var move_up = "move_up"
var move_down = "move_down"
var action_a = "action_a"
var action_b = "action_b"

var player

# networking
puppet var puppet_pos = Vector2()
puppet var puppet_target_vel = Vector2()
puppet var puppet_linear_vel = Vector2()


func _ready():
	puppet_pos = position


func init(p: Player):
	player = p
	set_network_master(p.nid)
	$AnimatedSprite.modulate = Party._colors[p.color]
	var spi = str(p.keyset)
	move_left = "move_left_" + spi
	move_right = "move_right_" + spi
	move_up = "move_up_" + spi
	move_down = "move_down_" + spi
	action_a = "action_a_" + spi
	action_b = "action_b_" + spi
	name = "%d - %d" % [p.nid, p.local]
	$Light2D.color = ["00ff00", "ff0000", "ffff00", "0000ff"][p.color]
	

func get_move_direction():
	var dir_h = Input.get_action_strength(move_right) - Input.get_action_strength(move_left)
	var dir_v = Input.get_action_strength(move_down) - Input.get_action_strength(move_up)
	return Vector2(dir_h, dir_v)

func _integrate_forces(state: Physics2DDirectBodyState):
	var delta = state.step
	var target_vel
	
	if is_network_master():
		target_vel = get_move_direction()
		rset_unreliable("puppet_target_vel", target_vel)
	else:
		target_vel = puppet_target_vel
	
	if target_vel.length_squared() > 1:
		target_vel = target_vel.normalized()
	
	if target_vel.x != 0:
		$AnimatedSprite.scale.x = 3 * sign(target_vel.x)
	
	if is_network_master():
		apply_central_impulse(target_vel * acceleration * delta)
		rset("puppet_pos", position)
		rset_unreliable("puppet_linear_vel", state.linear_velocity)
	else:
		var pvel = (puppet_pos - position) * delta
		state.linear_velocity = lerp(state.linear_velocity, puppet_linear_vel + pvel, 0.5)
		puppet_linear_vel = state.linear_velocity
		state.transform.origin = lerp(position, puppet_pos, 0.5)
		puppet_pos = state.transform.origin


func _on_Moth_body_entered(body):
	if linear_velocity.length() > 150 and abs(linear_velocity.y) > 11:
		$HitSound.play()
	if is_network_master() and body.has_method("switch") and body.on:
		body.rpc("switch", false)
		body.controller.rpc("add_score", player.color, body.color)
		body.controller.rpc("start_timer")

func get_score():
	return score_counter.score

