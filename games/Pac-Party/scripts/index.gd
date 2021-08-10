extends Node2D

onready var players_scene = preload("res://games/Pac-Party/scenes/player_node.tscn")
#onready var players_team_scene = preload()

var player_alone
var players_team
var players
var players_size = 4 # 1v3 siempre tiene 4 players
remotesync var winners = []
var end_scores = []
var player_nodes = []

var test_init_positions = [Vector2(0,0), Vector2(100,100), Vector2(-100,100), Vector2(0,100)]

func _ready() -> void:
	var teams = Party.get_teams().duplicate()
	player_alone = teams[0][0]
	players_team = teams[1]
	players = [player_alone, players_team[0], players_team[1], players_team[2]]
	
	# Players Init
	for i in range(players_size):
		player_nodes.push_back(players_scene.instance())
		player_nodes[i].init(players[i], test_init_positions[i])
		self.add_child(player_nodes[i])
#		player_nodes[i].connect("win",self,"on_player_win")
#		end_scores.push_back({"player": players[i], "points": 0})


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
