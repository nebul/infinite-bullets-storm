extends RefCounted
class_name BossTypes

## Roster of unique bosses (the boss analogue of EnemyTypes). Each boss encounter
## cycles the roster; later encounters are tougher (Boss scales health by wave).
## To add a boss, append a def here.

static func build() -> Array[BossDef]:
	return [_sentinel(), _lancer(), _maelstrom()]

static func default() -> BossDef:
	return _sentinel()

# Pick the boss for the Nth boss encounter (1-based), cycling the roster.
static func for_index(n: int) -> BossDef:
	var roster := build()
	return roster[(maxi(1, n) - 1) % roster.size()]

# --- Boss 1: Sentinel — roams, rotating rings + aimed ----------------------
static func _sentinel() -> BossDef:
	var d := BossDef.new()
	d.boss_name = "sentinel"
	d.color = Color(0.85, 0.1, 0.35)
	d.size = Vector2(80, 60)
	d.base_health = 120
	d.movement = "roam"
	d.move_speed = 90.0
	d.spell_keys = ["b1_1", "b1_2", "b1_3"]
	d.phase_shoot_times = [0.8, 0.6, 0.4]

	var ring := CirclePattern.new()
	ring.num_bullets = 16
	ring.bullet_speed = 115.0
	ring.spin = 0.5

	var ring_cw := CirclePattern.new()
	ring_cw.num_bullets = 13
	ring_cw.bullet_speed = 110.0
	ring_cw.spin = 0.8
	var ring_ccw := CirclePattern.new()
	ring_ccw.num_bullets = 13
	ring_ccw.bullet_speed = 125.0
	ring_ccw.spin = -0.8
	var aim_mid := AimedPattern.new()
	aim_mid.num_bullets = 3
	aim_mid.bullet_speed = 180.0

	var spiral := SpiralPattern.new()
	spiral.arms = 6
	spiral.spin_step = 0.45
	spiral.bullet_speed = 120.0
	spiral.accel = 60.0
	var ring_final := CirclePattern.new()
	ring_final.num_bullets = 14
	ring_final.bullet_speed = 130.0
	ring_final.spin = -0.5
	var aim_wide := AimedPattern.new()
	aim_wide.num_bullets = 5
	aim_wide.spacing_deg = 9.0
	aim_wide.bullet_speed = 170.0

	d.phase_patterns = [[ring], [ring_cw, ring_ccw, aim_mid], [spiral, ring_final, aim_wide]]
	return d

# --- Boss 2: Lancer — sweeps side to side, fast aimed/fan barrages ----------
static func _lancer() -> BossDef:
	var d := BossDef.new()
	d.boss_name = "lancer"
	d.color = Color(0.95, 0.4, 0.1)
	d.size = Vector2(72, 72)
	d.base_health = 150
	d.movement = "sweep"
	d.move_speed = 120.0
	d.spell_keys = ["b2_1", "b2_2", "b2_3"]
	d.phase_shoot_times = [0.7, 0.5, 0.35]

	var fan0 := FanPattern.new()
	fan0.num_bullets = 11
	fan0.spread_deg = 100.0
	fan0.bullet_speed = 140.0

	var fan1 := FanPattern.new()
	fan1.num_bullets = 13
	fan1.spread_deg = 120.0
	fan1.bullet_speed = 150.0
	var aim1 := AimedPattern.new()
	aim1.num_bullets = 3
	aim1.bullet_speed = 170.0
	aim1.accel = 120.0

	var fan2 := FanPattern.new()
	fan2.num_bullets = 17
	fan2.spread_deg = 160.0
	fan2.bullet_speed = 150.0
	var aim2 := AimedPattern.new()
	aim2.num_bullets = 5
	aim2.spacing_deg = 7.0
	aim2.bullet_speed = 160.0
	aim2.accel = 220.0

	d.phase_patterns = [[fan0], [fan1, aim1], [fan2, aim2]]
	return d

# --- Boss 3: Maelstrom — swings like a pendulum, hypnotic spirals ----------
static func _maelstrom() -> BossDef:
	var d := BossDef.new()
	d.boss_name = "maelstrom"
	d.color = Color(0.45, 0.2, 0.8)
	d.size = Vector2(90, 54)
	d.base_health = 180
	d.movement = "pendulum"
	d.move_speed = 70.0
	d.spell_keys = ["b3_1", "b3_2", "b3_3"]
	d.phase_shoot_times = [0.5, 0.4, 0.3]

	var spiral0 := SpiralPattern.new()
	spiral0.arms = 3
	spiral0.spin_step = 0.3
	spiral0.bullet_speed = 120.0

	var spiral1 := SpiralPattern.new()
	spiral1.arms = 4
	spiral1.spin_step = 0.4
	spiral1.bullet_speed = 125.0
	var ring1 := CirclePattern.new()
	ring1.num_bullets = 12
	ring1.bullet_speed = 105.0
	ring1.spin = 0.6

	var spiral_cw := SpiralPattern.new()
	spiral_cw.arms = 5
	spiral_cw.spin_step = 0.42
	spiral_cw.bullet_speed = 120.0
	spiral_cw.accel = 50.0
	var spiral_ccw := SpiralPattern.new()
	spiral_ccw.arms = 5
	spiral_ccw.spin_step = -0.42
	spiral_ccw.bullet_speed = 120.0

	d.phase_patterns = [[spiral0], [spiral1, ring1], [spiral_cw, spiral_ccw]]
	return d
