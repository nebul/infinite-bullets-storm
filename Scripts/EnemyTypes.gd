extends RefCounted
class_name EnemyTypes

## Factory for the enemy roster. Built once in code (could be authored as .tres
## later since EnemyTypeDef is a Resource). To add an enemy, append a def in
## build() and set its behavior / min_wave / weight — the spawner picks it up
## automatically.

static func build() -> Array[EnemyTypeDef]:
	return [_grunt(), _fast(), _tank(), _weaver(), _sniper()]

static func default() -> EnemyTypeDef:
	return _grunt()

# Pure, deterministic weighted pick among the types unlocked at `wave`.
# `roll` is a value in [0, 1) (pass randf() at the call site). Kept free of
# node/RNG dependencies so it can be unit-tested.
static func pick(roster: Array, wave: int, roll: float) -> EnemyTypeDef:
	var total := 0.0
	for d in roster:
		if wave >= d.min_wave:
			total += d.weight
	if total <= 0.0:
		return default()
	var r := roll * total
	for d in roster:
		if wave < d.min_wave:
			continue
		r -= d.weight
		if r <= 0.0:
			return d
	return default()

static func _grunt() -> EnemyTypeDef:
	var d := EnemyTypeDef.new()
	d.type_name = "grunt"
	d.color = Color.RED
	d.size = 24.0
	d.health = 10
	d.score_value = 100
	d.attack_speed = 50.0
	d.shoot_min = 0.3
	d.shoot_max = 0.5
	d.min_wave = 1
	d.weight = 1.0
	var circle := CirclePattern.new()
	circle.num_bullets = 14
	var spiral := SpiralPattern.new()
	spiral.arms = 3
	d.patterns = [circle, spiral, AimedPattern.new()]
	return d

static func _fast() -> EnemyTypeDef:
	var d := EnemyTypeDef.new()
	d.type_name = "fast"
	d.color = Color(1.0, 0.55, 0.1)
	d.size = 18.0
	d.health = 5
	d.score_value = 150
	d.attack_speed = 130.0
	d.shoot_min = 0.8
	d.shoot_max = 1.6
	d.behavior = "diver"
	d.min_wave = 2
	d.weight = 0.6
	d.patterns = []   # divers ram instead of shooting
	return d

static func _tank() -> EnemyTypeDef:
	var d := EnemyTypeDef.new()
	d.type_name = "tank"
	d.color = Color(0.6, 0.15, 0.6)
	d.size = 38.0
	d.health = 30
	d.score_value = 250
	d.attack_speed = 22.0
	d.shoot_min = 0.5
	d.shoot_max = 0.8
	d.min_wave = 3
	d.weight = 0.4
	var fan := FanPattern.new()
	fan.num_bullets = 9
	fan.spread_deg = 90.0
	d.patterns = [fan, WallPattern.new()]
	return d

static func _weaver() -> EnemyTypeDef:
	var d := EnemyTypeDef.new()
	d.type_name = "weaver"
	d.color = Color(0.2, 0.8, 0.5)
	d.size = 22.0
	d.health = 14
	d.score_value = 200
	d.attack_speed = 60.0
	d.shoot_min = 0.4
	d.shoot_max = 0.7
	d.behavior = "weaver"
	d.min_wave = 4
	d.weight = 0.5
	var fan := FanPattern.new()
	fan.num_bullets = 5
	fan.spread_deg = 50.0
	fan.curve = 0.9   # curving fan — hard to read, fits the weaver's erratic feel
	d.patterns = [fan, AimedPattern.new()]
	return d

static func _sniper() -> EnemyTypeDef:
	var d := EnemyTypeDef.new()
	d.type_name = "sniper"
	d.color = Color(0.95, 0.85, 0.2)
	d.size = 20.0
	d.health = 8
	d.score_value = 220
	d.attack_speed = 35.0
	d.shoot_min = 0.9
	d.shoot_max = 1.4
	d.min_wave = 3
	d.weight = 0.4
	# Tight, accelerating aimed bursts that punish standing still.
	var aimed := AimedPattern.new()
	aimed.num_bullets = 2
	aimed.spacing_deg = 4.0
	aimed.bullet_speed = 130.0
	aimed.accel = 220.0
	d.patterns = [aimed]
	return d
