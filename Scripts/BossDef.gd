extends Resource
class_name BossDef

## Data for one boss. A boss is a unique, one-off entity (the Boss class), with
## its own visuals, health, movement rule and per-phase attack patterns. Built
## in code by BossTypes (could be authored as .tres).

@export var boss_name: String = "boss"
@export var color: Color = Color(0.85, 0.1, 0.35)
@export var size: Vector2 = Vector2(80, 60)
@export var base_health: int = 120

# Movement rule, dispatched by Boss._move: "roam" | "sweep" | "pendulum".
@export var movement: String = "roam"
@export var move_speed: float = 90.0

# Localization keys for the spell-card banner, one per HP phase.
@export var spell_keys: Array[String] = []

# Shoot interval per phase (seconds).
@export var phase_shoot_times: Array = [0.8, 0.6, 0.4]

# phase_patterns[phase] = Array[BulletPattern] fired together that phase.
var phase_patterns: Array = []
