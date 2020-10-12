extends CanvasLayer

# to keep on loading until all is ready
signal show

# returns to menu screen if error during loading
signal error

# called when this screen is already visible
func on_show():
	print("owo")

var keysets_taken = []

#var slot_used = []

var local_players = {}

enum State { WAITING, COUNT_DOWN, GO}
var current_state = State.WAITING

remote var colors_taken = []

onready var player_selection = $Panel/PlayerSelection
onready var playback = $AnimationTree.get("parameters/playback")


var remote_player_waiting = 0

func _ready():
	for i in range(4):
		var ps = player_selection.get_child(i)
		ps.connect("leave", self, "release_slot")
		ps.connect("player_ready", self, "on_player_ready")
	LobbyManager.connect("player_added", self, "on_player_added")
	LobbyManager.connect("player_removed", self, "on_player_removed")
	LobbyManager.connect("player_disconnected", self, "player_disconnected")
	LobbyManager.connect("port_opened", self, "on_port_opened")
	if is_network_master():
		LobbyManager.open_port()
	else:
		print("ready ", Party._players)
		if Party._players == []:
			emit_signal("show")
			return
		
		# load ps
		for player in Party._players:
			var ps = player_selection.get_child(player.slot)
			ps.connect("remote_init_completed", self, "on_remote_init_completed")
			ps.remote_init(player)
			remote_player_waiting += 1

func on_port_opened(result):
#	LobbyManager.thread.wait_to_finish()
	if result:
		emit_signal("show")
	else:
		call_deferred("emit_signal", "error")

func on_remote_init_completed():
	remote_player_waiting -= 1
	if remote_player_waiting == 0:
		emit_signal("show")

func player_disconnected(id):
	for player in Party._players:
		if player.nid == id:
			LobbyManager.remove_player(player.nid, player.local)
	
	for ps in player_selection.get_children():
		if ps._player and ps._player.nid == id:
			ps.reset()

# Ask the server to load the current state
master func load_state():
	var id = get_tree().get_rpc_sender_id()
	print("loading state for " + str(id))
	LobbyManager.update_slots_id(id)
	Party.update_players_id(id)

func _process(_delta):
	if current_state == State.WAITING:
		for i in range(3):
			var is_joy = i == 0 and (abs(Input.get_joy_axis(0,0)) > 0.5 or abs(Input.get_joy_axis(0,1)) > 0.5)
			if (Input.is_action_just_pressed("keyset_" + str(i)) or is_joy) and not i in keysets_taken:
					assign_slot(i)


func go():
	if current_state == State.COUNT_DOWN:
		current_state = State.GO
		var colors = range(Party._colors.size())
		for ps in player_selection.get_children():
			ps.set_process(false)
			if ps._player:
				var c = ps._player.color
				if c in colors:
					colors.erase(c)
	
		if is_network_master():
			for player in Party._players:
				if player.color == 4:
					player.color = colors[randi() % colors.size()]
					LobbyManager.rpc(
						"update_player",
						player.nid, player.local, 
						["color"], [player.color])
					colors.erase(player.color)
		
		var timer = Timer.new()
		timer.one_shot = true
		add_child(timer)
		timer.connect("timeout", Party, "_next")
		timer.start()

	
# TODO this will fail with perfect synchronized inputs
# Maybe ask first if the slot is used and reserve ir until the assing is done
func assign_slot(keyset: int):
	var id = get_tree().get_network_unique_id()
	
	# get available slot
	var slot = -1
	for i in range(4):
		var ps = player_selection.get_child(i)
		if not ps._player:
			slot = i
			break
	if slot == -1:
		return
		
	keysets_taken.append(keyset)
	for ps in player_selection.get_children():
		ps.set_available_keyset(keyset, false)
	
	
	# create a new player and fill the slot
	var player = Player.new()
	var index = 0
	if local_players.size() > 0:
		while index in local_players:
			index += 1
	local_players[index] = player
	var player_name = LobbyManager.player_name
	if index > 0:
		player_name += " ( %d )" % [index + 1]
	player.init(player_name, id, index, slot, keyset)
	Party._players.push_back(player)
	# Notify other players
	player_selection.get_child(slot).init(player)
	LobbyManager.rpc("add_player", player.get_data())

func on_player_added(player: Player):
	player_selection.get_child(player.slot).remote_init(player)

func on_player_removed(player: Player):
	colors_taken.erase(player.color)

func release_slot(player: Player):
	local_players.erase(player.local)
	keysets_taken.erase(player.keyset)
	for ps in player_selection.get_children():
		ps.set_available_keyset(player.keyset, true)
	LobbyManager.rpc("remove_player", player.nid, player.local)
	

func on_player_ready():
	var players = 0
	var players_ready = 0
	for i in range(4):
		var ps = player_selection.get_child(i)
		if ps._player:
			players += 1
			if ps.is_ready:
				players_ready += 1
	if players > 1 and players == players_ready:
		current_state = State.COUNT_DOWN
		playback.travel("count_down")
	else:
		current_state = State.WAITING
		playback.travel("waiting")
		
		

sync func check_start():
	
	var players = 0
	var start_game = true
	
	for player in Party._players:
		if player:
			players += 1
			if LobbyManager.slot_waiting(player.slot):
				start_game = false
	
	if players > 1 and start_game:
		$AnimationPlayer.play("count_down")
		current_state = State.COUNT_DOWN
	elif $AnimationPlayer.current_animation == "count_down":
			$AnimationPlayer.play("waiting")
			current_state = State.WAITING
