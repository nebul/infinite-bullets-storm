extends State

@onready var collision = %CollisionShape2D

var player_entered : bool = false:
	set(value):
		player_entered = value
		collision.set_deferred("disabled",value)

func transition():
	if player_entered:
		get_parent().change_state("5Leaf")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass # Replace with function body.*

func _on_player_detection_body_entered(body):
	player_entered = true
