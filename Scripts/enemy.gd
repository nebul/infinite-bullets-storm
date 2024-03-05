extends CharacterBody2D

var theta: float = 0.0
@export_range(0,2*PI) var alpha: float = 0.0

@export var bullet_node: PackedScene
var bullet_type: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func shoot(angle):
	var bullet = bullet_node.instantiate()
	bullet.position = global_position
	angle += alpha
	bullet.direction = Vector2(cos(angle), sin(angle))
	bullet.set_property(bullet_type)
	
	get_tree().current_scene.call_deferred("add_child", bullet)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_speed_timeout(): # shoot timer
	shoot(theta)
