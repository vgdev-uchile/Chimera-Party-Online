extends CanvasLayer

var _labels = []
var _lifespans = []
var _ages = []

var container = VBoxContainer.new()
var theme = Theme.new()

var font_size = 2

func _ready():
	container.rect_position = Vector2(10, 10)
	container.rect_scale = Vector2(font_size, font_size)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	theme.set_color("font_color", "Label", Color.white)
	theme.set_color("font_color_shadow", "Label", Color.black)
	theme.set_constant("shadow_as_outline", "Label", 1)
	layer = 128

func _process(delta):
	for i in range(_labels.size() - 1, -1, -1):
		_ages[i] += delta
		if _ages[i] > _lifespans[i]:
			container.remove_child(_labels[i])
			_labels.remove(i)
			_lifespans.remove(i)
			_ages.remove(i)

func print(string, lifespan = 2.0):
	var label = Label.new()
	label.set_theme(theme)
	label.text = str(string)
	container.add_child(label)
	_labels.append(label)
	_lifespans.append(lifespan)
	_ages.append(0)
