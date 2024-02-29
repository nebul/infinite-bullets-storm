extends BulletPattern
class_name AimedPattern

## Tight burst aimed at the target (the player). Faster than area patterns so it
## actually threatens a moving player.

@export var num_bullets: int = 3
@export var spacing_deg: float = 6.0
@export var bullet_speed: float = 165.0
@export var accel: float = 0.0   # >0 = bullets speed up over their flight

func generate_bullets(origin: Vector2, target: Vector2) -> Array[Dictionary]:
	var base_angle = (target - origin).angle() if target != origin else PI / 2.0
	var bullets: Array[Dictionary] = []
	var step = deg_to_rad(spacing_deg)
	var start = base_angle - step * (num_bullets - 1) / 2.0
	for i in range(num_bullets):
		bullets.append({
			"position": origin,
			"angle": start + step * i,
			"speed": bullet_speed,
			"accel": accel,
		})
	return bullets
