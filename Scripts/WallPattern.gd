extends BulletPattern
class_name WallPattern

## A descending wall with a gap to weave through — the classic "find the hole"
## danmaku moment. The gap position shifts every emission.

@export var num_bullets: int = 11
@export var spacing: float = 34.0
@export var bullet_speed: float = 110.0
@export var gap_size: int = 2

func generate_bullets(origin: Vector2, _target: Vector2) -> Array[Dictionary]:
	var bullets: Array[Dictionary] = []
	var gap_start = randi() % max(1, num_bullets - gap_size)
	var start_x = -spacing * (num_bullets - 1) / 2.0
	for i in range(num_bullets):
		if i >= gap_start and i < gap_start + gap_size:
			continue
		bullets.append({
			"position": origin + Vector2(start_x + i * spacing, 0),
			"angle": PI / 2.0,   # straight down
			"speed": bullet_speed,
		})
	return bullets
