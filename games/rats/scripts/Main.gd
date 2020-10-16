extends Node2D

var Rat = preload("res://games/rats/scenes/Rat.tscn")
var Rats = preload("res://games/rats/scenes/Rats.tscn")

var Levels = [
	preload("res://games/rats/scenes/Level1.tscn"),
	preload("res://games/rats/scenes/Level2.tscn"),
	preload("res://games/rats/scenes/Level3.tscn"),
	preload("res://games/rats/scenes/Level4.tscn"),
]

var level
var current = 0

var players

# used to sync the level loading
var confirmations = 0

func on_show():
	print("show owo")
	get_tree().paused = false
	$Timer.start()
	for rat in $Rats.get_children():
		rat.set_physics_process(true)

#func _enter_tree() -> void:
#	LobbyManager.host_game("elixs")

func _ready():
#	$Rat.stopped = false
	
	print("ready owo")
	get_tree().paused = true
	level = Levels[0].instance()
	level.connect("check_next", self, "check_next")
	$Level.add_child(level)
	$Timer.connect("timeout", self, "on_timeout")
	$CanvasLayer/Timer/Control/TextureProgress.max_value = $Timer.wait_time
	update_timer_display($Timer.wait_time)
	
	players = Party.get_players()
	
	spawn_rats()

# Due to problems now the rats are being deleted and created again
# If you find a way to teleport them on the pause bewteen transitions
# then go ahead
	
func spawn_rats():
	for i in players.size():
		var rats = Rats.instance()
		rats.connect("dead", self, "check_next")
		$Controllers.add_child(rats)
		
		var rat_a = init_rat(i, 0, rats)
		var rat_b = init_rat(i, 1, rats)
		rats.init(players[i], rat_a, rat_b)
		
	shuffle_rats()
	

func delete_rats():
	for rat in $Rats.get_children():
		$Rats.remove_child(rat)
		rat.queue_free()
	for rats in $Controllers.get_children():
		$Controllers.remove_child(rats)
		rats.queue_free()

func init_rat(player_index, index, rats):
	var rat = Rat.instance()
	rat.init(players[player_index], index, rats)
	$Rats.add_child(rat)
	rat.set_physics_process(false)
	return rat

func shuffle_rats():
	var indices = range($Controllers.get_child_count())
	indices.shuffle()
	for i in $Controllers.get_child_count():
		$Controllers.get_child(i).teleport(level.get_node("Positions").get_child(players.size() - 2).get_child(indices[i]))

func on_timeout():
	update_timer_display(0)
	if is_network_master():
		rpc("next")

func check_next():
	var cheese_counter = level.cheese_counter
	for rat in $Rats.get_children():
		if rat.cheese_collected:
			cheese_counter -= 1
		if cheese_counter == 0:
			break
		if not rat.dead and not rat.cheese_collected:
			return
	rpc("next")

sync func next():
	if current + 1 == Levels.size():
		if is_network_master():
			var end_scores = []
			for rats in $Controllers.get_children():
				end_scores.push_back({"player": rats._player, "points": rats.cheese})
			Party.end_game(end_scores)
		return
	get_tree().paused = true
	$Timer.stop()
	$AnimationPlayer.play("fade_in")
	yield($AnimationPlayer, "animation_finished")
	$Level.remove_child(level)
	level.queue_free()
	delete_rats()
	current += 1
	level = Levels[current].instance()
	level.connect("check_next", self, "check_next")
	$Level.add_child(level)
	spawn_rats()
	update_timer_display($Timer.wait_time)
	rpc_id(1, "confirm")

sync func continue_next():
	$AnimationPlayer.play("fade_out")
	yield($AnimationPlayer, "animation_finished")
	get_tree().paused = false
	$Timer.start()
	for rat in $Rats.get_children():
		rat.set_physics_process(true)
		


func _process(delta: float) -> void:
	if not $Timer.is_stopped():
		update_timer_display($Timer.time_left)

func update_timer_display(value):
	$CanvasLayer/Timer/Label.text = str(ceil(value))
	$CanvasLayer/Timer/Control/TextureProgress.value = value

#func _physics_process(delta: float) -> void:
#	if Input.is_action_just_pressed("action_a"):
#		for rat in $Rats.get_children():
#			rat.disable_collision(true)
#		call_deferred("shuffle_rats")
#		for rat in $Rats.get_children():
#			rat.disable_collision(false)
##		next()
#		$AnimationPlayer.play("fade_in")
#	if Input.is_action_just_pressed("action_b"):
#		$AnimationPlayer.play("fade_out")

master func confirm(value=1):
	confirmations += value
	if confirmations == get_tree().get_network_connected_peers().size() + 1:
		confirmations = 0
		rpc("continue_next")
