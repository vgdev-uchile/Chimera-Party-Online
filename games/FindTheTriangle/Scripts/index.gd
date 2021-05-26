extends Node2D

var players
var players_size
remotesync var winners = []
var end_scores = []
var player_nodes = []
var time = 0
export var gametime = 60

var player_scene = preload("res://games/FindTheTriangle/Scenes/player_node.tscn")
var scores = {0: [0,0,0,0],1: [100,0,0,0],2: [100,50,0,0], 3: [100,50,25,0], 4:[100,50,25,10]}
remotesync var generation_rot = [0,0]

onready var VIEWPORT1 = $"MainCanvasLayer/MainContainer/TopContainer/CCPlayer1/Player1/Vp Player1"
onready var CH1 = $"MainCanvasLayer/MainContainer/TopContainer/CCPlayer1/crosshair"
onready var WIN1 = $"MainCanvasLayer/MainContainer/TopContainer/CCPlayer1/win"
onready var NAME1 = $"MainCanvasLayer/MainContainer/TopContainer/CCPlayer1/Username"

onready var VIEWPORT2 = $"MainCanvasLayer/MainContainer/TopContainer/CCPlayer2/Player2/Vp Player2"
onready var CH2 = $"MainCanvasLayer/MainContainer/TopContainer/CCPlayer2/crosshair"
onready var WIN2 = $"MainCanvasLayer/MainContainer/TopContainer/CCPlayer2/win"
onready var NAME2 = $"MainCanvasLayer/MainContainer/TopContainer/CCPlayer2/Username"

onready var BOTTOMCONTAINER = $"MainCanvasLayer/MainContainer/BottomContainer"

onready var VIEWPORT3 = $"MainCanvasLayer/MainContainer/BottomContainer/CCPlayer3/Player3/Vp Player3"
onready var CH3 = $MainCanvasLayer/MainContainer/BottomContainer/CCPlayer3/crosshair
onready var WIN3 = $MainCanvasLayer/MainContainer/BottomContainer/CCPlayer3/win
onready var NAME3 = $"MainCanvasLayer/MainContainer/BottomContainer/CCPlayer3/Username"

onready var VIEWPORT4 = $"MainCanvasLayer/MainContainer/BottomContainer/CCPlayer4/Player4/Vp Player4"
onready var CH4 = $MainCanvasLayer/MainContainer/BottomContainer/CCPlayer4/crosshair
onready var WIN4 = $MainCanvasLayer/MainContainer/BottomContainer/CCPlayer4/win
onready var NAME4 = $"MainCanvasLayer/MainContainer/BottomContainer/CCPlayer4/Username"

onready var WORLD = $"MainCanvasLayer/MainContainer/TopContainer/CCPlayer1/Player1/Vp Player1/World"
onready var WORLD_CENTER_ROTATE = funcref(WORLD.get_node("Center"),'call_rotate')
onready var VIEWPORTS = [VIEWPORT1,VIEWPORT2,VIEWPORT3,VIEWPORT4]
onready var CHS = [CH1,CH2,CH3,CH4]
onready var WINS = [WIN1,WIN2,WIN3,WIN4]
onready var NAMES = [NAME1,NAME2,NAME3,NAME4]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	players = Party.get_players().duplicate()
	players_size = players.size()
	if players_size > 2:
		BOTTOMCONTAINER.visible = true
	for i in range(players_size):
		player_nodes.push_back(player_scene.instance())
		VIEWPORTS[i].get_parent().get_parent().visible = true
#		CHS[i].visible = true
		VIEWPORTS[i].world = VIEWPORT1.world
		player_nodes[i].init(players[i],CHS[i],WINS[i],NAMES[i])
		player_nodes[i].connect("win",self,"on_player_win")
		VIEWPORTS[i].add_child(player_nodes[i])
		end_scores.push_back({"player": players[i], "points": 0})
	
	#Generacion posicionamiento del objetivo
	if is_network_master():
		randomize()
		var generation_pos = [rand_range(-PI,PI), rand_range(-PI/2,PI/2)]
#		print(generation_pos)
		rset("generation_rot",generation_pos)
	#Posicionamiento
		WORLD_CENTER_ROTATE.call_func(generation_rot[0],generation_rot[1])
	
	#Timer
	time = gametime
	$TimeOut.connect("timeout",self,"set_final_scores")
	$TimeOut.start(time)
	$Second.connect("timeout",self,"on_second_passed")
	$Second.start()
	get_node("MainCanvasLayer/RichTextLabel").parse_bbcode("[center]{secs}[/center]".format({"secs": time}))

func on_second_passed():
	time -=1
	get_node("MainCanvasLayer/RichTextLabel").parse_bbcode("[center]{secs}[/center]".format({"secs": time}))

func on_player_win(slot):
#	if is_network_master():
	if winners.size() < players_size:
		winners.append(slot)
		rset("winners",winners)
	if winners.size() == players_size:
		rpc("set_final_scores")

remotesync func set_final_scores():
	var scores_to_add = scores[winners.size()]
	for index in range(winners.size()):
		var slot = winners[index]
		var this_score = scores_to_add[index]
		for player in end_scores:
			if player["player"]["slot"] == slot:
				player["points"] = this_score
				break
	print("end scores: ",end_scores)
	if is_network_master():
		_end_this_game()

func _end_this_game():
	Party.end_game(end_scores)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
