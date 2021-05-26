extends Camera

var target = null


func _physics_process(_delta: float) -> void:
	if target:
		look_at(target.transform.origin,Vector3.UP)
