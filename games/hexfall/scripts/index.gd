extends Node2D

var Dino = preload("res://games/hexfall/scenes/Dino.tscn")

var players: Array
var dead_players = []
var tied_players = []

var scores = {2: [100, 0], 3: [100, 50, 0], 4: [100, 50, 25, 0]}

var tie_timers = []

func _ready():
#	Party.load_test()
	players = Party.get_players().duplicate()
	var players_size = players.size()
	
	for i in range(players_size):
		var dino = Dino.instance()
		dino.init(players[i])
		dino.global_position = $Positions.get_child(players_size - 2).get_child(i).global_position
		dino.connect("died", self, "on_dino_died")
		$Dinos.add_child(dino)
	
	$ScoreTimer.connect("timeout", self, "on_score_timeout")

sync func finish():
	$UI/Finish.show()
	$Tiles.stop_all()
	for dino in $Dinos.get_children():
		dino.stop()

func on_dino_died(player: Player):
	if is_network_master():
		players.erase(player)
		tied_players.push_back(player)
		if players.size() == 1:
			rpc("finish")
			$ScoreTimer.start()
			for timer in tie_timers:
				print("stop timer")
				timer.stop()
		elif players.size() > 1:
			var timer = Timer.new()
			add_child(timer)
			timer.one_shot = true
			timer.wait_time = 0.5
			timer.connect("timeout", self, "on_tie_timeout")
			timer.start()
			tie_timers.push_back(timer)

func on_tie_timeout():
	print("on_tie_timeout")
	var timer = tie_timers.pop_front()
	remove_child(timer)
	var player = tied_players.pop_front()
	dead_players.push_back(player)

sync func set_finish_text(text):
	$UI/Finish.text = text

sync func show_scores(end_scores):
	for i in range(end_scores.size()):
		var player_ui = $UI/CenterContainer/Scores.get_child(i / 2).get_child(i % 2)
		var player = end_scores[i].player
		var points = end_scores[i].points
		player_ui.get_node("Name").text = player.name
		player_ui.get_node("Name").modulate = Party.get_colors()[player.color]
		player_ui.get_node("Score").text = str(points)
		player_ui.show()


func on_score_timeout():
	var players_size = players.size()
	
	if players_size == 1:
		var winner: Player = players[0]
		rpc("set_finish_text", "Gana %s" % winner.name)
	else:
		rpc("set_finish_text", "Empate!")
	
	var tps = 0 if players_size == 1 else tied_players.size()
	
	for player in tied_players:
		dead_players.push_back(player)
	
	if players_size == 1:
		dead_players.push_back(players[0])
	
	dead_players.invert()
	
	var ps = dead_players.size()
	
	var end_scores = []
	var end_scores_remote = []
	
	for i in range(ps):
		var pi = i
		if i < tps:
			pi = tps - 1
		var p: Player = dead_players[i]
		end_scores.push_back(
			{"player": p, "points": scores[ps][pi]})
		end_scores_remote.push_back(
			{"player": {"name": p.name, "color": p.color},"points": scores[ps][pi]})
	
	rpc("show_scores", end_scores_remote)
	
	$EndTimer.start()
	
	yield($EndTimer, "timeout")
	
	Party.end_game(end_scores)
