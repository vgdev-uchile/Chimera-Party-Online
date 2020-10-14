extends Node

var rat_a
var rat_b

var cheese = 0

# Inputs

var move_left = "move_left"
var move_right = "move_right"
var move_up = "move_up"
var move_down = "move_down"
var action_a = "action_a"
var action_b = "action_b"

var _player

func init(player: Player, rat_a, rat_b):
	_player = player
	set_network_master(player.nid)
	var ks = str(player.keyset)
	move_left = "move_left_" + ks
	move_right = "move_right_" + ks
	move_up = "move_up_" + ks
	move_down = "move_down_" + ks
	action_a = "action_a_" + ks
	action_b = "action_b_" + ks
	name = str("%d - %d" % [player.nid, player.local])
	self.rat_a = rat_a
	self.rat_b = rat_b
#	self.rat_a.rset("stopped", false)

func _physics_process(delta: float) -> void:
	if is_network_master():
		if Input.is_action_just_pressed(action_a) or Input.is_action_just_pressed(action_b):
			rat_a.rset("stopped", !rat_a.stopped)
			rat_b.rset("stopped", !rat_b.stopped)
