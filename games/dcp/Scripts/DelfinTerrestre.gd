extends KinematicBody


const material_buenas_tardes = preload("res://games/dcp/Resources/DCP_BT.tres")

export (float) var speed = 10
export (float) var rot_speed = 1
export (float) var gravity = 9.8

var dir: Vector3 = Vector3.FORWARD
remotesync var moving = false
var v_speed = 0
var velocity = Vector3.ZERO
var owo = false
var ded = false
var can_move = false

var move_left = "move_left"
var move_right = "move_right"
var move_up = "move_up"
var move_down = "move_down"
var action_a = "action_a"
var action_b = "action_b"

var player

puppet var puppet_pos = Vector3.ZERO
puppet var puppet_rot = 0
puppet var puppet_linear_vel = Vector3.ZERO
puppet var puppet_moving = false

onready var label_holder = $LabelHolder
onready var name_label = label_holder.get_node("PlayerLabel/RichTextLabel")
onready var voices = $VoicesGM
onready var nowos = $Nowos
onready var transform_voice = $TransformationVoice/BuenasTardes
onready var voices_ohno = $VoicesOhNo
onready var main_scene = get_parent().get_parent()


func _ready():
	dir = Vector3.FORWARD.rotated(Vector3.UP, rotation.y)
	$delfin_con_patas/AnimationPlayer.play("Idle")
	name_label.set("custom_fonts/normal_font", name_label.get_font("normal_font").duplicate())


func init(p: Player):
	player = p
	set_network_master(p.nid)
	var spi = str(p.keyset)
	move_left = "move_left_" + spi
	move_right = "move_right_" + spi
	move_up = "move_up_" + spi
	move_down = "move_down_" + spi
	action_a = "action_a_" + spi
	action_b = "action_b_" + spi
	name = "%d - %d" % [p.nid, p.local]
	name_label.get("custom_fonts/normal_font").outline_color = Party.get_colors()[p.color]
	#name_label.set("custom_fonts/normal_font/outline_color", Party.get_colors()[p.color])
	name_label.parse_bbcode("[center]" + p.name + "[/center]")
	#if is_network_master():
	#	name_label.visible = false
	

master func swap_camera():
	$CamPivot/Camera2.current = true
	if owo:
		voices = transform_voice.get_parent()
	else:
		voices = $VoicesGA

remotesync func talk(n):
	voices.get_child(n).play()
	print(main_scene.ball.translation)

remotesync func buenas_tardes():
	if main_scene.buenas_tardes: return
	main_scene.buenas_tardes = true
	transform_voice.play()
	yield(transform_voice, "finished")
	owo = true
	$delfin_con_patas/Armature/Skeleton/Cube.material_override = material_buenas_tardes
	main_scene.buenas_tardes_mode()
	voices = $TransformationVoice
	$HuntArea.monitoring = true

func _physics_process(delta):
	if ded or not can_move: return
	var h_speed = Vector3.ZERO
	
	if is_network_master():
		var h_input = Input.get_action_strength(move_right) - Input.get_action_strength(move_left)
		var v_input = Input.get_action_strength(move_up) - Input.get_action_strength(move_down)
		
		if h_input != 0:
			rotation.y = rotation.y - rot_speed * h_input * delta
			dir = Vector3.FORWARD.rotated(Vector3.UP, rotation.y)
		
		if v_input != 0:
			moving = true
			h_speed = speed * v_input * dir
		else:
			moving = false
		
		if is_on_floor():
			v_speed = -gravity * delta
		else:
			v_speed -= gravity * delta

		velocity = move_and_slide(Vector3(h_speed.x, v_speed, h_speed.z), Vector3.UP)
		rset("puppet_rot", rotation.y)
		rset("puppet_linear_vel", velocity)
		rset("puppet_pos", translation)
		rset_unreliable("moving", moving)
	else:
		rotation.y = puppet_rot
		velocity = puppet_linear_vel
		moving = puppet_moving
		move_and_slide(velocity, Vector3.UP)
		#translation = lerp(translation, puppet_pos, 0.5)
	
	# Name label position fix
	#if not is_network_master():
	if $VisibilityNotifier.is_on_screen():
		label_holder.visible = true
		var pos = label_holder.global_transform.origin
		var cam = get_tree().get_root().get_camera()
		var screenpos = cam.unproject_position(pos)
		label_holder.get_node("PlayerLabel").set_position(screenpos)
	else:
		label_holder.visible = false
	
	if moving:
		$delfin_con_patas/AnimationPlayer.play("Run")
	else:
		if $CamPivot/Camera.current:
			$delfin_con_patas/AnimationPlayer.play("Static")
		else:
			$delfin_con_patas/AnimationPlayer.play("Idle")

func _input(event):
	if not is_network_master(): return
	if event.is_action_pressed(action_a):
		rpc("talk", randi() % voices.get_child_count())
	
	if event.is_action_pressed(action_b):
		if main_scene.owo:
			rpc("buenas_tardes")
		elif main_scene.buenas_tardes:
			rpc("talk", randi() % voices.get_child_count())
		else:
			nowos.get_child(randi() % nowos.get_child_count()).play()

func _on_HuntArea_body_entered(body):
	if is_network_master():
		body.rpc("fucking_die", randi() % voices_ohno.get_child_count())

remotesync func fucking_die(n):
	voices_ohno.get_child(n).play()
	ded = true
	if is_network_master():
		main_scene.get_node("PatoRealPOV").current = true
