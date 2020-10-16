extends Node

var rat_a
var rat_b

var cheese = 0

signal dead

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
	self.rat_a.stopped = false
	self.rat_b = rat_b
#	self.rat_a.rset("stopped", false)

func _physics_process(delta: float) -> void:
	if is_network_master() and not (rat_a.dead or rat_b.dead):
		if Input.is_action_just_pressed(action_a) or Input.is_action_just_pressed(action_b):
			rat_a.rset("stopped", !rat_a.stopped)
			rat_b.rset("stopped", !rat_b.stopped)

func teleport(position_node):
	rat_a.teleport(position_node.get_child(0).global_position)
	rat_b.teleport(position_node.get_child(1).global_position)
	rat_a.rset("stopped", false)
	rat_b.rset("stopped", true)

func dead(rat):
	if rat == rat_a and not rat_b.dead:
		rat_b.rset("stopped", false)
	if rat == rat_b and not rat_a.dead:
		rat_a.rset("stopped", false)
	if rat_a.dead and rat_b.dead and is_network_master():
		emit_signal("dead")
