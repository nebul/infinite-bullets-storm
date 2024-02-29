extends Area2D
class_name HomingMissile

@export var speed: float = 300.0
@export var turning_speed: float = 3.0
@export var damage: int = 5

var target: Node2D = null
var velocity: Vector2 = Vector2.ZERO

var sprite: ColorRect

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	create_visual()

func create_visual() -> void:
	sprite = ColorRect.new()
	sprite.size = Vector2(8, 16)
	sprite.position = Vector2(-4, -8)
	sprite.color = Color.YELLOW
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if target and is_instance_valid(target):
		var direction = global_position.direction_to(target.global_position)
		velocity = velocity.move_toward(direction * speed, turning_speed)
	else:
		velocity = velocity.move_toward(Vector2.UP * speed, turning_speed)
	
	global_position += velocity * delta
	rotation = velocity.angle()
	
	var viewport_rect = get_viewport_rect()
	if position.x < -50 or position.x > viewport_rect.size.x + 50 or position.y < -50 or position.y > viewport_rect.size.y + 50:
		queue_free()

func set_target(new_target: Node2D) -> void:
	target = new_target

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		body.take_damage(damage)
		queue_free()
