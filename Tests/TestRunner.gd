extends Node

## Headless unit tests for the game's pure logic. Run with:
##   Godot --headless res://Tests/test_runner.tscn
## Exits with code 1 if any assertion fails (0 on success), so CI/grep can gate.

var _total: int = 0
var _failures: int = 0

func _ready() -> void:
	test_enemy_types()
	test_enemy_selection()
	test_boss_types()
	test_patterns()
	test_game_manager_multiplier()
	test_bullet_manager()

	print("TESTS: %d/%d passed" % [_total - _failures, _total])
	if _failures > 0:
		print("RESULT: FAIL")
	else:
		print("RESULT: PASS")
	get_tree().quit(1 if _failures > 0 else 0)

func check(cond: bool, msg: String) -> void:
	_total += 1
	if not cond:
		_failures += 1
		print("  FAIL: ", msg)

# --- enemy roster -----------------------------------------------------------

func test_enemy_types() -> void:
	var roster := EnemyTypes.build()
	check(roster.size() == 5, "roster has 5 types")
	check(EnemyTypes.default().type_name == "grunt", "default is grunt")

	var behaviors := {}
	var sniper: EnemyTypeDef = null
	for d in roster:
		check(d.type_name != "", "type has a name")
		check(d.weight > 0.0, "%s has positive weight" % d.type_name)
		behaviors[d.behavior] = true
		if d.type_name == "sniper":
			sniper = d

	check(behaviors.has("diver"), "a diver type exists")
	check(behaviors.has("weaver"), "a weaver type exists")
	check(sniper != null and sniper.patterns.size() > 0, "sniper has a pattern")
	if sniper:
		check(sniper.patterns[0].accel > 0.0, "sniper bullets accelerate")

# --- bosses (data-driven, one-off enemies) ----------------------------------

func test_boss_types() -> void:
	var roster := BossTypes.build()
	check(roster.size() == 3, "three bosses in the roster")
	var movements := {}
	for b in roster:
		check(b.base_health > 0, "%s has health" % b.boss_name)
		check(b.phase_patterns.size() == 3, "%s has 3 phases" % b.boss_name)
		check(b.spell_keys.size() == 3, "%s has 3 spell names" % b.boss_name)
		for phase in b.phase_patterns:
			check(phase is Array and phase.size() > 0, "%s phase has patterns" % b.boss_name)
		movements[b.movement] = true
	check(movements.size() == 3, "bosses have distinct movement rules")
	# for_index cycles the roster (1-based).
	check(BossTypes.for_index(1).boss_name == roster[0].boss_name, "boss 1 -> first")
	check(BossTypes.for_index(4).boss_name == roster[0].boss_name, "boss 4 wraps to first")
	check(BossTypes.for_index(2).boss_name == roster[1].boss_name, "boss 2 -> second")

# --- enemy selection (pure weighted pick) -----------------------------------

func test_enemy_selection() -> void:
	var r := EnemyTypes.build()
	# Wave 1: only grunts are unlocked, whatever the roll.
	check(EnemyTypes.pick(r, 1, 0.0).type_name == "grunt", "wave1 low roll -> grunt")
	check(EnemyTypes.pick(r, 1, 0.99).type_name == "grunt", "wave1 high roll -> grunt")
	# Wave 2 unlocks fast.
	check(EnemyTypes.pick(r, 2, 0.9).type_name == "fast", "wave2 high roll -> fast")
	# Wave 3 unlocks tank + sniper (not weaver yet).
	check(EnemyTypes.pick(r, 3, 0.75).type_name == "tank", "wave3 mid roll -> tank")
	check(EnemyTypes.pick(r, 3, 0.99).type_name == "sniper", "wave3 high roll -> sniper")
	check(EnemyTypes.pick(r, 3, 0.7586).type_name != "weaver", "weaver locked before wave 4")
	# Wave 4 unlocks weaver.
	check(EnemyTypes.pick(r, 4, 0.7586).type_name == "weaver", "wave4 -> weaver reachable")

# --- bullet patterns --------------------------------------------------------

func test_patterns() -> void:
	var origin := Vector2(100, 100)
	var below := Vector2(100, 300)

	var circle := CirclePattern.new()
	circle.num_bullets = 8
	var cb := circle.generate_bullets(origin, below)
	check(cb.size() == 8, "circle emits num_bullets")
	check(cb[0].has("position") and cb[0].has("angle") and cb[0].has("speed"), "spec has required keys")

	var wall := WallPattern.new()
	wall.num_bullets = 11
	wall.gap_size = 2
	check(wall.generate_bullets(origin, below).size() == 9, "wall leaves a gap")

	var aimed := AimedPattern.new()
	var ab := aimed.generate_bullets(origin, below)
	check(absf(ab[ab.size() / 2].angle - PI / 2.0) < 0.2, "aimed points at target")

	var fan := FanPattern.new()
	fan.num_bullets = 7
	check(fan.generate_bullets(origin, below).size() == 7, "fan emits num_bullets")

	var spiral := SpiralPattern.new()
	spiral.generate_bullets(origin, below)
	check(spiral.current_angle > 0.0, "spiral advances its angle")

# --- scoring ----------------------------------------------------------------

func test_game_manager_multiplier() -> void:
	var gm := GameManager.new()   # not added to tree, so _ready/side-effects don't run
	var cases := {0: 1, 2: 1, 3: 2, 6: 2, 7: 3, 11: 3, 12: 4, 19: 4, 20: 5, 50: 5}
	for combo in cases:
		gm.combo = combo
		check(gm.get_multiplier() == cases[combo], "multiplier at combo %d == %d" % [combo, cases[combo]])

# --- bullet engine ----------------------------------------------------------

func test_bullet_manager() -> void:
	BulletManager.clear()
	check(BulletManager.enemy.count == 0, "clear empties enemy bullets")
	BulletManager.spawn_enemy(Vector2(50, 50), 0.0, 100.0)
	BulletManager.spawn_enemy(Vector2(60, 60), 1.0, 120.0)
	check(BulletManager.enemy.count == 2, "spawn_enemy adds bullets")
	BulletManager.spawn_player(Vector2(10, 10), -PI / 2.0, 600.0, 1)
	check(BulletManager.player.count == 1, "spawn_player adds a bullet")
	BulletManager.clear()
	check(BulletManager.enemy.count == 0 and BulletManager.player.count == 0, "clear empties both sets")

	BulletManager.spawn_enemy(Vector2(30, 30), 0.0, 100.0)
	BulletManager.spawn_enemy(Vector2(40, 40), 0.0, 100.0)
	check(BulletManager.cancel_enemy_bullets() == 2, "cancel returns the cleared count")
	check(BulletManager.enemy.count == 0, "cancel empties enemy bullets")

	BulletManager.spawn_enemy(Vector2(100, 100), 0.0, 50.0)
	BulletManager.spawn_enemy(Vector2(110, 100), 0.0, 50.0)
	BulletManager.spawn_enemy(Vector2(400, 400), 0.0, 50.0)
	check(BulletManager.cancel_enemy_bullets_near(Vector2(100, 100), 40.0) == 2, "cancel-near hits only bullets in radius")
	check(BulletManager.enemy.count == 1, "cancel-near leaves the far bullet")
	BulletManager.clear()

	var circle := CirclePattern.new()
	circle.num_bullets = 10
	BulletManager.spawn_enemy_pattern(circle.generate_bullets(Vector2(100, 100), Vector2.ZERO), 1.5)
	check(BulletManager.enemy.count == 10, "spawn_enemy_pattern emits every spec")
	BulletManager.clear()
