extends State
class_name DiveState

## Aggressive charge: lock onto the player's position and rush it. Used by
## "diver" enemies (the fast ones) as a melee/ram threat instead of shooting.
## They may charge off-screen and despawn — a one-shot kamikaze pass.

const DURATION := 1.4

var time_left: float = 0.0
var dir: Vector2 = Vector2.DOWN

func enter() -> void:
	enemy.stop_shooting()
	time_left = DURATION
	var target = enemy.get_player_position()
	dir = (target - enemy.global_position).normalized() if target != Vector2.ZERO else Vector2.DOWN

func update(delta: float) -> void:
	enemy.velocity = dir * enemy.dive_speed()
	time_left -= delta
	if time_left <= 0.0:
		enemy.change_state("reposition")
