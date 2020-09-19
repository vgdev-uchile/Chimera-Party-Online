extends Node2D

var Rat = preload("res://games/rats/scenes/Rat.tscn")

var players

func _ready():
#	Party.load_test()
	players = Party.get_players()
	var players_size = players.size()
	
	for i in range(players_size):
		var rat = Rat.instance()
		rat.init(players[i])
#		dino.connect("died", self, "on_dino_died")
		rat.global_position = $Positions.get_child(players_size - 2).get_child(i).global_position
		$Rats.add_child(rat)
