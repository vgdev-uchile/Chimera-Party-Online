extends CanvasLayer

# to keep on loading until all is ready
signal show

var PlayerControl = preload("res://scenes/PlayerControl.tscn")
var Dino = preload("res://scenes/Dino.tscn")

enum InputButton {
	left = 1,
	right = 2,
	up = 4,
	down = 8
	a = 16,
	b = 32
}

onready var Players = $Panel/Preview/Players

#[{player, dino}]
var player_dinos = []

var modes_dict = {
	Party.GameType.FREE_FOR_ALL: GameModeFFA,
	Party.GameType.ONE_VS_THREE: GameMode1v3,
	Party.GameType.TWO_VS_TWO: GameMode2v2}

onready var id = get_tree().get_network_unique_id()

# Called when the node enters the scene tree for the first time.
func _ready():
	var game = Party._current_game
	var type = Party._game_type
	var config = load("res://games/" + game + "/config.tres") as Config
	var image = load("res://games/" + game + "/intro.png")
	
	var mode
	for m in config.modes:
		if m is modes_dict[type]:
			mode = m
			break
		
	
	$Panel/Preview.texture = image
	
	$DisplayName.text = mode.display_name
	$Description.text = mode.description
	
	if (mode is GameMode1v3 or mode is GameMode2v2) and mode.use_groups:
		$Controls/Group1.text = mode.solo_name if mode is GameMode1v3 else mode.team_a_name
		$Controls/Group2.text = mode.team_name if mode is GameMode1v3 else mode.team_b_name
		$Controls/Group1.visible = true
		$Controls/Group2.visible = true
	
	var group1_pointer = $Controls/Group1
	var group2_pointer = $Controls/Group2
	
	var node_pointer = group1_pointer
	
	var group2_index = mode.team_first_input if mode is GameMode1v3 else \
	 mode.team_b_first_input if mode is GameMode2v2 else 0
	
	for i in range(8):
		if i == group2_index:
			node_pointer = group2_pointer
		var input = mode.get("input_" + str(i))
		var player_control = PlayerControl.instance()
		player_control.description = mode.get("description_" + str(i))
		player_control.left = bool(input & InputButton.left)
		player_control.right = bool(input & InputButton.right)
		player_control.up = bool(input & InputButton.up)
		player_control.down = bool(input & InputButton.down)
		player_control.a = bool(input & InputButton.a)
		player_control.b = bool(input & InputButton.b)
		$Controls.add_child_below_node(node_pointer, player_control)
		node_pointer = player_control
		
	# groups
	if Party._teams.size() == 2:
		Players.get_node("VS").visible = true
		for i in range(2):
			for player in Party._teams[i]:
				var dino = Dino.instance()
				dino.dino_color = player.color
				Players.add_child(dino)
				player_dinos.append({"player": player, "dino": dino})
		Players.move_child(Players.get_node("VS"), Party._teams[0].size())
	else:
		for player in Party._players:
			var dino = Dino.instance()
			dino.dino_color = player.color
			Players.add_child(dino)
			player_dinos.append({"player": player, "dino": dino})
	
	$Timer.connect("timeout", self, "on_timeout")
	
	emit_signal("show")

func on_timeout():
	Party._next()
	
func _process(delta):
	for i in range(player_dinos.size()):
		var player_dino = player_dinos[i]
		var player: Player = player_dino.player
		if player.nid == id:
			var ks = str(player.keyset)
			if Input.is_action_just_pressed("action_a_" + ks):
					rpc("set_ok", i, !player_dino.dino.ok)

sync func set_ok(index, value):
	player_dinos[index].dino.ok = value
	for pd in player_dinos:
		if not pd.dino.ok:
			$Timer.stop()
			return
	$Timer.start()

