extends CanvasLayer

var PlayerScore = preload("res://scenes/PlayerScore.tscn")

onready var Players = $Panel/Screen/Center/Players

var final_round = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.connect("timeout", self, "on_timeout")
	$Timer2.connect("timeout", Party, "_game_over")
	
	var players =  Party._players.duplicate()

	players.sort_custom(self, "score_sort")

	for player in players:
		var player_score = PlayerScore.instance()
		player_score.dino_color = player.color
		player_score.score = player.points
		Players.add_child(player_score)
	
	if Party._current_round == Party._rounds:
		$Panel/Screen/Round.text = "Ronda Final"
		final_round = true
	else:
		$Panel/Screen/Round.text = "Ronda " + str(Party._current_round)
		Party._current_round += 1
	if is_network_master():
		$Timer.start()
	
func score_sort(a, b):
	return a.points > b.points

func on_timeout():
	if final_round:
		var winners = []
		var max_score = 0
		for player in Party._players:
			if player.points > max_score:
				max_score = player.points
				winners = [player]
			elif player.points == max_score:
				winners.push_back(player)
		var winner = {"name": winners[0].name, "color": winners[0].color} if winners.size() == 1 else null
		rpc("set_winner", winner)
	else:
		Party.rpc("_next")

sync func set_winner(winner):
	if winner:
		$Panel/Screen/Round.text = "Gana %s" % winner.name
		$Panel/Screen/Round.modulate = Party._colors[winner.color]
	else:
		$Panel/Screen/Round.text = "Empate · o ·)>"
		$Panel/Screen/Round.modulate = Color("#ff7315")
	$Timer2.start()
