extends State

func enter():
	super.enter()
	owner.alpha = 1.5
	owner.bullet_type = 1

func transition():
	if can_transition:
		get_parent().change_state("3Leaf")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass # Replace with function body.*
