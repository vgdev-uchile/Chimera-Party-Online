extends StaticBody2D

var vanishing = false

func bump():
	if not vanishing:
		rpc("sync_bump")

sync func sync_bump():
	vanishing = true
	$AnimationPlayer.play("vanish")
