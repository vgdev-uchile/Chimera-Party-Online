extends ColorRect

signal finished_fading

export var duration = 0.5

func _ready():
	$Tween.connect("tween_all_completed", self, "on_tween_completed")

# Show screen
func fade_in():
	
	$Tween.interpolate_property(self, "color:a", 1.0, 0.0, duration, Tween.TRANS_QUART, Tween.EASE_OUT)
	$Tween.start()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# Hide screen
func fade_out():
	$Tween.interpolate_property(self, "color:a", 0.0, 1.0, duration, Tween.TRANS_QUART, Tween.EASE_IN)
	$Tween.start()
	mouse_filter = Control.MOUSE_FILTER_STOP
	

func on_tween_completed():
	emit_signal("finished_fading")

	

