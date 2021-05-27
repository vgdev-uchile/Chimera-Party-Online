extends Spatial

var player_scene = preload("res://games/Bonk/Scenes/Player.tscn")

var players
onready var camera : Camera = $CameraContainer/Camera

func _ready():
	camera.make_current()
	
	players = Party.get_players().duplicate()
	for i in range(players.size()):
		var p = player_scene.instance()
		p.init(players[i])
		p.global_transform.origin = $PositionContainer.get_children()[i].global_transform.origin
		$PlayerContainer.add_child(p)

var max_big : float =1.0

func _process(delta):
	_get_bigness()
	_vector_update()
	_camera_update()

func _get_bigness():
	for child in $PlayerContainer.get_children():
		max_big = max(max_big,child.biggyness)


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
	
