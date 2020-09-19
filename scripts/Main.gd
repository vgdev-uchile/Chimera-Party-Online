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

func _process(delta):
	if ResourceQueue.is_ready(loading_world):
		loading_state = LoadingStates.BLACK_2
		var new_world = ResourceQueue.get_resource(loading_world)
		current_world = new_world.instance()
		
		if current_world.has_signal("show"):
			current_world.connect("show", fade, "fade_out")
			
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

func start_game():
	set_game_state(GameState.MENU)

#	Party._new_game = true
#	Party.current_round = 1
#	load_games()

func _ready():
	set_process(false)
	fade.connect("finished_fading", self, "on_finished_fading")
	ResourceQueue.start()
	load_games()
	start_game()

func load_games():
	var directory: Directory = Directory.new()
	if directory.open("res://games/") == OK:
		directory.list_dir_begin(true)
		var game = directory.get_next()
		while game != "":
			if directory.current_is_dir():
				print(game + "/", "found")
				var config: Config = load("res://games/"+game+"/config.tres")
				# Saving game modes for quick access
				for mode in config.modes:
					if mode is GameMode1v3:
						games_1v3.push_back(game)
					elif mode is GameMode2v2:
						games_2v2.push_back(game)
					elif mode is GameModeFFA:
						games_ffa.push_back(game)
				weights[game] = 1
			else:
				print(game, " found. There shouldn't be a file here")
			game = directory.get_next()
	else:
		print("Error opening directory")

func choose_random_game():
	var games = []
	match Party._game_type:
		Party.GameType.FREE_FOR_ALL:
			games = games_ffa
		Party.GameType.ONE_VS_THREE:
			games = games_1v3
		Party.GameType.TWO_VS_TWO:
			games = games_2v2

	var weight_total = 0
	for game in games:
		weight_total += weights[game]
	var choosen = randf() * weight_total
	var weight_sum = 0
	for game in games:
		weight_sum += weights[game]
		if weight_sum >= choosen:
			weights[game] /= 2
			Party._current_game = game
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
