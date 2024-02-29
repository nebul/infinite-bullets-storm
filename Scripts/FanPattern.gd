extends BulletPattern
class_name FanPattern

@export var num_bullets: int = 7
@export var spread_deg: float = 60.0
@export var bullet_speed: float = 140.0
@export var curve: float = 0.0   # rad/s; non-zero makes the fan sweep/curve

func generate_bullets(origin: Vector2, target: Vector2) -> Array[Dictionary]:
	var base_dir = (target - origin).normalized() if target != origin else Vector2.DOWN
	var base_angle = base_dir.angle()
	var bullets: Array[Dictionary] = []
	var spread = deg_to_rad(spread_deg)
	var step = spread / max(1, num_bullets - 1)
	var start = base_angle - spread / 2.0
	for i in range(num_bullets):
		bullets.append({
			"position": origin,
			"angle": start + step * i,
			"speed": bullet_speed,
			"avel": curve,
		})
	return bullets
