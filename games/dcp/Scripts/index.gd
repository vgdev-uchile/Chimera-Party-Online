extends Spatial


const dolphin_scene = preload("res://games/dcp/Scenes/DelfinTerrestre.tscn")

var score = 0
var players
export var seconds_left = 120
export var end_time = 10
remotesync var owo = false
remotesync var buenas_tardes = false

onready var starting_points = $StartingPoints
onready var duck_makers = $DuckMakers
onready var score_label = $CanvasLayer/RichTextLabel
onready var ball = $Sphere
onready var player_container = $PlayerContainer
onready var time_label = $CanvasLayer/TimeLabel


func _ready():
	players = Party.get_players().duplicate()
	var n_players = players.size()
	
	for i in range(n_players):
		var curr_pos = starting_points.get_child(players[i].slot)
		var new_dolphin = dolphin_scene.instance()
		player_container.add_child(new_dolphin)
		new_dolphin.translation = curr_pos.translation
		new_dolphin.rotation.y = curr_pos.rotation.y
		new_dolphin.puppet_rot = curr_pos.rotation.y
		new_dolphin.init(players[i])
		
	for i in n_players:
		var dcp = player_container.get_child(i)
		if dcp.is_network_master():
			print("Dolphin ", i, " linked with dolphin ", (i + 1) % n_players)
			var linked_dcp = player_container.get_child((i + 1) % n_players)
			linked_dcp.get_node("CamPivot/Camera").current = true
			break
	
	if is_network_master():
		rpc("spawn_ball", randi() % duck_makers.get_child_count())
		
	$CanvasLayer/AnimationPlayer.play("start")
	yield($CanvasLayer/AnimationPlayer, "animation_finished")
	
	$CanvasLayer/TimerSeconds.start()
	for dcp in player_container.get_children():
		dcp.can_move = true

func buenas_tardes_mode():
	$DirectionalLight.light_color = Color.webmaroon
	$AudioStreamPlayer.play()
	for dcp in player_container.get_children():
		if dcp.is_network_master():
			dcp.swap_camera()
			break

func _input(event):
	return
	if event.is_action_pressed("ui_cancel"):
		$DCP/TransformationVoice/BuenasTardes.play()
		yield($DCP/TransformationVoice/BuenasTardes, "finished")
		$DCP/delfin_con_patas/Armature/Skeleton/Cube.material_override = $DCP.material_buenas_tardes
		$delfin_con_patas2/Camera.current = false
		$delfin_con_patas2/Camera4.current = true
		$DCP.voices = $DCP/VoicesGA

remotesync func spawn_ball(n):
	var new_ball_start_pos = duck_makers.get_child(n).global_transform.origin
	ball.translation = new_ball_start_pos
	ball.sleeping = false
	ball.can_move = true
	ball.mode = RigidBody.MODE_RIGID
	print(ball.translation)

remotesync func add_score(value):
	score += value
	update_score()

remotesync func deactivate_ball():
	ball.mode = RigidBody.MODE_KINEMATIC
	ball.can_move = false

func update_score():
	score_label.parse_bbcode("[center]Puntos: %s[/center]" % score)

remotesync func end_wholesome_game():
	owo = true
	$EndTimer.start(end_time)
	$CanvasLayer/StartLabel.parse_bbcode("[center]¡Todos ganan![/center]")
	$CanvasLayer/StartLabel.modulate = Color.white

func _on_BallCatcher_body_entered(body):
	if is_network_master():
		rpc("add_score", 1)
		rpc("deactivate_ball")
		var next_start = randi() % duck_makers.get_child_count()
		rpc("spawn_ball", next_start)
	

func _on_TimerSeconds_timeout():
	seconds_left -= 1
	time_label.parse_bbcode("[center]%d:%02d[/center]" % [(seconds_left / 60), (seconds_left % 60)])
	if seconds_left <= 0:
		$CanvasLayer/TimerSeconds.stop()
		time_label.parse_bbcode("[center]0:00[/center]")
		if is_network_master():
			rpc("end_wholesome_game")


func _on_EndTimer_timeout():
	if not buenas_tardes:
		var final_scores = []
		for player in players:
			final_scores.append({"player": player, "points": score * 20})
		Party.end_game(final_scores)
