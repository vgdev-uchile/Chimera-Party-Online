extends Resource

export (float) var time = 0
export (float) var duration = 0
const colors = [
	Color(1,0,1,1),
	Color.red,
	Color.green,
	Color.blue,
	Color.yellow
]
export (int, "White", "Red", "Green", "Blue", "Yellow") var color = 0 setget set_color

var conductor = null

export (bool) var anim_event
export (String) var animation_name
export (String) var anim_player_path
export (bool) var meth_event
export (String) var method_name


func play_event():
	if anim_event:
		play_anim()
	if meth_event:
		conductor_call()


func play_anim():
	conductor.get_node(anim_player_path).play(animation_name)
	
func conductor_call():
	conductor.call(method_name)


func set_color(c):
	if c is int:
		color = c
		return
	for i in range(colors.size()):
		if colors[i] == c:
			color = i
			return
	color = 0
	
func get_color():
	return colors[color]
	
func get_color_index():
	return color
