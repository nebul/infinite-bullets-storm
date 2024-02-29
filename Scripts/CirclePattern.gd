extends BulletPattern
class_name CirclePattern

@export var num_bullets: int = 16
@export var bullet_speed: float = 120.0
@export var spin: float = 0.0   # rad/s curve; non-zero makes a swirling ring

func generate_bullets(origin: Vector2, _target: Vector2) -> Array[Dictionary]:
	var bullets: Array[Dictionary] = []
	for i in range(num_bullets):
		var angle = TAU * i / num_bullets
		bullets.append({
			"position": origin,
			"angle": angle,
			"speed": bullet_speed,
			"avel": spin,
		})
	return bullets
