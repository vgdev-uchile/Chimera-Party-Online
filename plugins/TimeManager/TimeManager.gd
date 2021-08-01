extends Node

# TimeManager

## How does it work:



const continue_cycle_signal : String = "continue_cycle"
export(bool) var autostart = true # se iniciará en ready.
export(Array,String) var target_node_names : Array = ["TimeManager"]
export(Array,String) var target_methods    : Array = ["test"]
export(Array,float)  var wait_times        : Array = ["1.0"]
export(int,"TIMER_PROCESS_PHYSICS","TIMER_PROCESS_IDLE") var TimerProcessMode = 0

## main functionality #####################################################

func _ready() -> void:
	if !is_network_master():
		return
	
	startup_error_checking()
	setup()
	if autostart:
		cycle()

func continue_cycle() -> void:
	cycle()

var size        : int          # size of target arrays
var cycle_ended : bool = false # true after the cycle ends
var cycle_index : int  = 0     # number of the current cycle

# Main method, it is in charge of the cycle renewal: cleanup, cycle setup, method
# calls and countdown start.
func cycle() -> void:
	## only grant access to network master, and only if the cycle has not ended
	if !(is_network_master() and !cycle_ended):
		return
	
	## cleanup
	remove_incoming_continue_cycle_connection(last_external_incoming_connection_node)
	## and setting up
	timer_setup_at_step(cycle_index)
	
	## execute external target method
	var target_node   : Node   = get_target_node(target_node_names[cycle_index])
	var target_method : String = target_methods[cycle_index]
	target_node.call(target_method)
	
	## start the countdown until next cycle
	if wait_times[cycle_index] >= 0:
		# if wait time non negative, countdown will be executed through timer
		timer.start()
	else:
		# if not, countdown will be handled with the external node call.
		# In this case, the node is expected to emit
		# the signal "continue_cycle" / TimeManager.continue_cycle_signal
		# to end the countdown
		pass
	
	# change cycle to the next
	cycle_index +=1
	if cycle_index>=size:
		end()

###### INTERNAL SETUP ######################################################

onready var timer : Timer
# setup: This method is in charge of setting up variables
# and timer behaviour.
func setup() -> void:
	size            = target_node_names.size()
	timer           = Timer.new()
	timer.name      = "TimeManagerTimer"
	timer.one_shot  = true
	timer.autostart = autostart
	timer.connect("timeout",timer,"cycle")
	add_child(timer)

# timer_setup_at_step: This method changes timer setup as well as 
# connects the external node to the time manager via the "continue_cycle"
# signal. The signal will be later disconnected
func timer_setup_at_step(index : int) -> void:
	# error handling
	if index>=size:
		push_error("index cycle is greater than targets array size")
		return
	
	## Setup wait time
	# sets wait time to the targeted wait time, only if it is non negative.
	var wait_time = wait_times[index]
	if wait_time>=0:
		timer.wait_time = wait_times[index]
	
	## Setup incoming "continue_cycle" signal
	# gets target node/method information to connect the signal
	var target_node   : Node   = get_target_node(target_node_names[index])
	var target_method : String = target_methods[index]
	# connect an external node to continue cycle signal.
	var external_incoming_connection_result =(
		target_node.connect(continue_cycle_signal,self,"continue_cycle") )
	# saves the external incoming signal for disconnection later
	# (at cycle() -> cleanup).
	if external_incoming_connection_result==OK:
		last_external_incoming_connection_node = target_node

# get_target_node : finds a node in the node hierarchy, that is
# equal or descendant to the TimeManager parent.
func get_target_node(node_string: String) -> Node:
	if node_string=="" or node_string=="parent":
		return get_parent()
	else:
		return get_parent().find_node(node_string)

var last_external_incoming_connection_node : Node
func remove_incoming_continue_cycle_connection(from : Node):
	if from==null:
		# push_error("Target node no longer exists. Cannot disconnect signal")
		return
	var node = from
	if node.is_connected(continue_cycle_signal,timer,"continue_cycle"):
		node.disconnect(continue_cycle_signal,timer,"continue_cycle")
	else:
		push_error("Something happened, target node was not properly connected to time manager")

# checks for errors on startup. Example: target arrays of different size.
func startup_error_checking() -> void:
	if target_node_names.size()!=target_methods.size():
		push_error("target_node_names and target_methods array sizes mismatch")
	if wait_times.size()!=target_methods.size():
		push_error("wait_times and target_methods array sizes mismatch")
	if target_methods.size()!=wait_times.size():
		push_error("target_node_names and wait_times array sizes mismatch")
	if target_node_names.size()==0:
		push_error("target_node_names empty, this array should be at least size 1!")

func end():
	cycle_ended=true

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
