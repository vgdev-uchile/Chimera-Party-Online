extends Spatial


var pos_container
var players

var final_scores = []

var dog_scene = preload("res://games/Rotodog/Scenes/TheDog.tscn")

onready var player_container = $Plane/Players
onready var playerNode = $CanvasLayer/PlayerAB


class ScoreSorter:
	static func sort_scores(a, b):
		return a[1] > b[1]


func _ready():
	players = Party.get_players().duplicate()
	var n_players = players.size()
	
	pos_container = get_node("Plane/Positions/{n}Dogs".format({"n": n_players}))
	
	for i in range(n_players):
		var curr_pos = pos_container.get_child(i).translation
		var new_dog = dog_scene.instance()
		new_dog.playerNode = playerNode
		player_container.add_child(new_dog)
		new_dog.translation = curr_pos
		new_dog.init(players[i])
		
	var pos = $Light.translation
	var cam = get_tree().get_root().get_camera()
	var screenpos = cam.unproject_position(pos)
	
	playerNode.set_position(screenpos)
	$CanvasLayer/Conductor/NoteContAB.set_position(screenpos)


remotesync func end_game():
	
	Party.end_game(final_scores)


func cam_to_origin():
	$Plane/AnimationPlayer.stop()
	#$ddcamera/RigidBody.mode = RigidBody.MODE_KINEMATIC
	$ddcamera/RigidBody.linear_velocity = Vector3.ZERO
	$ddcamera/RigidBody.gravity_scale = 3
	$ddcamera/RigidBody/Timer.start(2)


func _on_BGM_finished():
	var rhythm_scores = []
	for child in player_container.get_children():
		rhythm_scores.append([child.player, child.score])
	rhythm_scores.sort_custom(ScoreSorter, "sort_scores")
	var next_max_score = rhythm_scores[0][1]
	var next_points = 100
	for i in range(rhythm_scores.size()):
		if rhythm_scores[i][1] < next_max_score:
			next_points -= 25
			next_max_score = rhythm_scores[i][1]
		final_scores.append({"player": rhythm_scores[i][0], "points": rhythm_scores[i][1]})
	for dog in player_container.get_children():
		if dog.player == rhythm_scores[0][0]:
			dog.change_dance(4)
	$GameEndTimer.start(10)


func _on_GameEndTimer_timeout():
	if is_network_master():
		rpc("end_game")


func _on_cameraTimer_timeout():
	$ddcamera/RigidBody.gravity_scale = 0.1
