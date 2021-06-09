extends Spatial




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
func call_rotate(h,v):
	rpc("rotate",h,v)
remotesync func rotate(h,v):
	rotate_y(h)
	rotate_x(v)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
