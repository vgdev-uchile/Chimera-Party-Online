extends Area2D

func _ready():
	connect("body_entered", self, "on_body_entered")

func on_body_entered(body: Node):
	print("awa de uwu")
	if is_network_master():
		var players = Party.get_players()
		var end_scores = []
		for player in players:
			end_scores.push_back({"player": player, "points": 0})
		Party.end_game(end_scores)
