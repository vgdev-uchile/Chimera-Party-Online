extends CanvasLayer

var testing = false

var games = [Party.Main.games_ffa, Party.Main.games_1v3, Party.Main.games_2v2]
var games_count = []

func _ready():
	$Panel/CenterContainer/Main/Start.grab_focus()
	$Panel/CenterContainer/Main/Start.connect("pressed", self, "_on_start_pressed")
	$Panel/CenterContainer/Main/Settings.connect("pressed", self, "_on_settings_pressed")
	$Panel/CenterContainer/Main/Test.connect("pressed", self, "_on_test_pressed")
	$Panel/CenterContainer/Main/TestContainer/Cancel.connect("pressed", self, "_on_cancel_pressed")
	$Panel/CenterContainer/Main/Exit.connect("pressed", self, "_on_exit_pressed")
	
	$Panel/CenterContainer/Start/Back.connect("pressed", self, "_on_back_pressed")
	$Panel/CenterContainer/Start/HBoxContainer/Host.connect("pressed", self, "_on_host_pressed")
	$Panel/CenterContainer/Start/HBoxContainer2/Join.connect("pressed", self, "_on_join_pressed")
	
	if OS.has_environment("USERNAME"):
		$Panel/CenterContainer/Start/HBoxContainer/Name.text = OS.get_environment("USERNAME")
	
	for mode in games:
		for game in mode:
			$Panel/CenterContainer/Main/TestContainer/Games.add_item(game)
		games_count.append(mode.size())

func _on_start_pressed():
	$Panel/CenterContainer/Main.hide() 
	$Panel/CenterContainer/Start.show()
	$Panel/CenterContainer/Start/HBoxContainer/Host.grab_focus()
	
func _on_settings_pressed():
	pass

func _on_test_pressed():
	testing = true
	$Panel/CenterContainer/Main/Test.hide()
	$Panel/CenterContainer/Main/TestContainer.show()

func _on_cancel_pressed():
	testing = false
	$Panel/CenterContainer/Main/Test.show()
	$Panel/CenterContainer/Main/TestContainer.hide()

func _on_exit_pressed():
	get_tree().quit()

func _on_back_pressed():
	$Panel/CenterContainer/Main.show()
	$Panel/CenterContainer/Start.hide()

func _on_host_pressed():
	var name = $Panel/CenterContainer/Start/HBoxContainer/Name.text
	if name == "":
		$Panel/CenterContainer/Error.text = "Nombre incorrecto!"
		return
	
	$Panel/Error.text = ""
	if LobbyManager.host_game(name, testing) == OK:
		if testing:
			Party._testing = true
			var selected_game = $Panel/CenterContainer/Main/TestContainer/Games.selected
			if selected_game < games_count[0]:
				Party._current_game = Party.Main.games_ffa[selected_game]
				Party.load_test("ffa")
			else:
				selected_game -= games_count[0]
				if selected_game < games_count[1]:
					Party._current_game = Party.Main.games_1v3[selected_game]
					Party.load_test("1v3")
				else:
					selected_game -= games_count[1]
					if selected_game < games_count[2]:
						Party._current_game = Party.Main.games_2v2[selected_game]
						Party.load_test("2v2")

			$Panel/CenterContainer/Start/HBoxContainer/Host.disabled = true
		else:
			Party._next()
	else:
		$Panel/Error.text = "Error al hostear"

func _on_join_pressed():
	var name = $Panel/CenterContainer/Start/HBoxContainer/Name.text
	if name == "":
		$Panel/Error.text = "IP incorrecta!"
		return
	
	$Panel/Error.text = ""
	var ip = $Panel/CenterContainer/Start/HBoxContainer2/IP.text
	
	if LobbyManager.join_game(name, ip) != OK:
		$Panel/Error.text = "Error al hostear"

