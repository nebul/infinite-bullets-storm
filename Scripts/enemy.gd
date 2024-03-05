extends CharacterBody2D

var theta: float = 0.0
@export_range(0,2*PI) var alpha: float = 0.0

@export var bullet_node: PackedScene
var bullet_type: int = 0

func get_vector(angle):
	theta = angle + alpha
	return Vector2(cos(theta), sin(theta))

func shoot(angle):
	var bullet = bullet_node.instantiate()
	bullet.position = global_position
	bullet.direction = get_vector(angle)
	bullet.set_property(bullet_type)
	get_tree().current_scene.call_deferred("add_child", bullet)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass # Replace with function body.*

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_speed_timeout(): # shoot timer
	shoot(theta)
