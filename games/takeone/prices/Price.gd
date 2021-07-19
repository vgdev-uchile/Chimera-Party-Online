extends RigidBody2D


export var value = 1

puppet var puppet_vel = Vector2()
puppet var puppet_linear_vel = Vector2()
puppet var puppet_pos = Vector2()
puppet var puppet_ang = 0

var broadcasting = true
var destroy_y = 1200
var target_vel

func _ready():
	self.z_index = 10
	init(1)

func get_value():
	return value

func init(nid):
	set_network_master(nid)
	if not is_network_master():
		mode = RigidBody2D.MODE_KINEMATIC
		
func _physics_process(delta):
	if global_position.y > destroy_y:
		stop_broadcasting()
		call_deferred("queue_free")
		return
		
	if not broadcasting: return
	
	if is_network_master():
		rset("puppet_vel", linear_velocity)
		rset_unreliable("puppet_pos", position)
		rset_unreliable("puppet_ang", rotation_degrees)
	else:
		linear_velocity = lerp(linear_velocity, puppet_vel, 0.2)
		position = lerp(position, puppet_pos, 0.2)
		rotation_degrees = puppet_ang


remotesync func stop_broadcasting():
	set_physics_process(false)
	broadcasting = false
	mode = RigidBody2D.MODE_RIGID
	
