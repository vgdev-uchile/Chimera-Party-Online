extends Node2D


export (int, "White", "Red", "Green", "Blue", "Yellow") var color setget set_color
enum {WHITE, RED, GREEN, BLUE, YELLOW}
const colors = [
	Color(0,1,0,1),
	Color(1,0,0,1),
	Color(0,1,0,1),
	Color(0,0,1,1),
	Color(1,1,0,1)
]
var r = 0

var note_duration = 2.0
var note_spawn = 0.0
var frame_time = 1.0/60.0
var miss_time = 10 * frame_time
onready var note_time: float = note_spawn + note_duration
onready var conductor = get_parent().get_parent()

onready var R = conductor.R


func _draw():
	draw_arc(Vector2.ZERO, r, 0, 2*PI, 64, colors[color], 2, true)

func update_time():
	note_time = note_spawn + note_duration

func _process(delta):
	var d = (conductor.get_song_position() - note_spawn)
	r = R * d / note_duration
	if d > note_duration + miss_time:
		#conductor.miss()
		queue_free()
	update()
	
func set_color(c):
	if c is int:
		color = c
	else:
		color = colors.find(c)

