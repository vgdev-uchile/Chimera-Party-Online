extends StaticBody2D

onready var initial_position = position
onready var target = initial_position

export var button: NodePath
onready var _button = get_node(button)

func _ready() -> void:
	if is_network_master():
		if _button:
			_button.connect("pushed", self, "open")
			_button.connect("released", self, "close")


func _physics_process(delta: float) -> void:
#	if Input.is_action_just_pressed("action_a"):
#		open()
#	if Input.is_action_just_pressed("action_b"):
#		close()
	if position != target:
		position = lerp(position, target, 0.25)

func open():
	rpc("sync_open")

sync func sync_open():
	target = initial_position - $CollisionShape2D.shape.extents.y * 2 * transform.y

func close():
	rpc("sync_close")

sync func sync_close():
	target = initial_position
