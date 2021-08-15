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
puppet var puppet_mov = Vector2.ZERO
var _init_position
var in_list_slot

# Properties
const SPEED_G = 5
const SPEED_P = 18
var speed
const DEADZONE = 0.1
const TEXTURES = {"Ghost": preload("res://games/Pac-Party/sprites/ghost_spritesheet.png"),
				  "Pac":   preload("res://games/Pac-Party/sprites/player_spritesheet.png")}

# State
var mov_direction = Vector2.ZERO
var last_move_dir = Vector2.ZERO
var target_tile   = Vector2.ZERO 

var is_alive = false
var has_win  = false

var dot_objective =  1
remotesync var dot_current   =  0

# Powers
var can_team_action= true
var can_invincible = true
var can_boost      = true
const DURATION_INVINCIBLE = 1.5
const COOLDOWN_INVINCIBLE = 15
const DURATION_BOOST      = 2.0
const COOLDOWN_BOOST      = 10
const COOLDOWN_TEAMACTION = 7.5

var map
var map_offset
onready var area = $CollisionArea


# Signals
signal pac_win
signal pac_dead


func init(player: Player, init_position: Vector2, player_slot, map_pointer, dots):
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
	is_pac = slot == 0
	in_list_slot = player_slot
	map = map_pointer
	map_offset = map.get_cell_size()/2
	# cambiar sprite y velocidad
	speed = SPEED_G
	if is_pac:
		$Sprite.texture = TEXTURES["Pac"]
		speed = SPEED_P
		dot_objective = dots
	# sprite color y name tag
	$Sprite.modulate = Party.get_colors()[_player.color]
	$HBoxContainer/NameTag.text = player.name 


func _ready() -> void:
	position = _init_position
	puppet_mov = _init_position
	var _error = area.connect("body_entered", self, "on_body_entered")
	yield(get_tree().create_timer(1), "timeout")
	$CollisionArea/Collision.disabled = false
	is_alive = true


func _physics_process(delta: float) -> void:
	if is_alive:
		# Obtener input
		var target_mov = Vector2.ZERO
		if is_network_master():
			target_mov = get_input(delta)
			target_mov = target_mov.normalized()
			target_tile = cell_move(target_mov)
			rset_unreliable("puppet_mov", target_tile)
			if invincible_trigger():
				invincible()
			if boost_trigger():
				rpc("boost")
		else:
			target_tile = puppet_mov
		# Procesar input
		position = position.linear_interpolate(target_tile, speed * delta)
		# Procesar animacion
		if is_network_master():
			animation_controller()
		# Checkear si pac ganó
		if is_network_master() and is_pac and not has_win:
			if dot_current >= dot_objective:
				has_win = true
				emit_signal("pac_win")


func get_input(_delta):
	if Input.get_action_strength(move_right) > DEADZONE:
		mov_direction = Vector2.RIGHT
	elif Input.get_action_strength(move_left) > DEADZONE:
		mov_direction = Vector2.LEFT
	if Input.get_action_strength(move_up) > DEADZONE:
		mov_direction = Vector2.UP
	elif Input.get_action_strength(move_down) > DEADZONE:
		mov_direction = Vector2.DOWN
	return mov_direction


func cell_move(movement):
	var current_tile = map.world_to_map(position)
	var next_tile_try = map.get_cellv(current_tile + movement)
	var next_tile_pos
	if next_tile_try == map.INVALID_CELL:
		next_tile_pos = map.map_to_world(current_tile + movement) + map_offset
		last_move_dir = movement
	elif map.get_cellv(current_tile + last_move_dir) == map.INVALID_CELL:
		next_tile_pos = map.map_to_world(current_tile + last_move_dir) + map_offset
	else:
		next_tile_pos = map.map_to_world(current_tile) + map_offset
	return next_tile_pos


remotesync func animation_controller():
	if last_move_dir == Vector2.LEFT:
		$Sprite.flip_h = false if is_pac else true
		$AnimationPlayer.play("Hmove")
	elif last_move_dir == Vector2.RIGHT:
		$Sprite.flip_h = true if is_pac else false
		$AnimationPlayer.play("Hmove")
	elif last_move_dir == Vector2.UP:
		$Sprite.flip_h = false
		$AnimationPlayer.play("VmoveUp")
	elif last_move_dir == Vector2.DOWN:
		$Sprite.flip_h = false
		$AnimationPlayer.play("VmoveDown")
	else:
		$Sprite.flip_h = false
		$AnimationPlayer.play("Idle")


func invincible_trigger():
	return is_pac and can_invincible and Input.is_action_just_pressed(action_a)


func invincible():
	can_invincible = false
	rpc("_make_invincible")
	yield(get_tree().create_timer(DURATION_INVINCIBLE), "timeout")
	rpc("_unmake_invincible")
	yield(get_tree().create_timer(COOLDOWN_INVINCIBLE), "timeout")
	rpc("_cooldw_invincible")
	can_invincible = true

remotesync func _make_invincible():
	$CollisionArea/Collision.disabled = true
	$Sprite.modulate.a = 0.4
	$HBoxContainer/NameTag.text = "Power Used"

remotesync func _unmake_invincible():
	$CollisionArea/Collision.disabled = false
	$Sprite.modulate.a = 0.7
	$HBoxContainer/NameTag.text = "Power Charging"

remotesync func _cooldw_invincible():
	$Sprite.modulate.a = 1.0
	$HBoxContainer/NameTag.text = "Power Ready"
	yield(get_tree().create_timer(2), "timeout")
	$HBoxContainer/NameTag.text = _player.name

func boost_trigger():
	return not is_pac and can_boost and Input.is_action_just_pressed(action_a)


remotesync func boost():
	can_boost = false
	speed += 5
	$Sprite.modulate.a = 0.5
	$HBoxContainer/NameTag.text = "Power Used"
	yield(get_tree().create_timer(DURATION_BOOST), "timeout")
	speed = SPEED_G
	$Sprite.modulate.a = 0.7
	$HBoxContainer/NameTag.text = "Power Charging"
	yield(get_tree().create_timer(COOLDOWN_BOOST), "timeout")
	can_boost = true
	$Sprite.modulate.a = 1.0
	$HBoxContainer/NameTag.text = "Power Ready"
	yield(get_tree().create_timer(2), "timeout")
	$HBoxContainer/NameTag.text = _player.name


func on_body_entered(body: Node2D):
	if is_network_master():
		if body.is_in_group("Pac-Partier"):
			if is_pac and not body.is_pac:
				rpc("die")
			elif not is_pac and not body.is_pac:
				rpc("teammate_action")
		elif is_pac and body.is_in_group("Pac-Point"):
			body.call_destruction()
			rset("dot_current", dot_current + 1)


remotesync func die():
	if is_alive:
		is_alive = false
		emit_signal("pac_dead", self, dot_objective/dot_current)
	

remotesync func teammate_action():
	if can_team_action:
		can_team_action = false
#		print("TEAMM8 ACTION")
		# summonear coso
		yield(get_tree().create_timer(COOLDOWN_TEAMACTION), "timeout")
		can_team_action = true


func set_max_dots(qty):
	dot_objective = qty

# DEBUG
#func _unhandled_key_input(event):
#	if is_network_master() and event.is_pressed() and event.scancode == KEY_SPACE:
#		if is_pac:
#			is_pac = false
#			speed = SPEED_G
#			$Sprite.texture = TEXTURES["Ghost"]
#		else:
#			is_pac = true
#			speed = SPEED_P
#			$Sprite.texture = TEXTURES["Pac"]
