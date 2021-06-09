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
