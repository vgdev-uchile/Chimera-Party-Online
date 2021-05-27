extends Spatial

var player_scene = preload("res://games/Bonk/Scenes/Player.tscn")

var players
var player_scores = [] #{"player": player, "points": score}
onready var camera : Camera = $CameraContainer/Camera

func _ready():
	camera.make_current()
	
	players = Party.get_players().duplicate()
	for i in range(players.size()):
		var p = player_scene.instance()
		p.init(players[i])
		p.global_transform.origin = $PositionContainer.get_children()[i].global_transform.origin
		$PlayerContainer.add_child(p)


func _process(delta):
	_get_bigness()
	_vector_update()
	_camera_update()

func _get_bigness():
	for child in $PlayerContainer.get_children():
		max_big = max(max_big,child.biggyness)

var max_big : float =1.0
onready var start_pos : Vector3 = $CameraContainer/Start.global_transform.origin
onready var end_pos : Vector3 = $CameraContainer/End.global_transform.origin
onready var start_aim : Vector3 = $CameraContainer/AimStart.global_transform.origin
onready var end_aim : Vector3 = $CameraContainer/AimEnd.global_transform.origin
onready var target_pos : Vector3 = $CameraContainer/Start.global_transform.origin
onready var target_aim : Vector3 = $CameraContainer/AimStart.global_transform.origin

func _camera_update():
	camera.global_transform.origin = lerp(camera.global_transform.origin,target_pos,0.5)
	# camera look at

var pos_lambda : float = 0.0
var aim_lambda : float = 0.0

export var reasonable_key_presses : float = 1000.0
func _lambda_update():
	pos_lambda = min(pow((2*max_big-1),1.1)/pow(reasonable_key_presses,1.1),1)
	aim_lambda = min(pow((2*max_big-1),1.1)/pow(reasonable_key_presses,1.1),1)

func _vector_update():
	_lambda_update()
	target_pos =  (1-pos_lambda)*start_pos  + pos_lambda*end_pos
	target_aim =  (1-aim_lambda)*start_aim  + aim_lambda*end_aim

var _cycle_var : int =0
enum _cycles {entrance,countdown,start,game,stop,end,exit}

var results : Array
func _cycle():
	match _cycle_var:
		_cycles.entrance:
			pass
		_cycles.countdown:
			pass
		_cycles.start:
			pass
		_cycles.game:
			pass
		_cycles.stop:
			results = _get_results()
		_cycles.end:
			pass
		_cycles.exit:
			pass
	Party.end_game(player_scores)

# returns a list of results and updates player_scores
func _get_results() -> Array:
	var player_list = $PlayerContainer.get_children()
	
	var biggest_size = 0
	var best_player : Player
	
	var second_best_player : Player
	var second_biggest = 0
	var second_draw = []
	
	var everyone_else  = []
	
	# sacar el primero
	for child in player_list:
		var p   = child.player
		var big = child.biggyness
		if big>biggest_size:
			biggest_size=big
			best_player = p
	
	# check for draws in first place
	var first_draw = []
	for child in player_list:
		var p = child.player
		var big = child.biggyness
		if big==biggest_size:
			first_draw.append(p)
		else:
			everyone_else.append(p)
	if first_draw.size()>1:
		_draw(first_draw,biggest_size)
		return [first_draw,[],everyone_else]
	
	everyone_else.resize(0)
	
	# if not superior draw, then there exists at least some second player
	for child in player_list:
		var p = child.player
		var big = child.biggyness
		if p!=best_player:
			if big>second_biggest:
				second_best_player = p
				second_biggest = big
	
	# get every second player
	for child in player_list:
		var p = child.player
		var big = child.biggyness
		if big==second_best_player:
			second_draw.push_back(p)
	
	# get everyone else:
	for child in player_list:
		var p = child.player
		var big = child.biggyness
		if big < second_biggest:
			everyone_else.push_back(p)
	_bonk(best_player,second_draw,everyone_else,biggest_size,second_biggest)
	
	return [[best_player],second_draw,everyone_else]


func _draw(firsts,greatest):
	var _draw_score : int = _draw_score_function(greatest)
	for p in players:
		if firsts.find(p)!=-1: # drawer
			player_scores.push_back({"player":p,"points":_draw_score})
		else:
			player_scores.push_back({"player":p,"points":simp_scores})
	return


# writes player scores
export var simp_scores : int = 10
func _bonk(best,seconds,elses,max_bigness,weak_bigness):
	var bonk_strength = max_bigness-weak_bigness
	
	# winner gets bonk energy
	var winner_score : int = _winner_score_function(bonk_strength,max_bigness)
	player_scores.push_back({"player":best,"points":winner_score})
	
	# bonk the losers
	var loser_score : int = _loser_score_function(bonk_strength,max_bigness)
	for loser in seconds:
		player_scores.push_back({"player":loser,"points":loser_score})
	
	# everyone else is just meh
	for simp in elses:
		player_scores.push_back({"player":simp,"points":simp_scores})
	return

func _winner_score_function(strength,greatest):
	return int(70*(strength+greatest)/reasonable_key_presses)

func _loser_score_function(strength,greatest):
	return -int(90*(strength+greatest)/reasonable_key_presses)

func _draw_score_function(greatest):
	return min(-20,-int(50*(greatest)/reasonable_key_presses))
