extends Node2D

func _enter_tree() -> void:
	LobbyManager.host_game("elixs")

func _ready() -> void:
	var player = Player.new()
	var player2 = Player.new()
	player.init("P1", 1, 0, 0, 1, 1)
	player2.init("P2", 1, 1, 1, 2, 0)
	$Rat.stopped = false
	$Rat2.stopped = false
	$Rat.init(player, 0, null)
	$Rat2.init(player2, 0, null)
