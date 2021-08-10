extends Spatial

class_name Main
# This node's work is to load the games and keep the flow

onready var fade = $Loading/Fade

enum LoadingStates {
	BLACK_1,
	LOADING,
	BLACK_2,
	PLAYING
}

var loading_state = LoadingStates.PLAYING
var current_world: Node = null
var loading_world = null

enum GameState {
	MENU = 1,
	LOBBY = 2,
	INTRO = 4,
	GAME = 8,
	SCORES = 16,
	END = 32,
	TESTING = 64
}

var game_state setget set_game_state

var games_ffa = []
var games_1v3 = []
var games_2v2 = []

# {game : weight}
var weights = {}

var first_time = true

# used to sync the game selection
var confirmations = 0

func load_world(scene_to_load: String, now = false):
	if now:
		if current_world:
			$World.remove_child(current_world)
			current_world.queue_free()
			current_world = null
		current_world = load(scene_to_load).instance()
		$World.add_child(current_world)
	else:
		loading_world = scene_to_load
		ResourceQueue.queue_resource(loading_world)
		loading_state = LoadingStates.BLACK_1
		fade.fade_out()
	

func on_finished_fading():
	match loading_state:
		LoadingStates.BLACK_1:
			$World.visible = false
			if current_world:
				$World.remove_child(current_world)
				current_world.queue_free()
				current_world = null
			$Loading/ColorRect.visible = true 
			loading_state = LoadingStates.LOADING
			fade.fade_in()
		LoadingStates.LOADING:
			set_process(true)
		LoadingStates.BLACK_2:
			$Loading/ColorRect.visible = false
			$World.visible = true
			loading_state = LoadingStates.PLAYING
			fade.fade_in()
		LoadingStates.PLAYING:
			if current_world.has_method("on_show"):
				current_world.on_show()
		_:
			pass

func _process(_delta):
	if ResourceQueue.is_ready(loading_world):
		loading_state = LoadingStates.BLACK_2
		var new_world = ResourceQueue.get_resource(loading_world)
		current_world = new_world.instance()
		
		if current_world.has_signal("show"):
			current_world.connect("show", fade, "fade_out")
			if current_world.has_signal("error"):
				current_world.connect("error", self, "on_error")
			
		if game_state == GameState.INTRO:
			#Delay adding the word until all know the current game and teams
			if is_network_master():
				Party._next_game()
		
		if game_state & (GameState.INTRO | GameState.GAME | GameState.SCORES):
			# delay until all confirm
			if game_state != GameState.INTRO:
				# intro waits until all get the current game
				rpc_id(1, "confirm")
			else:
				rpc_id(1, "confirm", 0.5)
		else:
			add_world()
		set_process(false)

sync func add_world():
	$World.add_child(current_world)
	if not current_world.has_signal("show"):
		fade.fade_out()

func on_error():
	first_time = true
	set_game_state(GameState.MENU)
	fade.fade_out()
	LobbyManager.game_over()

func start_game():
	set_game_state(GameState.MENU)

#	Party._new_game = true
#	Party.current_round = 1
#	load_games()

func _ready():
	var meh = IP.get_local_addresses()
	set_process(false)
	fade.connect("finished_fading", self, "on_finished_fading")
	ResourceQueue.start()
	load_games()
	start_game()

func load_games():
	var games = []
	var directory: Directory = Directory.new()
	if directory.open("res://games/") == OK:
		directory.list_dir_begin(true)
		var game = directory.get_next()
		while game != "":
			if directory.current_is_dir():
				print(game + "/", "found")
				var config: Config = load("res://games/"+game+"/config.tres")
				if not config.playable:
					print(game, " is not playable")
					game = directory.get_next()
					continue
				# Saving game modes for quick access
				for mode in config.modes:
					if mode is GameMode1v3:
						games_1v3.push_back(game)
					elif mode is GameMode2v2:
						games_2v2.push_back(game)
					elif mode is GameModeFFA:
						games_ffa.push_back(game)
				games.push_back(game)
			else:
				print(game, " found. There shouldn't be a file here")
			game = directory.get_next()
	else:
		print("Error opening directory")
	
	var game_weight = 1.0 / games.size()
	for game in games:
		weights[game] = game_weight

func choose_random_game():
	randomize()
	var games = []
	var only_ffa = Party._players.size() != 4
	
	if only_ffa:
		games = games_ffa
	else:
		games = games_ffa + games_1v3 + games_2v2
		# Remove duplicates
		print("Games: ", games)
		var index = 0
		while index < games.size():
			var found = games.rfind(games[index])
			if found == index:
				index += 1
			else:
				games.remove(found)
		print("Games: ", games)

	var choosen = randf()
	var weight_sum = 0
	for game in games:
		weight_sum += weights[game]
		if weight_sum >= choosen:
			var old_game_weigth = weights[game]
			weights[game] /= 10.0
			
			var total_weight = 1.0 - old_game_weigth + weights[game]
			# normalize weights
			
			for g in weights:
				weights[g] /= total_weight
			
			
			Party._current_game = game
			
			if not only_ffa:
				var config: Config = load("res://games/"+game+"/config.tres")
				var mode_index = randi() % config.modes.size()
				var game_type = config.modes[mode_index]
				print("1v3: ", game_type is GameMode1v3, ". 2v2: ", game_type is GameMode2v2)
				if game_type is GameMode1v3:
						print("Juego 1v3")
						Party._game_type = Party.GameType.ONE_VS_THREE
				elif game_type is GameMode2v2:
						print("Juego 2v2")
						Party._game_type = Party.GameType.TWO_VS_TWO
				elif game_type is GameModeFFA:
						print("Juego FFA")
						Party._game_type = Party.GameType.FREE_FOR_ALL
				else:
					print("No se econtró el modo de juego, esto no debería pasar.")
			else:
				Party._game_type = Party.GameType.FREE_FOR_ALL
			
			return
	
	print("No game found, this should never happened")



func next():
	match game_state:
		GameState.MENU:
			set_game_state(GameState.LOBBY)
		GameState.LOBBY:
			set_game_state(GameState.INTRO)
		GameState.INTRO:
			set_game_state(GameState.GAME)
		GameState.GAME:
			set_game_state(GameState.SCORES)
		GameState.SCORES:
			set_game_state(GameState.INTRO)

func testing():
	set_game_state(GameState.TESTING)

func set_game_state(new_state):
	game_state = new_state
	match game_state:
		GameState.MENU:
			load_world("res://scenes/Menu.tscn", first_time)
			first_time = false
		GameState.LOBBY:
			load_world("res://scenes/Lobby.tscn")
		GameState.INTRO:
			load_world("res://scenes/Intro.tscn")
		GameState.GAME, GameState.TESTING:
			load_world("res://games/"+ Party._current_game + "/index.tscn")
		GameState.SCORES:
			load_world("res://scenes/Scores.tscn")

master func confirm(value=1):
	confirmations += value
	if confirmations == get_tree().get_network_connected_peers().size() + 1:
		confirmations = 0
		rpc("add_world")
