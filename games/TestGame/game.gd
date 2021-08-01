extends Node

var players
func _ready():
	players = Party.get_players().duplicate()
	
	for i in range(players.size()):
		var p = player_scene.instance()
		#p.init(players[i]) # Esta función se explicará más adelante
		player_container.add_child(p)
		# Definir aquí la posición inicial del jugador
		# y otras cosas que quieras hacer

# Cargamos la escena de los jugadores al principio
#var player_scene = preload()
# *puedes arrastrar tu escena dentro de los
# paréntesis y se rellenará automáticamente

var player_scene = preload("res://games/TestGame/player.tscn")
onready var player_container = $player_container

# Nodo, hijo de index, en que colocaremos a los jugadores
#var player_container = $Players


