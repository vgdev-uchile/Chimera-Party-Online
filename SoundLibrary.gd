extends Node2D

# Cómo se usa? ###########################

## Añadir sonidos:
# Cada hijo de este nodo es un "tipo" de sonido, (saltar, morir, comer, etc)
# los nodos tienen nombres como:
# dddnombre   , en que ddd es un entero desde el 1 al 999
# para agregar sonidos de un tipo nuevo, crear un nodo vacío con ese nombre
# y ponerle nodos audioStreamPlayer

## Hacerlo sonar en un juego:
# agregar este nodo a una escena y llamarlo desde el código usando SoundLibrary.make_sound(numero_de_sonido_requerido)
#
# ejemplo:
# # ponerlo en el código
#
# var soundlibrary = get_node("SoundLibrary")
#
# # hacer sonar el sonido 001:
#
# soundlibrary.make_sound(1)

###########################################

#### Ready ####################################
var _rng = RandomNumberGenerator.new()
var is_ready = false
func _ready():
	_rng.randomize()
	_make_sound_library()
	is_ready=true

	_config()

## Front end ##################################

func make_sound(s_type):
	if !is_ready:
		return
	s_type = s_type%_n_type_sounds
	_sound_dictionary[s_type][_rng.randi()%_n_sounds_by_type[s_type]].play()

func adjust_vol_by_type(s_type,target_volume):
	# make sure doesn't break
	target_volume = min(24,target_volume)
	s_type        = s_type%_n_type_sounds

	#adjust manually
	for child in _sound_dictionary[s_type]:
		child.volume_db=target_volume

func _config():
	# minor configurations
	
	#jump 
	adjust_vol_by_type(1,-20)
	#feet leaving ground
	adjust_vol_by_type(2,-20)
	# cry
	adjust_vol_by_type(4,-10)
	pass

## Library construction #######################

var _n_type_sounds    = 1
var _n_sounds_by_type = []
var _sound_dictionary = []
func _make_sound_library():
	_n_type_sounds = get_child_count()
	_n_sounds_by_type.resize(_n_type_sounds)
	_sound_dictionary.resize(_n_type_sounds)

	for sound_type in get_children():
		# info about soundtype 
		var sound_type_id  = int(sound_type.name.left(3))
		var children       = sound_type.get_children()
		var children_count = sound_type.get_child_count()
		
		# new data
		_n_sounds_by_type[sound_type_id] = children_count

		var minor_dictionary = []
		minor_dictionary.resize(children_count)
		for i in range(children_count):
			minor_dictionary[i]=children[i]

		_sound_dictionary[sound_type_id] = minor_dictionary

## Debug #####################################
#
#const debug_on = false
#const debug_rand = true
#const debugged_sound = 1
#
#func _physics_process(_delta):
#	if Input.is_key_pressed(KEY_0):
#		if !debug_rand:
#			make_sound(debugged_sound)
#		else:
#			make_sound(_rng.randi())
