extends Resource
class_name EnemyTypeDef

## Pure data describing one kind of enemy. Adding a new enemy means adding one
## of these (see EnemyTypes.build) instead of editing a match statement.

@export var type_name: String = "grunt"
@export var color: Color = Color.RED
@export var size: float = 24.0
@export var health: int = 10
@export var score_value: int = 100
@export var attack_speed: float = 50.0
@export var shoot_min: float = 1.0
@export var shoot_max: float = 3.0

# FSM behavior profile: "standard" (strafe+shoot), "diver" (charge), "weaver" (sine+shoot).
@export var behavior: String = "standard"

# Spawn selection: only eligible from this wave on, picked by relative weight.
@export var min_wave: int = 1
@export var weight: float = 1.0

# One is chosen (and duplicated) per spawned enemy. Stateful patterns like
# SpiralPattern need their own instance, hence the duplicate at spawn time.
@export var patterns: Array[BulletPattern] = []

func pick_pattern() -> BulletPattern:
	if patterns.is_empty():
		return null
	return patterns[randi() % patterns.size()].duplicate()
