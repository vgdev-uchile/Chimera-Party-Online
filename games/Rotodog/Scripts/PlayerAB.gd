extends Node2D


var r = 0

var increment = false
var color = Color(1,1,1,1)
var colors = [
	Color(0, 1, 0, 1),
	Color(0, 1, 0, 1),
	Color(0, 0, 1, 1),
	Color(1, 1, 0, 1),
]

var score = 0

var start_time = 0

var next_note = null
var epsilon = 0.15
var player
var dog

onready var conductor = get_parent().get_node("Conductor")
onready var note_container = conductor.get_node("NoteContAB")
onready var parts_perfect = $ParticlesPerfect
onready var parts_great = $ParticlesGreat

onready var R = conductor.R

var move_left = "move_left"
var move_right = "move_right"
var move_up = "move_up"
var move_down = "move_down"
var action_a = "action_a"
var action_b = "action_b"

var next_arrow = 0
var arrow_order
var part_em_perf = 0
var part_em_good = 0

export (int) var swap_dance_on = 20
var hits = 0
var combo = 0
var phase = 0

var frame_time = 1.0/60.0
export (Array, float) var time_windows = [5, 7.5, 10, 12.5, 15]
enum acc {PERFECT, GREAT, GOOD, BAD, MISS}


func init(p, d):
	player = p
	dog = d
	set_network_master(p.nid)
	var spi = str(p.keyset)
	move_left = "move_left_" + spi
	move_right = "move_right_" + spi
	move_up = "move_up_" + spi
	move_down = "move_down_" + spi
	action_a = "action_a_" + spi
	action_b = "action_b_" + spi
	#arrow_order = [move_left, move_up, move_right, move_down]


func _draw():
	draw_arc(Vector2.ZERO, R, 0, 2*PI, 64, Color(1, 1, 1, 1), 3, true)


func _input(event):
	if event.is_action_pressed(move_right):
		print("left")
		check_note_hit(0)
		get_tree().set_input_as_handled()
		return
	
	if event.is_action_pressed(move_up):
		print("up")
		check_note_hit(1)
		get_tree().set_input_as_handled()
		return
	
	if event.is_action_pressed(move_left):
		print("right")
		check_note_hit(2)
		get_tree().set_input_as_handled()
		return
	
	if event.is_action_pressed(move_down):
		print("down")
		check_note_hit(3)
		get_tree().set_input_as_handled()
	
	if event.is_action_pressed(action_a):
		check_note_hit(4)
		get_tree().set_input_as_handled()

	if event.is_action_pressed(action_b):
		check_note_hit(5)
		get_tree().set_input_as_handled()
		


func check_note_hit(action):
	if note_container.get_child_count() == 0:
		return
	var song_pos = conductor.song_pos
	next_note = note_container.get_child(0)
	var hit = false
	var push_delay = abs(next_note.note_time - song_pos)
	
	if  push_delay > time_windows[acc.BAD] * frame_time:
		return
	
	match next_note.color:
		0: # Arrows
			if action == next_arrow:
				next_arrow = (next_arrow + 1) % 4
				hit = true
		3: # A
			if action == 4:
				hit = true
		1: # B
			if action == 5:
				hit = true
	
	if hit:
		hits += 1
		if hits == swap_dance_on:
			hits = 0
			dog.swap_dance(phase)
		add_score(push_delay)
	else:
		add_score(time_windows[acc.MISS] * frame_time)
	
	next_note.queue_free()
		
	print("note time: {nt}; song pos: {sp} {hit}".format({
		"nt": next_note.note_time,
		"sp": song_pos,
		"hit": "Hit" if hit else ""
	}))


func set_label_text(n):
	var t
	var c
	"[center][rainbow freq=0.1 sat=0.7 value=1 ]↑↓→←AB[/rainbow][/center]"
	match n:
		-1:
			t = ""
		0:
			t = ["→", "↑", "←", "↓"][next_arrow]
			c = "#ff00ff"
		1:
			t = "B"
			c = "#ff0000"
		3:
			t = "A"
			c = "#0000ff"
	$RichTextLabel.parse_bbcode(
		"[center][color={color}]{t}[/color][/center]".format(
			{"t": t, "color": c}))


func add_score(delay):
	var s = 0
	if delay < time_windows[acc.PERFECT] * frame_time:
		s = 100
		parts_perfect.get_child(part_em_perf).emitting = true
		part_em_perf = (part_em_perf + 1) % 8
		$SoundPerfect.play()
	elif delay < time_windows[acc.GREAT] * frame_time:
		s = 50
		parts_great.get_child(part_em_good).emitting = true
		part_em_good = (part_em_good + 1) % 8
		$SoundGreat.play()
	elif delay < time_windows[acc.GOOD] * frame_time:
		s = 25
		$SoundGood.play()
	elif delay < time_windows[acc.BAD] * frame_time:
		s = 1
		$SoundBad.play()
	else:
		s = -10
		$SoundMiss.play()
	dog.rpc("add_score", s)
