extends Node2D

var current_state: State
var previous_state: State

func change_state(state):
	if state == previous_state.name :
		return
	current_state = find_child(state) as State
	current_state.enter()
	previous_state.exit()
	previous_state = current_state

# Called when the node enters the scene tree for the first time.
func _ready():
	current_state = get_child(0) as State
	previous_state = current_state
	current_state.enter()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass # Replace with function body.*
