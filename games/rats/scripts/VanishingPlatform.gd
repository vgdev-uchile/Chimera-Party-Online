extends StaticBody2D

var vanishing = false

func bump():
	print("bump")
	rpc("sync_bump")

sync func sync_bump():
	if not vanishing:
		vanishing = true
		$AnimationPlayer.play("vanish")
