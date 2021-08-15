extends Node


# Función para sacar una captura de pantalla para la imagen de la intro
# La pongo acá porque me da lata buscar cómo lo hacía a cada rato
# Hay que poner el nombre del juego en la ruta de guardado
func _input(event):
	if event.is_action_pressed("ui_accept"):
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		image.save_png("res://games/[juego]/intro.png")
