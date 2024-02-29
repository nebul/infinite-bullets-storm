extends Camera2D
class_name ScreenShake

## Self-contained screen shake. Lives on the gameplay Camera2D and listens to
## EventBus directly, so Main no longer needs to know about shaking.

const DECAY: float = 18.0
const MAX: float = 12.0

var strength: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE   # freeze while paused
	EventBus.screen_shake_requested.connect(add)

func add(amount: float) -> void:
	strength = minf(strength + amount, MAX)

func _process(delta: float) -> void:
	if strength > 0.0:
		strength = maxf(strength - DECAY * delta, 0.0)
		offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
	elif offset != Vector2.ZERO:
		offset = Vector2.ZERO
