extends Node2D

onready var players_scene = preload("res://games/Pac-Party/scenes/player_node.tscn")
onready var maps = [preload("res://games/Pac-Party/scenes/Map1.tscn"),
					preload("res://games/Pac-Party/scenes/Map2.tscn")]
#onready var players_team_scene = preload()
remotesync var selected_map = 0

var player_alone
var players_team
var players
var players_size = 4 # 1v3 siempre tiene 4 players
remotesync var winners = []
var end_scores = []
var player_nodes = []


remote var remote_data
var test_init_positions = [Vector2(0,0), Vector2(100,100), Vector2(-100,100), Vector2(0,100)]

func _ready() -> void:
	var teams = Party.get_teams().duplicate()
	if teams.size() == 0: #error al obtener los equipos
		Party.load_test("1v3")
		teams = Party.get_teams().duplicate()
	player_alone = teams[0][0]
	players_team = teams[1]
	players = [player_alone, players_team[0], players_team[1], players_team[2]]
	
	# Map selection
	if is_network_master():
		randomize()
		selected_map = randi() % maps.size()
		rset("selected_map", selected_map)
		rpc("set_map")
	
	# Players Init
	for i in range(players_size):
		player_nodes.push_back(players_scene.instance())
		player_nodes[i].init(players[i], test_init_positions[i], i==0)
		self.add_child(player_nodes[i])
#		player_nodes[i].connect("win",self,"on_player_win")
#		end_scores.push_back({"player": players[i], "points": 0})

remotesync func set_map():
	var map = maps[selected_map].instance()
	$Map.add_child(map)
