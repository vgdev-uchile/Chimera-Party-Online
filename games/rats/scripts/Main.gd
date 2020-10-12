extends Node2D

var Rat = preload("res://games/rats/scenes/Rat.tscn")
var Rats = preload("res://games/rats/scenes/Rats.tscn")

var players

#onready var a = $Rat
#onready var b = $Rat2

#func _enter_tree() -> void:
#	LobbyManager.host_game("elixs")

func _ready():
	
#	print("ready main")
#	Party.load_test()
#	$Rat.stopped = false
#	$Rat.init(Party.get_players()[0], 0)
#	$Rat2.init(Party.get_players()[0], 1)
#
#	var rats = Rats.instance()
#	rats.init(Party.get_players()[0], a, b)
#	add_child(rats)
	
	
	players = Party.get_players().duplicate()
	players.shuffle()
	for i in range(players.size()):
		var rat_a = init_rat(i, 0)
		var rat_b = init_rat(i, 1)

		var rats = Rats.instance()
		rats.init(players[i], rat_a, rat_b)
		add_child(rats)

func init_rat(player_index, index):
	var rat = Rat.instance()
	if index == 0:
		rat.stopped = false
	rat.init(players[player_index], index)
	rat.global_position = $"Level1/Positions".get_child(players.size() - 2).get_child(player_index).get_child(index).global_position
	$Rats.add_child(rat)
	return rat
