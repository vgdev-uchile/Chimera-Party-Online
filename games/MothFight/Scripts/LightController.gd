extends Node

var rng = RandomNumberGenerator.new()
var scores = {"Verde": 0, "Rojo": 0, "Amarillo": 0, "Azul": 0}
var color_names = ["Verde", "Rojo", "Amarillo", "Azul", "Blanco"]
var available_colors = [Color("00ff00"), Color("ff0000"), Color("ffff00"), Color("0000ff")]
var possible_colors = [4]

remotesync var color_order = []

export var game_length = 30
var time = 0

var players
var Players
var score_counters = [null, null, null, null]
var moth_scene = preload("res://games/MothFight/Scenes/Moth.tscn")
var Counter = preload("res://games/MothFight/Scenes/ScorePanel.tscn")

class ScoreSorter:
	static func sort_scores(a, b):
		return a[1] > b[1]

func _ready():
	if is_network_master():
		rng.randomize()
	time = game_length
	get_node("../CanvasLayer/TimerLabel").parse_bbcode("[center]{mins}:{secs}[/center]".format({"mins": time/60, "secs": "%02d" % (time % 60)}))
	Players = get_node("../Players")
	players = Party.get_players().duplicate()
	for i in range(players.size()):
		var player_inst = moth_scene.instance()
		Players.add_child(player_inst)
		player_inst.init(players[i])
		possible_colors.append(players[i].color)
		var counter = Counter.instance()
		counter.set_color(color_names[player_inst.player.color])
		counter.get_node("Panel/Bg").modulate = available_colors[player_inst.player.color]
		var score_container = get_node("../CanvasLayer/HBoxContainer")
		score_container.add_child(counter)
		score_counters[players[i].color] = counter
		player_inst.score_counter = counter
		counter.get_node("Panel/Control/NameLabel").parse_bbcode(
			"[center][color=#{color}]{player_name}[/color][/center]".format({
				"color": available_colors[player_inst.player.color].to_html(false),
				"player_name": player_inst.player.name
			}))
	var player_num = Players.get_child_count()
	if is_network_master():
		for i in possible_colors:
			for _j in range(5):
				color_order.append(i)
		for _i in range(45 - 5 * possible_colors.size()):
			color_order.append(4)
		color_order.shuffle()
		rset("color_order", color_order)
	for i in range(player_num):
		Players.get_child(i).global_position = \
			get_node("../Positions").get_child(i).global_position
	get_node("../CanvasLayer/CountDownLabel/AnimationPlayer").play("countdown")
	yield(get_node("../CanvasLayer/CountDownLabel/AnimationPlayer"), "animation_finished")
	start_game()

remotesync func activate_lightbulb(n):
	var col = color_order.pop_back()
	var light = $Lights.get_child(n)
	light.color = col
	light.switch(true)

func lights_on():
	var c = 0
	for lamp in $Lights.get_children():
		if lamp.on:
			c += 1
	return c
	
remotesync func add_score(moth_color, light_col):
	if light_col == 4:
		scores[color_names[moth_color]] += 1
		score_counters[moth_color].add_score(1)
	elif moth_color == light_col:
		scores[color_names[moth_color]] += 2
		score_counters[moth_color].add_score(2)
	else:
		scores[color_names[moth_color]] += 1
		scores[color_names[light_col]] -= 1
		score_counters[moth_color].add_score(1)
		score_counters[light_col].add_score(-1)

func final_score():
	var lamps = []
	var final_scores = []
	for i in range(players.size()):
		final_scores.append({"player": players[i], "points": 0})
	
	var score_tiers = [100, 50, 25, 0]
		
	for i in range(4):
		if score_counters[i] != null:
			lamps.append([i, score_counters[i].score])
	
	lamps.sort_custom(ScoreSorter, "sort_scores")
	
	var lamp_scores = []
	for l in lamps:
		lamp_scores.append(l[1])
			
	var total_players = lamps.size()
	if lamp_scores.max() > 0:
		var i = 0
		while i < total_players:
			var tier = i
			var max_score = lamp_scores.max()
			var players_in_tier = lamp_scores.count(max_score)
			while max_score in lamp_scores:
				lamp_scores.erase(max_score)
			var tier_score = (100 - 25 * tier - 25 * (players_in_tier - 1)) if lamps[i][1] > 0 else 0
			
			for _j in range(players_in_tier):
				for sc in final_scores:
					if sc["player"].color == lamps[i][0]:
						sc["points"] = tier_score
						break
				for player in players:
					if player.color == lamps[i][0]:
						var tier_texture
						if tier_score > 0:
							match tier:
								0:
									tier_texture = load("res://games/MothFight/Sprites/crown.png")
								1:
									tier_texture = load("res://games/MothFight/Sprites/silver_bulb.png")
								2:
									tier_texture = load("res://games/MothFight/Sprites/bronze_bulb.png")
								3:
									tier_texture = load("res://games/MothFight/Sprites/broken_bulb.png")
						else:
							tier_texture = load("res://games/MothFight/Sprites/broken_bulb.png")
						
						score_counters[player.color].get_node("Panel/TierSprite").texture = tier_texture
						score_counters[player.color].get_node("Panel/TierSprite/RichTextLabel").parse_bbcode(
							"[center][color=#{color}]+{score}[/color][/center]".format(
								{"score": tier_score,
								"color": available_colors[player.color].to_html(false)}))
				i += 1
	return final_scores

remotesync func start_game():
	$GameOverTimer.start(1)
	$Timer.start(2)
	$AudioStreamPlayer.play()

remotesync func start_timer():
	if $Timer.is_stopped():
		$Timer.start(4)

func _on_Timer_timeout():
	if is_network_master():
		if lights_on() <3:
			var is_off = false
			var next
			while not is_off:
				next = rng.randi_range(0, $Lights.get_child_count()-1)
				if not $Lights.get_child(next).on:
					is_off = true
			rpc("activate_lightbulb", next)
		start_timer()

func _on_GameOverTimer_timeout():
	time -= 1
	get_node("../CanvasLayer/TimerLabel").parse_bbcode("[center]{mins}:{secs}[/center]".format({"mins": time/60, "secs": "%02d" % (time % 60)}))
	if time == 0:
		$GameOverTimer.stop()
		get_node("../CanvasLayer/TextureRect").visible = true
		$Timer.stop()
		for child in $Lights.get_children():
			child.switch(false)
		var s = final_score()
		for panel in get_node("../CanvasLayer/HBoxContainer").get_children():
			panel.get_node("Panel/TierSprite").visible = true
		$EndGameTimer.start(7)
		yield($EndGameTimer, "timeout")
		Party.end_game(s)

