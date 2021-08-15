extends Node2D

onready var players_scene = preload("res://games/Pac-Party/scenes/player_node.tscn")
onready var collectable   = preload("res://games/Pac-Party/scenes/Collectable.tscn")
onready var maps = [preload("res://games/Pac-Party/scenes/Map1.tscn"),
					preload("res://games/Pac-Party/scenes/Map2.tscn")]
#onready var players_team_scene = preload()
var selected_map = 0
var map

var player_alone
var players_team
var players
var players_size = 4 # 1v3 siempre tiene 4 players
remotesync var winners = []
var end_scores = []
var player_nodes = []
const PAC_WIN_SCORES = [100, 0, 0, 0]
const PAC_LOSE_SCORE = [[0, 75, 75, 75], [50, 50, 50, 50], [75, 25, 25, 25]]


var collectable_count = 0

remote var remote_data
var test_init_positions = [Vector2(0,56), Vector2(40,8), Vector2(-40,8), Vector2(0,-8)]

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
		rpc("set_map", selected_map)
	yield(get_tree().create_timer(0.2), "timeout")
	call_deferred("_ready2")

func _ready2() -> void:
	# Players Init
	for i in range(players_size):
		player_nodes.push_back(players_scene.instance())
		player_nodes[i].init(players[i], test_init_positions[i], i, map, collectable_count)
		self.add_child(player_nodes[i])
		var _err1 = player_nodes[i].connect("pac_dead",self,"on_pac_dead")
		var _err2 = player_nodes[i].connect("pac_win" ,self,"on_pac_win" )
	# Color tweens start
	$ColorMapR.start()
	$ColorMapG.start()
	$ColorMapB.start()


remotesync func set_map(sel_map):
	selected_map = sel_map
	map = maps[selected_map].instance()
	$Map.add_child(map)
	var _twr = $ColorMapR.connect("tween_completed", self, "_on_r_faded")
	var _twg = $ColorMapG.connect("tween_completed", self, "_on_g_faded")
	var _twb = $ColorMapB.connect("tween_completed", self, "_on_b_faded")
	$ColorMapR.interpolate_property(map, "modulate:r", map.modulate.r, 0.5 - map.modulate.r, 4.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$ColorMapG.interpolate_property(map, "modulate:g", map.modulate.g, 0.5 - map.modulate.g, 6.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$ColorMapB.interpolate_property(map, "modulate:b", map.modulate.b, 0.5 - map.modulate.b, 10.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	if map.has_node("dots"):
		var map_offset = map.get_cell_size()/2
		var empty_cells = map.get_node("dots").get_used_cells()
		for empty_cell in empty_cells:
			var dot = collectable.instance()
			dot.init(collectable_count, player_alone.nid)
			collectable_count += 1 
			dot.global_position = map.map_to_world(empty_cell) + map_offset
			$Map.add_child(dot)


func _on_r_faded(_o, _k):
	$ColorMapR.interpolate_property(map, "modulate:r", map.modulate.r, 0.5 - map.modulate.r, 2.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$ColorMapR.start()
func _on_g_faded(_o, _k):
	$ColorMapG.interpolate_property(map, "modulate:g", map.modulate.g, 0.5 - map.modulate.g, 3.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$ColorMapG.start()
func _on_b_faded(_o, _k):
	$ColorMapB.interpolate_property(map, "modulate:b", map.modulate.b, 0.5 - map.modulate.b, 5.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$ColorMapB.start()
func on_pac_dead(pac_node: Node2D, ratio: float):
	var scores
	if ratio > 0.75:
		scores = PAC_LOSE_SCORE[2]
	elif ratio > 0.5:
		scores = PAC_LOSE_SCORE[1]
	else:
		scores = PAC_LOSE_SCORE[0]
	rpc("set_final_scores", scores)

func on_pac_win():
	var scores = PAC_WIN_SCORES
	rpc("set_final_scores", scores)


remotesync func set_final_scores(scores):
	for i in range(players_size):
		var score = { "player" : players[i], "points" : scores[i]}
		end_scores.push_back(score)
	yield(get_tree().create_timer(1), "timeout")
	if is_network_master():
		_end_this_game()

func _end_this_game():
	Party.end_game(end_scores)
