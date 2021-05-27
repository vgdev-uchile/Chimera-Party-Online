extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


export var wx : float = 1.0
export var wy : float = 1.0
export var wz : float = 1.0

func _process(delta):
	rotate_x(wx*delta)
	rotate_y(wy*delta)
	rotate_z(wz*delta)
