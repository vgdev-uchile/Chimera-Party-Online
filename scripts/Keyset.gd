extends Node2D

func set_available(index, value):
	if index == 0:
		return
	$AnimationTree.set("parameters/loop/conditions/available_" + str(index), value)

func set_keyset(keyset: int):
	$AnimationTree.active = false
	$key_a.position = Vector2(-27, 12)
	$key_b.position = Vector2(27, 12)
	$AnimationPlayer.play(str(keyset))

func clear_keyset():
	$AnimationTree.active = true
