extends State
class_name WeaveState

## Sweeps side to side in a sine wave while firing — a harder-to-predict shooter
## than the straight-strafing AttackState. Used by "weaver" enemies.

const DURATION := 4.0
const FREQ := 2.6      # oscillation speed
const AMP := 95.0      # horizontal swing speed

var t: float = 0.0

func enter() -> void:
	t = 0.0
	enemy.start_shooting()

func exit() -> void:
	enemy.stop_shooting()

func update(delta: float) -> void:
	t += delta
	enemy.velocity = Vector2(cos(t * FREQ) * AMP, 0.0)
	if t >= DURATION:
		enemy.change_state("reposition")
