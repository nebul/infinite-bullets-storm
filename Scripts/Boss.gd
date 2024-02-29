extends CharacterBody2D
class_name Boss

signal boss_died
signal health_changed(current: int, maximum: int)
signal spell_card_changed(card_name: String)

const ExplosionScene = preload("res://Scenes/Explosion.tscn")

var def: BossDef
var max_health: int = 120
var health: int = 120
var wave: int = 5

var base_color: Color = Color(0.85, 0.1, 0.35)
var sprite: ColorRect
@onready var shoot_timer: Timer = $ShootTimer
@onready var bullet_spawn: Marker2D = $BulletSpawn

var player
var phase: int = 0

# Movement state (interpretation depends on def.movement).
var move_speed: float = 90.0
var move_target: Vector2 = Vector2.ZERO
var move_dir: int = 1
var swing: float = 0.0
var target_y: float = 110.0
var entered: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	if def == null:
		def = BossTypes.default()
	apply_def()
	create_visual()
	player = get_tree().get_nodes_in_group("player")[0] if get_tree().get_nodes_in_group("player").size() > 0 else null
	shoot_timer.timeout.connect(shoot)
	shoot_timer.wait_time = def.phase_shoot_times[0]
	health_changed.emit(health, max_health)

func apply_def() -> void:
	base_color = def.color
	move_speed = def.move_speed
	var boss_num = int(wave / 5)
	max_health = def.base_health + maxi(0, boss_num - 1) * 60   # tougher each appearance
	health = max_health

func create_visual() -> void:
	sprite = ColorRect.new()
	sprite.size = def.size
	sprite.position = -def.size / 2.0
	sprite.color = base_color
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if not entered:
		global_position.y += move_speed * delta
		if global_position.y >= target_y:
			global_position.y = target_y
			entered = true
			move_target = global_position
			shoot_timer.start()
			announce_spell_card()
		return
	_move(delta)
	update_phase()

# --- movement rules (selected by def.movement) ------------------------------

func _move(delta: float) -> void:
	match def.movement:
		"sweep":
			_move_sweep(delta)
		"pendulum":
			_move_pendulum(delta)
		_:
			_move_roam(delta)

# Wander to repicked waypoints; faster/lower/closer over the phases.
func _move_roam(delta: float) -> void:
	swing -= delta
	if swing <= 0.0:
		var vr := get_viewport_rect().size
		var p := phase / 2.0
		move_target = Vector2(randf_range(80.0, vr.x - 80.0), randf_range(70.0, lerpf(150.0, 240.0, p)))
		swing = lerpf(2.0, 0.85, p)
	var to_target := move_target - global_position
	var step := phase_speed() * delta
	if to_target.length() > step:
		global_position += to_target.normalized() * step
	else:
		global_position = move_target

# Bounce side to side, sinking a little each phase.
func _move_sweep(delta: float) -> void:
	var vr := get_viewport_rect().size
	global_position.x += move_dir * phase_speed() * delta
	if global_position.x < 80.0:
		global_position.x = 80.0
		move_dir = 1
	elif global_position.x > vr.x - 80.0:
		global_position.x = vr.x - 80.0
		move_dir = -1
	global_position.y = move_toward(global_position.y, lerpf(110.0, 190.0, phase / 2.0), 25.0 * delta)

# Smooth sinusoidal swing across the arena; quicker each phase.
func _move_pendulum(delta: float) -> void:
	swing += delta * (0.8 + phase * 0.4)
	var vr := get_viewport_rect().size
	var amp := vr.x * 0.5 - 90.0
	global_position.x = vr.x * 0.5 + sin(swing) * amp
	global_position.y = move_toward(global_position.y, lerpf(110.0, 165.0, phase / 2.0), 25.0 * delta)

func phase_speed() -> float:
	return move_speed * (1.0 + phase * 0.4)

# --- phases / attacks -------------------------------------------------------

func update_phase() -> void:
	var ratio = float(health) / float(max_health)
	var new_phase = 0
	if ratio < 0.34:
		new_phase = 2
	elif ratio < 0.67:
		new_phase = 1
	if new_phase != phase:
		phase = new_phase
		shoot_timer.wait_time = def.phase_shoot_times[phase]
		announce_spell_card()

func announce_spell_card() -> void:
	spell_card_changed.emit(Localization.t(def.spell_keys[phase]))
	AudioManager.play("phase")

func shoot() -> void:
	if not entered:
		return
	var origin = bullet_spawn.global_position
	var target = origin + Vector2.DOWN * 200.0
	if is_instance_valid(player):
		target = player.global_position
	var scale = minf(1.0 + int(wave / 5) * 0.05, 1.4)
	for p in def.phase_patterns[phase]:
		BulletManager.spawn_enemy_pattern(p.generate_bullets(origin, target), scale)

# --- damage / death ---------------------------------------------------------

func take_damage(amount: int) -> void:
	health -= amount
	flash()
	health_changed.emit(maxi(health, 0), max_health)
	if health <= 0:
		die()

func flash() -> void:
	if not sprite:
		return
	sprite.color = Color.WHITE
	var t = create_tween()
	t.tween_property(sprite, "color", base_color, 0.1)

func hurt_radius() -> float:
	return maxf(def.size.x, def.size.y) * 0.5

func die() -> void:
	boss_died.emit()
	EventBus.enemy_killed.emit(2000)
	BulletManager.cancel_enemy_bullets()   # screen-clear-to-points payoff
	spawn_explosions()
	AudioManager.play("boss")
	EventBus.screen_shake_requested.emit(12.0)
	queue_free()

func spawn_explosions() -> void:
	for i in range(6):
		var explosion = ExplosionScene.instantiate()
		explosion.global_position = global_position + Vector2(randf_range(-35, 35), randf_range(-25, 25))
		explosion.color = Color(1, 0.5, 0.1)
		get_tree().current_scene.add_child(explosion)
