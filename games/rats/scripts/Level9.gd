extends Node2D

signal check_next

onready var cheese_counter = Party.get_players().size()

var rats

var camera_rect : = Rect2()
onready var viewport_rect : = get_viewport_rect()

func _ready() -> void:
	$Cheese.counter = cheese_counter
	if is_network_master():
		$Cheese.connect("collected", self, "emit_check_next")

func emit_check_next():
	emit_signal("check_next")

func camera(rats):
	self.rats = rats
	move_camera()

func _physics_process(delta: float) -> void:
	move_camera()

func move_camera():
	camera_rect = Rect2(rats[0].global_position, Vector2())
	for i in rats.size():
		if i == 0:
			continue
		camera_rect = camera_rect.expand(rats[i].global_position)
	$Camera2D.global_position = camera_rect.position + camera_rect.size / 2
	var zoom = max(
		max(1, camera_rect.size.x / viewport_rect.size.x + 0.5),
		max(1, camera_rect.size.y / viewport_rect.size.y + 0.5)
	)
	$Camera2D.zoom = Vector2(zoom, zoom)
