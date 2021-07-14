extends Spatial

var player_scene = preload("res://games/Bonk/Scenes/Player.tscn")

var players
var player_scores = [] #{"player": player, "points": score}
onready var camera : Camera = $CameraContainer/Camera

signal unfreeze
signal freeze

func _ready():
	camera.make_current()
	
	players = Party.get_players().duplicate()
	for i in range(players.size()):
		var p = player_scene.instance()
		p.init(players[i],i,self)
		p.global_transform = $PositionContainer.get_children()[i].global_transform
		$PlayerContainer.add_child(p)
		catch_connection(connect("freeze",p,"_on_freeze"))
		catch_connection(connect("unfreeze",p,"_on_unfreeze"))
	
	if is_network_master():
		_setup_cycle_timer()
		_cycle()

func _process(delta):
	_get_bigness()
	_lambda_update()
	_vector_update()
	if _cycle_var!=_cycles.entrance:
		_camera_update()
	#print(cycle_timer.time_left)

var bigness_array : PoolRealArray = [1.0,1.0,1.0,1.0,0.0]

func _get_bigness(): # ?? parece que desincronnizó
	for child in $PlayerContainer.get_children():
		max_big = max(max_big,child.biggyness)
	#for i in range(players.size()):
	#	max_big = max(max_big,child.biggyness)

func _on_notify_bigness(whom:int,howmuch:float):
	bigness_array[whom] = howmuch

################## Manejo de la cámara #########################################

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

export var play_time : float = 20.0
export var result_time : float = 5.0
export var reasonable_key_presses : float = 1000.0 # TODO: ESTIMATE THIS

func _lambda_update():
	pos_lambda = min(pow((2*max_big-1),1.1)/pow(reasonable_key_presses,1.1),1)
	aim_lambda = min(pow((2*max_big-1),1.1)/pow(reasonable_key_presses,1.1),1)

func _vector_update():
	target_pos =  (1-pos_lambda)*start_pos  + pos_lambda*end_pos
	target_aim =  (1-aim_lambda)*start_aim  + aim_lambda*end_aim

func _override_camera_pos(pos):
	target_pos = pos

############## Manejo de Ciclos ##################

var _cycle_var : int = _cycles.entrance
enum _cycles {entrance,countdown,start,game,stop,end,exit}

var ended : bool = false
var results : Array
func _cycle():
	# obs, esto solo se ejecuta desde master!
	if ended:
		return
	match _cycle_var:
		_cycles.entrance:
			printg(["entrance"])
			cycle_timer.wait_time = 3.0
			rpc("_cycle_entrance")
			cycle_timer.start()
		_cycles.countdown:
			printg(["countdown"])
			rpc("_cycle_countdown") # cycle timer is called within _cycle countdown
		_cycles.start:
			printg(["start"])
			cycle_timer.start()
			rpc("_cycle_start")
		_cycles.game:
			printg(["game"])
			rpc("_cycle_game")
			cycle_timer.wait_time = play_time
			cycle_timer.stop()
			cycle_timer.start()
		_cycles.stop:
			printg(["stop"])
			rpc("_cycle_stop")
			cycle_timer.wait_time = result_time
			results = _get_results()
			cycle_timer.start()
		_cycles.end:
			rpc("_cycle_end")
			printg(["end"])
			cycle_timer.start()
		_cycles.exit:
			rpc("_cycle_exit")
			printg(["exit"])
			ended = true
			Party.end_game(player_scores)
	_cycle_var+=1

onready var cycle_timer : Timer = Timer.new()

func _setup_cycle_timer():
	self.add_child(cycle_timer)
	cycle_timer.one_shot = true
	catch_connection(cycle_timer.connect("timeout",self,"_cycle"))

remotesync func _cycle_entrance():
	#target_pos = end_pos
	pass

remotesync func _cycle_countdown():
	_countdown() # esta función hará un llamado que cambiará el ciclo !

remotesync func _cycle_start():
	_start()

remotesync func _cycle_game():
	_game()

remotesync func _cycle_stop():
	_stop()
	pass

remotesync func _cycle_end():
	_end()
	pass

remotesync func _cycle_exit():
	_exit()
	pass


################# UI Overlay behaviour ################

onready var countdown_timer : Timer = Timer.new()

export(int,2,10) var countdown_time : int = 5
export(float,0.1,10) var countdown_time_step : float = 0.9
onready var _remaining_countdown : int = countdown_time
onready var countdown_label :RichTextLabel = $"UI Overlay/Contenedor/Countdown"
var _countdown_timer_setup : bool = false

func _countdown():
	if !_countdown_timer_setup:
		_setup_countdown_timer()
	
	if _remaining_countdown>0:
		countdown_label.bbcode_text =(
			"[center][rainbow]%d[/rainbow][/center]"%_remaining_countdown
			)
	else:
		countdown_label.bbcode_text = "[center][rainbow]START[/rainbow][/center]"
	countdown_label.show()
	if _remaining_countdown>=0:
		countdown_timer.start()
	_remaining_countdown -= 1
	if is_network_master() and _remaining_countdown<0:
		_cycle()

func _setup_countdown_timer():
	self.add_child(countdown_timer)
	countdown_timer.wait_time = countdown_time_step
	countdown_timer.one_shot = true
	countdown_timer.connect("timeout",self,"_countdown")
	_countdown_timer_setup=true

func _start():
	emit_signal("unfreeze")
	countdown_label.hide()

func _game():
	pass

func _stop():
	emit_signal("freeze")
	pass

func _end():
	pass

func _exit():
	pass

###################################################

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
		if big==second_biggest:
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

## utilities

func printg(args):
	print("Bonk: ")
	for arg in args:
		print(arg)

func catch_connection(variant,origin : String = ""):
	if variant!=OK:
		if origin=="":
			printg(["error!"])
		else:
			printg(["error on ",origin])
