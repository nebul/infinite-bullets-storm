extends Area2D
class_name PowerUp

enum PowerUpType {
	SPREAD_SHOT,
	RAPID_FIRE,
	SPEED_UP,
	HEALTH,
	HOMING_MISSILES,
	BOMB
}

@export var power_type: PowerUpType = PowerUpType.SPREAD_SHOT
@export var duration: float = 5.0
@export var fall_speed: float = 100.0

var sprite: ColorRect

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	create_visual()

func create_visual() -> void:
	sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	add_child(sprite)
	
	match power_type:
		PowerUpType.SPREAD_SHOT:
			sprite.color = Color.BLUE
		PowerUpType.RAPID_FIRE:
			sprite.color = Color.ORANGE
		PowerUpType.SPEED_UP:
			sprite.color = Color.YELLOW
		PowerUpType.HEALTH:
			sprite.color = Color.GREEN
		PowerUpType.HOMING_MISSILES:
			sprite.color = Color.PURPLE
		PowerUpType.BOMB:
			sprite.color = Color.WHITE

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	
	var viewport_rect = get_viewport_rect()
	if position.y > viewport_rect.size.y + 50:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		AudioManager.play("powerup")
		apply_power_up(body)
		queue_free()

func apply_power_up(player) -> void:
	match power_type:
		PowerUpType.SPREAD_SHOT:
			player.activate_spread_shot(duration)
		PowerUpType.RAPID_FIRE:
			player.activate_rapid_fire(duration)
		PowerUpType.SPEED_UP:
			player.activate_speed_up(duration)
		PowerUpType.HEALTH:
			player.heal(25)
		PowerUpType.HOMING_MISSILES:
			player.activate_homing_missiles(duration)
		PowerUpType.BOMB:
			player.add_bomb()
