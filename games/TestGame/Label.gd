extends Label

export(String) var label_text = "HOLA"

func _ready():
	text = label_text

func _show():
	if is_network_master():
		rpc("rpcshow")

remotesync func rpcshow():
	set_visible(true)
