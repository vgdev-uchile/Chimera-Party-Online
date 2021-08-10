extends KinematicBody


export (float) var speed = 100
export (float) var rot_speed = 1

var dir: Vector3 = Vector3.FORWARD
var moving = false
onready var label_holder = $LabelHolder

# Called when the node enters the scene tree for the first time.
func _ready():
	dir = Vector3.FORWARD.rotated(Vector3.UP, rotation.y)
	$delfin_con_patas/AnimationPlayer.play("Idle")


func init(nid):
	pass


func _physics_process(delta):
	var h_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var v_input = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	if h_input != 0:
		rotation_degrees.y = rotation_degrees.y - rad2deg(rot_speed * h_input * delta)
		#dir = dir.rotated(Vector3.UP, rot_speed * h_input * delta)
		dir = Vector3.FORWARD.rotated(Vector3.UP, rotation.y)
	
	if v_input != 0:
		moving = true
		move_and_slide(speed * v_input * dir, Vector3.UP)
	else:
		moving = false
		
	var pos = label_holder.global_transform.origin
	var cam = get_tree().get_root().get_camera()
	var screenpos = cam.unproject_position(pos)
	label_holder.get_node("PlayerLabel").set_position(screenpos)
	
	
	if moving:
		$delfin_con_patas/AnimationPlayer.play("Run")
	else:
		#$delfin_con_patas/AnimationPlayer.play("Idle")
		if $CamPivot/Camera.current:
			$delfin_con_patas/AnimationPlayer.play("Static")
		else:
			$delfin_con_patas/AnimationPlayer.play("Idle")
	
func _input(event):
	if event.is_action_pressed("ui_accept"):
		$Voices.get_child(randi() % $Voices.get_child_count()).play()
