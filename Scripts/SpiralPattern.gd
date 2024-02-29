extends BulletPattern
class_name SpiralPattern

## Few arms, advanced a little each emission. Fired on a fast timer this draws a
## continuous rotating spiral across the screen.

@export var arms: int = 3
@export var bullet_speed: float = 135.0
@export var spin_step: float = 0.35   # radians advanced per emission
@export var accel: float = 0.0        # >0 = bullets speed up over their flight

var current_angle: float = 0.0

func generate_bullets(origin: Vector2, _target: Vector2) -> Array[Dictionary]:
	var bullets: Array[Dictionary] = []
	for i in range(arms):
		var angle = current_angle + TAU * i / arms
		bullets.append({
			"position": origin,
			"angle": angle,
			"speed": bullet_speed,
			"accel": accel,
		})
	current_angle += spin_step
	return bullets
