extends Node

# todo: documentar

const continue_cycle_signal : String = "continue_cycle"
export(bool) var autostart = true # se iniciará en ready.
export(Array,String) var target_node_names : Array = ["TimeManager"]
export(Array,String) var target_methods    : Array = ["test"]
export(Array,float)  var wait_times        : Array = ["1.0"]
export(int,"TIMER_PROCESS_PHYSICS","TIMER_PROCESS_IDLE") var TimerProcessMode = 0
var size = 0
var ended = false

func _ready() -> void:
	if !is_network_master():
		return
	error_checking()
	setup()
	if autostart:
		cycle()

var cycle_index : int = 0
func cycle() -> void:
	if !is_network_master() or ended:
		return
	remove_incoming_continue_cycle_connection(last_external_incoming_connection_node)
	timer_setup_at_step(cycle_index)
	if wait_times[cycle_index] >= 0:
		timer.start()
	else:
		# in this case the node is expected to emit
		# the signal "continue_cycle"/TimeManager.continue_cycle_signal
		pass
	cycle_index +=1
	if cycle_index>=size:
		end()

func end():
	ended=true

onready var timer : Timer
func setup() -> void:
	size = target_node_names.size()
	timer = Timer.new()
	timer.one_shot = true
	autostart = false
	add_child(timer)

func timer_setup_at_step(index : int) -> void:
	if index>=size:
		push_error("index cycle overflowed")
		return
	
	timer.wait_time = wait_times[index]
	var target_node : Node = get_target_node(target_node_names[index])
	var target_method : String = target_methods[index]
	
	disconnect_all()
	var external_outgoing_connection_result =(
		timer.connect("timeout",target_node,target_method) )
	var external_incoming_connection_result =(
		target_node.connect(continue_cycle_signal,self,"continue_cycle") )
	var internal_connection_result =(
		timer.connect("timeout",self,"cycle") )# ugly
	
	if external_incoming_connection_result==OK:
		last_external_incoming_connection_node = target_node

func get_target_node(node_string: String) -> Node:
	if node_string=="" or node_string=="parent":
		return get_parent()
	else:
		return get_parent().find_node(node_string)

var last_external_incoming_connection_node : Node
func remove_incoming_continue_cycle_connection(from : Node):
	if from==null:
		return
	var node = from
	if node.is_connected(continue_cycle_signal,timer,"continue_cycle"):
		node.disconnect(continue_cycle_signal,timer,"continue_cycle")
	else:
		push_error("Something happened, target node was not connected to time manager")

func disconnect_all() -> void:
	# disconnect everything going out from timer
	var connection_array : Array = timer.get_signal_connection_list("timeout")
	for connection in connection_array:
		var signal_name   : String = connection["signal"]
		var target_method : String = connection["method"]
		var target_object : Object = connection["target"]
		# timer.is_connected(...) debería devolver true 
		timer.disconnect(signal_name,target_object,target_method)

func error_checking() -> void:
	if target_node_names.size()!=target_methods.size():
		push_error("target_node_names and target_methods array sizes mismatch")
	if wait_times.size()!=target_methods.size():
		push_error("wait_times and target_methods array sizes mismatch")
	if target_methods.size()!=wait_times.size():
		push_error("target_node_names and wait_times array sizes mismatch")
	if target_node_names.size()==0:
		push_error("target_node_names empty, this array should be at least size 1!")

func continue_cycle() -> void:
	cycle()

func test():
	print("test method reached!")

#func _input(event):
#	if event is InputEventKey:
#		if event.pressed and event.scancode == KEY_1:
#			var connection_result = timer.connect("timeout",self,"test")
#			print("connected!")
#		if event.pressed and event.scancode == KEY_2:
#			var connection_array : Array = timer.get_signal_connection_list("timeout")
#			print(connection_array)
#		if event.pressed and event.scancode == KEY_3:
#			disconnect_previous()
