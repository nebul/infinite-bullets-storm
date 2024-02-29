extends State
class_name AttackState

## Hold station near the top, strafe horizontally (bouncing off the edges) and
## fire patterns. After a while, fall back to repositioning.

const DURATION := 3.5
const EDGE_MARGIN := 50.0

var time_left: float = 0.0
var dir: int = 1

func enter() -> void:
	time_left = DURATION
	# Strafe toward the larger open side first.
	var half = enemy.get_viewport_rect().size.x / 2.0
	dir = 1 if enemy.global_position.x < half else -1
	enemy.start_shooting()

func exit() -> void:
	enemy.stop_shooting()

func update(delta: float) -> void:
	var vr = enemy.get_viewport_rect().size
	if enemy.global_position.x < EDGE_MARGIN:
		dir = 1
	elif enemy.global_position.x > vr.x - EDGE_MARGIN:
		dir = -1
	enemy.velocity = Vector2(dir * enemy.attack_speed, 0.0)

	time_left -= delta
	if time_left <= 0.0:
		enemy.change_state("reposition")
