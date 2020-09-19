extends StaticBody2D


var delta_acc = 0
var falling = false
var y_acc = 0

func _ready():
	set_process(false)
	set_physics_process(false)
	$Timer.connect("timeout", self, "on_timeout")

func _process(delta):
	$Sprite.position = Vector2(randf(), randf()) * 8
	$Sprite.modulate.v -= delta / 10

func _physics_process(delta):
	position.y += delta_acc / 2
	delta_acc += 3 * delta
	var scale_factor = max(0, 4 - delta_acc)
	if scale_factor == 0:
		set_physics_process(false)
		hide()
	$Sprite.scale = Vector2.ONE * scale_factor

sync func fall():
	falling = true
	set_process(true)
	if not get_tree().network_peer or is_network_master():
		$Timer.start()

func on_timeout():
	if get_tree().network_peer:
		rpc("drop")
	else:
		drop()
	
sync func drop():
	set_process(false)
	set_physics_process(true)
	$CollisionPolygon2D.disabled = true
	$Sprite.position = Vector2()
	$Sprite.z_index = -2

func stop():
	if falling and is_processing():
		if is_network_master():
			$Timer.stop()
		set_process(false)
		$Sprite.position = Vector2()
	
	

#func _input_event(viewport, event, shape_idx):
#	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
#		fall()
