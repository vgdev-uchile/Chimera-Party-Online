extends Node2D

export(NodePath) var lobby
onready var _lobby = get_node(lobby)

signal leave(slot)
signal player_ready()

signal remote_init_completed()

# Player that controls this Node
var _player : Player = null

# Used for navigation
var focused : PlayerButton = null

sync var is_ready = false setget set_is_ready
func set_is_ready(value):
	is_ready = value
	emit_signal("player_ready")
	if is_ready:
		$Remote/VBC/State.text = "Listo"
		$Remote/VBC/State.set("custom_colors/font_color", Color.green)
	else:
		$Remote/VBC/State.text = "Esperando"
		$Remote/VBC/State.set("custom_colors/font_color", Color.red)


func _ready():
	set_process(false)
	$Leave.connect("pressed", self, "on_Leave_pressed")
	$Color.connect("pressed", self, "on_Color_pressed")
	$Ok.connect("pressed", self, "on_Ok_pressed")
	$Ready.connect("pressed", self, "on_Ready_pressed")
	$ColorSelect.connect("selected", self, "on_ColorSelect_selected")
	$ColorSelect.init_current_option($ColorSelect.options.size() - 1)
	LobbyManager.connect("player_updated", self, "on_player_updated")

func on_player_updated(player):
	if player == _player:
		update_remote_color()

func set_available_keyset(index, value):
	$Panel/Keyset.set_available(index, value)

func init(player: Player):
	set_network_master(player.nid)
	set_process(true)
	_player = player
	$Panel/Keyset.set_keyset(player.keyset)
	$Color.focus(true)
	focused = $Color

sync func reset():
	$Panel/Keyset.clear_keyset()
	if focused:
		focused.focus(false)
	focused = null
	_player = null
	on_ColorSelect_selected($ColorSelect.options.size() - 1)
	$Remote.hide()
	set_is_ready(false)
	set_process(false)

	
func on_Leave_pressed():
	if is_ready:
		rset("is_ready", false)
		$Leave.toggle()
		$Leave.navigation = true
		focused = focused.go_previous()
	else:
		emit_signal("leave", _player)
		rpc("reset")

func on_Color_pressed():
	$Ready.hide()
	$Leave.hide()
	$ColorSelect.show()
	$Ok.show()
	$ColorSelect.focus(true)
	focused = $ColorSelect

func on_Ok_pressed():
	var color = $ColorSelect.current_option
	if _player.color == color or not (color in _lobby.colors_taken):
		if _player.color != color:
			_lobby.colors_taken.erase(_player.color)
			_lobby.colors_taken.push_back(color)
			_lobby.rset("colors_taken", _lobby.colors_taken)
			_player.color = color
			LobbyManager.rpc("update_player", _player.nid, _player.local, ["color"], [_player.color])
		$ColorSelect.hide()
		$Ok.hide()
		$Ready.show()
		$Leave.show()
		focused = $Color

func back():
	if focused == $ColorSelect or focused == $Ok:
		on_ColorSelect_selected(_player.color)
		$ColorSelect.hide()
		$Ok.hide()
		$Ready.show()
		$Leave.show()
		focused = $Color
	else:
		on_Leave_pressed()

func on_Ready_pressed():
	rset("is_ready", true)
	$Leave.toggle()
	$Leave.navigation = false
	focused = focused.go_next()

func on_ColorSelect_selected(option):
	rpc("on_ColorSelect_selected_sync", option)

sync func on_ColorSelect_selected_sync(option):
	for i in range($ColorSelect.options.size()):
		$Panel/Avatars.get_child(i).visible = i == option

func _process(_delta):
	if _player and focused:
		var ks = str(_player.keyset)
		if Input.is_action_just_pressed("move_down_"+ ks):
			focused = focused.go_next()
		if Input.is_action_just_pressed("move_up_"+ ks):
			focused = focused.go_previous()
		if Input.is_action_just_pressed("move_right_"+ ks):
			focused.choose_next()
		if Input.is_action_just_pressed("move_left_"+ ks):
			focused.choose_previous()
		if Input.is_action_just_pressed("action_a_"+ ks):
			focused.press()
		if Input.is_action_just_released("action_a_"+ ks):
			focused.release()
		if Input.is_action_just_pressed("action_b_"+ ks):
			back()

func remote_init(player):
	set_network_master(player.nid)
	_player = player
	$Panel/Keyset.set_keyset(player.keyset)
	$Remote.show()
	update_remote_color()
	$Remote/VBC/Name.text = player.name
	var id = get_tree().get_network_unique_id()
	rpc("request_data", id)

master func request_data(id):
	var option = 4
	for i in range($ColorSelect.options.size()):
		if $Panel/Avatars.get_child(i).visible:
			option = i
			break
	rpc_id(id, "update_data", is_ready, option, _lobby.colors_taken)

remote func update_data(r_is_ready, r_option, r_colors_taken):
	# Changing only if not already changed to solve possible data races
	if not is_ready:
		set_is_ready(r_is_ready)
	if $Panel/Avatars.get_child(4).visible:
		on_ColorSelect_selected_sync(r_option)
	if _lobby.colors_taken == []:
		_lobby.colors_taken = r_colors_taken
	emit_signal("remote_init_completed")

func update_remote_color():
	if _player.color < 4:
		$Remote/VBC/Color.text = Party._color_names[_player.color]
		$Remote/VBC/Color.set("custom_colors/font_color", Party._colors[_player.color])
	else:
		$Remote/VBC/Color.text = "Aleatorio"
		$Remote/VBC/Color.set("custom_colors/font_color", Color.black)
	on_ColorSelect_selected_sync(_player.color)
#func _process(delta):
#	if Input.is_action_just_pressed("test1"):
#		rpc("test")
#
#master func test():
#	var selfPeerID = get_tree().get_network_unique_id()
#	print("test meh " + str(selfPeerID))

