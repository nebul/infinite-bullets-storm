extends Area2D

var speed = 100
var direction = Vector2.RIGHT
var bullet_type: int = 0

#@export var texture_array : Array[Texture2D]

func set_property(type):
	bullet_type = type
#	$Sprite2D.texture = texture_array[type]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass # Replace with function body.

func _physics_process(delta):
	position += direction * delta *speed

func _on_body_entered(body):
	body.set_status(bullet_type)
	
func _on_screen_exited():
	queue_free()
