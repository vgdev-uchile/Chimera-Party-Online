extends KinematicBody2D

signal stomped(body)

func stomp(body: Node):
	emit_signal("stomped", body)
	
	
