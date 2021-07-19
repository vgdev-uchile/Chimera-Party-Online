extends KinematicBody2D


export var SPEED: float = 500
var linear_vel = Vector2()

var player
var player_index
var player_color

# Inputs
var move_left = ""
var move_right = ""
var move_up = ""
var move_down = ""
var action_a = ""
var action_b = ""
var stopped = false
puppet var puppet_pos = Vector2()
puppet var puppet_target_vel = Vector2()


func init(p: Player):
	player = p
	set_network_master(player.nid)
	$Sprite.modulate = Party._colors[player.color]
	var ks = str(player.keyset)
	move_left = "move_left_" + ks
	move_right = "move_right_" + ks
	move_up = "move_up_" + ks
	move_down = "move_down_" + ks
	action_a = "action_a_" + ks
	action_b = "action_b_" + ks
	name = "basket_" + str(player.nid)


func _physics_process(delta):
	if stopped: return
	var target_vel
	
	if is_network_master():
		target_vel = Vector2(
			Input.get_action_strength(move_right) - Input.get_action_strength(move_left),
			Input.get_action_strength(move_down) - Input.get_action_strength(move_up)) * SPEED
		rset("puppet_pos", position)
		rset("puppet_target_vel", target_vel)
	else:
		target_vel = puppet_target_vel
		position = lerp(position, puppet_pos, 0.5)
	
	linear_vel = lerp(linear_vel, target_vel, 0.2)
	move_and_slide(linear_vel)


# get_max_price_in_basket: None -> Price
# gets the price with the most value in the basket
func get_max_price_in_basket():
	var prices = self.get_prices_in_basket()
	var max_price = null
	for i in range(prices.size()):
		var price = prices[i]
		if max_price == null:
			max_price = price
		elif price.get_value() > max_price.get_value():
			price = max_price
	
	return max_price

# get_prices_in_basket: None -> Array(Price)
# gets the prices inside the basket
func get_prices_in_basket():
	return $CatchedObjectCollision.get_overlapping_bodies()
	
func get_player_index():
	return player.index

func stop_physics():
	stopped = true

	
	
