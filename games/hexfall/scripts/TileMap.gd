extends TileMap

# YSort to contain the tiles
export(NodePath) var tiles

export(Dictionary) var index_to_node
onready var _tiles = get_node(tiles)

func _ready():
	for index in index_to_node:
		var Tile = load(index_to_node[index])
		var cells = get_used_cells_by_id(index)
		for i in range(cells.size()):
			var coord = cells[i]
			var tile: Node2D = Tile.instance()
			tile.global_position = map_to_world(coord) * scale
			tile.name = "Tile %d" % i
			_tiles.add_child(tile)
#	if is_network_master():
	_tiles.init()
	hide()
