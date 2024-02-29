extends State
class_name RepositionState

## Drift (without shooting) to a fresh spot in the upper arena, then return to
## the enemy's combat state. Keeps engagements from getting static.

const SPEED := 90.0
const TIMEOUT := 2.0
const ARRIVE_DIST := 12.0

var target: Vector2 = Vector2.ZERO
var time_left: float = 0.0

func enter() -> void:
	enemy.stop_shooting()
	var vr = enemy.get_viewport_rect().size
	target = Vector2(randf_range(60.0, vr.x - 60.0), randf_range(60.0, 220.0))
	time_left = TIMEOUT

func update(delta: float) -> void:
	var to_target = target - enemy.global_position
	time_left -= delta
	if to_target.length() < ARRIVE_DIST or time_left <= 0.0:
		enemy.change_state(enemy.combat_state_name())
		return
	enemy.velocity = to_target.normalized() * SPEED
