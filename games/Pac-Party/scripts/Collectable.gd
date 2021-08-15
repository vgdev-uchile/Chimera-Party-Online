extends KinematicBody2D

func init(collectable_count, nid):
	set_network_master(nid)
	name = "dot %s" % collectable_count

func call_destruction():
	rpc("destroy")

remotesync func destroy():
	queue_free()
