extends Node

onready var Main = get_tree().get_root().get_node("Main") as Main

# Player colors
var _colors = [Color("#9fbc4d"), Color("#bc4d4f"), Color("#fdc760"), Color("#4d92bc")] setget , get_colors
func get_colors():
	return _colors

var _color_names = ["Verde", "Rojo", "Amarillo", "Azul"]
func get_color_names():
	return _color_names

# Game types
enum GameType {
	FREE_FOR_ALL = 1,
	ONE_VS_THREE = 2,
	TWO_VS_TWO = 4
}

# Current game info
var _current_game = ""

var _game_type = GameType.FREE_FOR_ALL setget set_game_type, get_game_type
func set_game_type(value):
	_game_type = value
func get_game_type():
	return _game_type

var _testing = false

# Round
var _rounds = 5 setget , get_rounds
func get_rounds():
	return _rounds

var _current_round = 1 setget , get_current_round
func get_current_round():
	return _current_round

# Array of all players
var _players = [] setget , get_players
func get_players():
	return _players

# Array of teams of players
# 1v3 [[p1], [p2, p3, p4]]
# 2v2 [[p1, p2], [p3, p4]]
var _teams = [] setget , get_teams
func get_teams():
	return _teams

func load_test(mode: String):
	var player0 = Player.new()
	player0.init("angry", 1, 0, 0, 1, 1)
	var player1 = Player.new()
	player1.init("OwO", 42, 1, 1, 2, 0)
	var player2 = Player.new()
	player2.init("troll69", 1, 1, 2, 0, 3)
	var player3 = Player.new()
	player3.init("HAF", 6489451867861349, 0, 3, 1, 2)
	match mode:
		"ffa":
			_game_type = GameType.FREE_FOR_ALL
			_players = [player0, player2, player3]
		"1v3":
			_game_type = GameType.ONE_VS_THREE
			_players = [player0, player1, player2, player3]
			_teams = [[player0], [player1, player2, player3]]
		"2v2":
			_game_type = GameType.TWO_VS_TWO
			_players = [player0, player1, player2, player3]
			_teams = [[player0, player1], [player2, player3]]
	# TODO: buscar forma de enviar por rpc los datos del modo de juego y teams
#	rpc("_update_game_data", _current_game, _game_type, _get_teams_data())
	

func _action_add_key(action, player_index: int, key):
	var ike: InputEventKey
	ike = InputEventKey.new()
	ike.scancode = key
	InputMap.action_add_event(action + str(player_index), ike)

func _make_teams():
	match _game_type:
		GameType.ONE_VS_THREE:
			var hplayer: Player = _players[0]
			for player in _players:
				if player.points > hplayer.points:
					hplayer = player
			var team = _players.duplicate()
			team.erase(hplayer)
			_teams = [[hplayer], team]
		GameType.TWO_VS_TWO:
			var hplayer: Player = _players[0]
			var lplayer: Player = _players[1]
			for player in _players:
				if player.points > hplayer.points:
					hplayer = player
				if player.points < lplayer.points:
					lplayer = player
			var team = _players.duplicate()
			team.erase(hplayer)
			team.erase(lplayer)
			_teams = [[hplayer, lplayer], team]

func _get_teams_data():
	var teams_data = []
	for team in _teams:
		var team_data = []
		for player in team:
			team_data.push_back({"nid": player.nid, "local": player.local})
		teams_data.push_back(team_data)
	print("Teams data: ", teams_data)
	return teams_data

func _set_teams_data(teams_data):
	_teams = []
	for team_data in teams_data:
		var team = []
		for player_data in team_data:
			var player
			for p in _players:
				if p.nid == player_data.nid and p.local == player_data.local:
					player = p
					break
			team.push_back(player)
		_teams.push_back(team)

remote func _update_game_data(current_game, game_type, teams_data):
	_current_game = current_game
	Party._game_type = game_type
	_set_teams_data(teams_data)
	Main.rpc_id(1, "confirm", 0.5)

func _next_game():
	Main.choose_random_game()
	_make_teams()
	print("Teams: ", _teams)
	Main.confirmations += 0.5
	rpc("_update_game_data", Party._current_game, Party._game_type, Party._get_teams_data())

# [{player, points}]
func end_game(score):
	for pp in score:
		LobbyManager.rpc(
			"update_player",
			pp.player.nid, pp.player.local,
			["points"], [pp.player.points + pp.points])
	if _testing:
		rpc("_test")
	else:
		rpc("_next")
	
sync func _next():
	Main.next()

sync func _test():
	Main.testing()

func _game_over():
	Main.start_game()
	LobbyManager.game_over()
	_players = []
	_current_round = 1

func game_started():
	return Main.game_state != Main.GameState.MENU
