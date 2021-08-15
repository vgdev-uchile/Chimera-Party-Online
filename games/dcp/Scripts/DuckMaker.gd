extends Spatial


const duck_scene = preload("res://games/dcp/Scenes/Duck.tscn")

export (int) var max_ducks = 100
var duck_count = 0
onready var duck_container = get_parent().get_node("../Ducks")



func _on_Timer_timeout():
	var new_duck = duck_scene.instance()
	#duck_container.add_child(new_duck)
	add_child(new_duck)
	duck_count += 1
	if duck_count >= max_ducks:
		$Timer.stop()
