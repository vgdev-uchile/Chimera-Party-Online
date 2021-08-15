extends RigidBody

var can_move = true
puppet var puppet_pos = Vector3.ZERO


# Called when the node enters the scene tree for the first time.
func _ready():
	puppet_pos = translation


func _physics_process(delta):
	if not can_move: return
	if is_network_master():
		rset_unreliable("puppet_pos", translation)
	else:
		translation = lerp(translation, puppet_pos, 0.2)
