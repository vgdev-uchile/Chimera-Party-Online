extends Object

class_name Player

var name
var nid # Network ID
var local # local number
var slot # Player number
var keyset
var color
var points

func init(name, nid, local, slot, keyset, color = 4, points = 0):
	self.name = name
	self.nid = nid
	self.local = local
	self.slot = slot
	self.keyset = keyset
	self.color = color
	self.points = points

func get_data():
	return [name, nid, local, slot, keyset, color, points]

func get_id():
	return {"nid": nid, "local": local}

func load_data(array):
	callv("init", array)

