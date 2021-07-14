extends Spatial

var move_left = "move_left"
var move_right = "move_right"
var move_up = "move_up"
var move_down = "move_down"
var action_a = "action_a"
var action_b = "action_b"

var id :int 


var bone_material : SpatialMaterial = SpatialMaterial.new()

var player
var player_id = 4
var index

func init(_player: Player,id,index):
	# Esta línea hará que el objeto sepa quién es su "dueño"
	set_network_master(_player.nid)
	player=_player
	# Esto configura los controles para cada botón
	# según haya elegido el jugador
	var ks = str(player.keyset)
	move_left = "move_left_" + ks
	move_right = "move_right_" + ks
	move_up = "move_up_" + ks
	move_down = "move_down_" + ks
	action_a = "action_a_" + ks
	action_b = "action_b_" + ks
	player_id = id
	var __ = connect("notify_bigness",index,"_on_notify_bigness")
	
	bone_material.albedo_color = player.color
	
	$Skel_base/Skel_armature/Skeleton/Skel_base.material_override = bone_material
	$floating_skull/Armature/Skeleton/Skeleton2.material_override = bone_material
	
	# Aquí puedes agregar otras cosas como:
	# obtener el nombre del jugador con player.name
	# obtener el color con player.color
	# También puedes guardar player en una
	# variable para acceder a ella después

var frozen : bool = true
func _on_freeze():
	frozen = true
	pass

func _on_unfreeze():
	frozen = false
	pass

func printsk(string):
	print("skeleton ",player.nid," : ",string)

func _input_bigger(input : String) -> void:
	if Input.is_action_just_pressed(input):
		rpc("_make_bigger",player_id)

func _process(delta):
	if frozen:
		return
	if is_network_master():
		_input_bigger(move_down)
		_input_bigger(move_left)
		_input_bigger(move_right)
		_input_bigger(move_up)
		_input_bigger(action_a)
		_input_bigger(action_b)
	
	self.scale = lerp(self.scale,_scale(biggyness)*Vector3.ONE,0.5)

var biggyness : float = 1.0
const biggyness_increment : float = 1.0

func _scale(bigg : float) -> float:
	return pow(bigg,0.333)

signal notify_bigness

remotesync func _make_bigger(whom: int):
	biggyness+=biggyness_increment
	emit_signal("notify_bigness",whom,biggyness)


