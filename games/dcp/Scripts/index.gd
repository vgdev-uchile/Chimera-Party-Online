extends Spatial

func _ready():
	$delfin_con_patas2/Camera.current = false
	$delfin_con_patas2/Camera2.current = false
	$DCP/CamPivot/Camera.current = true


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		$delfin_con_patas2/Camera.current = false
		$delfin_con_patas2/Camera2.current = true
		$AudioStreamPlayer.play()
