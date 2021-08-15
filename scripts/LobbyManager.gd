extends Node

# Default game port. Can be any number between 1024 and 49151.
#const DEFAULT_PORT = 10724
const DEFAULT_PORT = 10726

# Max number of client players.
const MAX_PEERS = 3

# Name for my player.
var player_name = ""

signal client_connected(state)

signal player_connected(id)
signal player_disconnected(id)

signal player_updated(player)
signal player_added(player)
signal player_removed(player)

signal port_opened(result)

var upnp = UPNP.new()

var thread = Thread.new()

# Connect all functions

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected", [], 1)
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected", [], 1)
	
func _player_connected(id):
	print(id)
	# Called on both clients and server when a peer connects. Send my info to it.
	if is_network_master():
		if Party._testing:
			Party._players[2].nid = id
			Party._test()
		var players = Party._players
		var players_data = []
		for player in players:
			players_data.push_back(player.get_data())
		rpc_id(id, "load_players", players_data, Party._testing, Party._current_game)
		Party.rpc_id(id, "_update_game_data", Party._current_game, Party._game_type, Party._get_teams_data())
	emit_signal("player_connected", id)

remote func load_players(players_data, testing, current_game):
	print("loading players")
	for player_data in players_data:
		var player = Player.new()
		player.load_data(player_data)
		Party._players.push_back(player)
	Party._testing = testing
	if testing:
		Party._current_game = current_game
		Party._test()
	else:
		Party._next()

func _player_disconnected(id):
	print("player disconected")
	if Party._current_game != "":
		Party._game_over()
	emit_signal("player_disconnected", id)

func _connected_ok():
	emit_signal("client_connected", true)
	pass # Only called on clients, not server.
	
	
func _connected_fail():
	emit_signal("client_connected", false)
	pass # Could not even connect to server; abort.

func _server_disconnected():
	Party._game_over()
	pass # Server kicked us; show error and abort.


	# Call function to update lobby UI here

func host_game(name, testing=false):
	player_name = name
	var host = NetworkedMultiplayerENet.new()
	var res = host.create_server(DEFAULT_PORT, 1 if testing else MAX_PEERS)
	if res == OK:
		get_tree().set_network_peer(host)
	return res

func open_port():
	thread.start(self, "thread_open_port")
#	thread.wait_to_finish()

func thread_open_port(userdata):
	var res = upnp.discover()
	if res != UPNP.UPNP_RESULT_SUCCESS:
		emit_signal("port_opened", false)
		return
	var gateway = upnp.get_gateway()
	res = gateway.add_port_mapping(DEFAULT_PORT, 0, "ChimeraParty", "UDP")
	print(res)
	if res != UPNP.UPNP_RESULT_SUCCESS:
		emit_signal("port_opened", false)
		return
	gateway.add_port_mapping(DEFAULT_PORT, 0, "ChimeraParty", "TCP")
	print(res)
	if res != UPNP.UPNP_RESULT_SUCCESS:
		emit_signal("port_opened", false)
		return
	emit_signal("port_opened", true)
	thread.call_deferred("wait_to_finish")


func join_game(name, ip):
	player_name = name
	var client = NetworkedMultiplayerENet.new()
	var res = client.create_client(ip, DEFAULT_PORT)
	if res == OK:
		get_tree().set_network_peer(client)
	return res

remote func add_player(player_data):
	print("adding_player")
	var player = Player.new()
	player.load_data(player_data)
	Party._players.push_back(player)
	emit_signal("player_added", player)

sync func remove_player(nid, local):
	var player
	for p in Party._players:
		if p.nid == nid and p.local == local:
			player = p
			break
	if player:
		Party._players.erase(player)
		emit_signal("player_removed", player)

sync func update_player(nid, local, properties, values):
	if properties.size() != values.size():
		return
	var player
	for p in Party._players:
		if p.nid == nid and p.local == local:
			player = p
			break
	if player:
		for i in range(properties.size()):
			player[properties[i]] = values[i]
		emit_signal("player_updated", player)

func game_over():
	get_tree().network_peer = null

#func _exit_tree():
#	thread.wait_to_finish()
