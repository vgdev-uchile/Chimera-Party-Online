extends YSort

var delta_acc = 0
var timer = 2
var timer_master = 2
var tiles = []

func _ready():
	if get_tree().network_peer and not is_network_master():
		set_physics_process(false)

# this will be called before showing the screen
func init():
	tiles = range(get_child_count())

func _physics_process(delta):
	if tiles.size() > 0:
		delta_acc += delta
		if delta_acc >= timer:
			delta_acc = 0
			timer_master *= 0.97
			timer = randf() * timer_master
			var tile_index = randi() % tiles.size()
			var tile = get_child(tiles[tile_index])
			tiles.remove(tile_index)
			if get_tree().network_peer:
				tile.rpc("fall")
			else:
				tile.fall()

func stop_all():
	set_physics_process(false)
	for tile in get_children():
		tile.stop()
