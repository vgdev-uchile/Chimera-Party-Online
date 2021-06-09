extends Node


export var bpm = 120
var crotchet
var song_pos = 0 setget ,get_song_position
var song = null
var next_note = 0
var max_notes
var start_time = 0
var next_event = 0
var max_events = 0

export (Resource) var level
export var R = 150
export (Resource) var event_map

var notes
var events

onready var song_player = $BGM
onready var note_container = $NoteContAB
onready var note_scene = preload("res://games/Rotodog/Scenes/RingNote.tscn")
onready var light = get_node("../../Light")
onready var note_light: OmniLight = light.get_node("NoteLight")
onready var light_material = light.get_surface_material(0)
onready var playerNode = get_node("../PlayerAB")
onready var playerContainer = get_node("../../Plane/Players")


func _ready():
	notes = level.notes.duplicate()
	events = event_map.notes.duplicate()
	for i in range(level.notes.size()):
		notes[i].time -= 2
	crotchet = 60 / bpm
	max_notes = notes.size() - 1
	max_events = events.size() - 1
	$AnimationPlayer.play("start")


func _process(delta):
	song_pos = song_player.get_playback_position() + \
				AudioServer.get_time_since_last_mix() - \
				AudioServer.get_output_latency()

	if song_pos >= notes[next_note].time and next_note < max_notes:
		var new_note = note_scene.instance()
		new_note.color = notes[next_note].get_color_index()
		new_note.note_spawn = notes[next_note].time
		note_container.add_child(new_note)
		#if next_note < max_notes:
		next_note += 1

	if note_container.get_child_count() > 0:
		var curr_note = note_container.get_child(0)
		var curr_color = curr_note.colors[curr_note.color]
		var note_percentage = (song_pos - curr_note.note_spawn) / curr_note.note_duration
		note_percentage = clamp(note_percentage, note_percentage, 1.0)
		light_material.albedo_color = Color.white.linear_interpolate(curr_color, note_percentage)
		note_light.light_color = curr_color
		note_light.omni_range = 4 + 2.6 * note_percentage
		playerNode.set_label_text(curr_note.color)
	else:
		light_material.albedo_color = Color.white
		note_light.omni_range = 0.1
		note_light.light_color = Color.white
		playerNode.set_label_text(-1)
		
	if events.size() > 0 and song_pos >= events[next_event].time:
		var ev = events.pop_front()
		ev.conductor = self
		ev.play_event()
		#if next_event < max_events:
		#	next_event += 1


func miss():
	playerNode.get_node("SoundMiss").play()


func start_song():
	if not song_player.playing:
		start_time = OS.get_ticks_msec()
		song_player.play()


func get_song_position():
	if song_player.playing:
		return song_pos
	return 0


func change_phase():
	playerNode.phase = 1


func universe_poses():
	for child in playerContainer.get_children():
		child.change_dance(2)


func dogDimensionDance():
	for child in playerContainer.get_children():
		child.change_dance(1)


func cam_to_origin():
	get_parent().get_parent().cam_to_origin()


func win_poses():
	for child in playerContainer.get_children():
		child.change_dance(3)
