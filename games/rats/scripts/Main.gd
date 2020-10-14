extends Node2D

var Rat = preload("res://games/rats/scenes/Rat.tscn")
var Rats = preload("res://games/rats/scenes/Rats.tscn")

var Levels = [
	preload("res://games/rats/scenes/Level1.tscn"),
	preload("res://games/rats/scenes/Level2.tscn")
]

var level
var current = 0

var players

#onready var a = $Rat
#onready var b = $Rat2

# used to sync the level loading
var confirmations = 0

func on_show():
	print("show owo")
	get_tree().paused = false
	$Timer.start()

func _enter_tree() -> void:
	LobbyManager.host_game("elixs")

func _ready():
	print("ready owo")
	get_tree().paused = true
	level = Levels[0].instance()
	level.connect("next", self, "next")
	$Level.add_child(level)
	$Timer.connect("timeout", self, "on_timeout")
	$CanvasLayer/Timer/Control/TextureProgress.max_value = $Timer.wait_time
	update_timer_display($Timer.wait_time)
	
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
		var rats = Rats.instance()
		add_child(rats)
		
		var rat_a = init_rat(i, 0, rats)
		var rat_b = init_rat(i, 1, rats)
		rats.init(players[i], rat_a, rat_b)
	move_rats()

func init_rat(player_index, index, rats):
	var rat = Rat.instance()
	if index == 0:
		rat.stopped = false
	rat.init(players[player_index], index, rats)
	$Rats.add_child(rat)
	return rat

func move_rats():
	for i in $Rats.get_child_count():
		var player_index = i / 2
		var index = i % 2
		$Rats.get_child(i).teleport(level.get_node("Positions").get_child(players.size() - 2).get_child(player_index).get_child(index).global_position)
	

func on_timeout():
	update_timer_display(0)
	if is_network_master():
		rpc("next")

sync func next():
	if current + 1 >= Levels.size():
		if is_network_master():
			var end_scores = []
			for player in players:
				end_scores.push_back({"player": player, "points": 0})
			Party.end_game(end_scores)
		return
	get_tree().paused = true
	$Timer.stop()
	
	$AnimationPlayer.play("fade_in")
	yield($AnimationPlayer, "animation_finished")
	$Level.remove_child(level)
	level.queue_free()
	current += 1
	level = Levels[current].instance()
	level.connect("next", self, "next")
	$Level.add_child(level)
	move_rats()
	update_timer_display($Timer.wait_time)
	rpc_id(1, "confirm")


sync func continue_next():
	$AnimationPlayer.play("fade_out")
	yield($AnimationPlayer, "animation_finished")
	get_tree().paused = false
	$Timer.start()

func _process(delta: float) -> void:
	if not $Timer.is_stopped():
		update_timer_display($Timer.time_left)

func update_timer_display(value):
	$CanvasLayer/Timer/Label.text = str(ceil(value))
	$CanvasLayer/Timer/Control/TextureProgress.value = value
	
#func _physics_process(delta: float) -> void:
#	if Input.is_action_just_pressed("action_a"):
##		next()
#		$AnimationPlayer.play("fade_in")
#	if Input.is_action_just_pressed("action_b"):
#		$AnimationPlayer.play("fade_out")

master func confirm(value=1):
	confirmations += value
	if confirmations == get_tree().get_network_connected_peers().size() + 1:
		confirmations = 0
		rpc("continue_next")
