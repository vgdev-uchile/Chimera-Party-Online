extends "res://games/TestGame/Label.gd"

func _show():
	if is_network_master():
		rpc("rpcshow")
		$Timer.start()

signal TimeManager_continue_cycle
func _on_Timer_timeout():
	emit_signal("TimeManager_continue_cycle")
	pass
