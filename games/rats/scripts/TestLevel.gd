extends Node2D

func _enter_tree() -> void:
	LobbyManager.host_game("elixs")

func _ready() -> void:
	$Rat.stopped = false
