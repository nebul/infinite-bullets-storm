extends CharacterBody2D
class_name Enemy

# Set from the EnemyTypeDef in apply_type(); not authored per-scene.
var health: int = 10
var score_value: int = 100

const ExplosionScene = preload("res://Scenes/Explosion.tscn")

var type_def: EnemyTypeDef
var wave: int = 1

var base_color: Color = Color.RED
var enemy_size: float = 24.0
var attack_speed: float = 50.0
var shoot_min: float = 1.0
var shoot_max: float = 3.0

var sprite: ColorRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var bullet_spawn: Marker2D = $BulletSpawn

var player
var states: Dictionary = {}
var current_state: State
var current_pattern
# Where this enemy settles after entering the arena.
var target_y: float = 120.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	apply_type()
	create_visual()
	collision_shape.scale = Vector2.ONE * (enemy_size / 24.0)
	shoot_timer.timeout.connect(shoot)
	shoot_timer.wait_time = randf_range(shoot_min, shoot_max)
	var players = get_tree().get_nodes_in_group("player")
	player = players[0] if players.size() > 0 else null
	target_y = randf_range(70.0, 220.0)
	build_states()

func apply_type() -> void:
	if type_def == null:
		type_def = EnemyTypes.default()
	base_color = type_def.color
	enemy_size = type_def.size
	attack_speed = type_def.attack_speed
	shoot_min = type_def.shoot_min
	shoot_max = type_def.shoot_max
	current_pattern = type_def.pick_pattern()
	# Scale with wave so deeper runs stay dangerous.
	health = int(round(type_def.health * (1.0 + (wave - 1) * 0.25)))
	score_value = type_def.score_value + (wave - 1) * 25

func create_visual() -> void:
	sprite = ColorRect.new()
	sprite.size = Vector2(enemy_size, enemy_size)
	sprite.position = Vector2(-enemy_size / 2.0, -enemy_size / 2.0)
	sprite.color = base_color
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.update(delta)
	move_and_slide()

	var vr = get_viewport_rect()
	if global_position.y > vr.size.y + 100 or global_position.y < -200 \
			or global_position.x < -200 or global_position.x > vr.size.x + 200:
		queue_free()

func take_damage(amount: int) -> void:
	health -= amount
	flash()
	if health <= 0:
		die()

func flash() -> void:
	if not sprite:
		return
	sprite.color = Color.WHITE
	var t = create_tween()
	t.tween_property(sprite, "color", base_color, 0.15)

func die() -> void:
	EventBus.enemy_killed.emit(score_value)
	BulletManager.cancel_enemy_bullets_near(global_position, 56.0)   # chain reward
	spawn_explosion()
	AudioManager.play("explosion")
	EventBus.screen_shake_requested.emit(5.0)
	queue_free()

func spawn_explosion() -> void:
	var explosion = ExplosionScene.instantiate()
	explosion.global_position = global_position
	explosion.color = Color(1, 0.4, 0.2)
	get_tree().current_scene.add_child(explosion)

# Collision radius used by the bullet engine for player-bullet hits.
func hurt_radius() -> float:
	return enemy_size * 0.5

# Mild per-wave speed-up; density (more emitters/patterns) does the heavy work.
func bullet_speed_scale() -> float:
	return minf(1.0 + (wave - 1) * 0.03, 1.6)

func shoot() -> void:
	if not bullet_spawn or not current_pattern:
		return
	var origin = bullet_spawn.global_position
	var target = origin + Vector2.DOWN * 200.0
	if is_instance_valid(player):
		target = player.global_position
	BulletManager.spawn_enemy_pattern(current_pattern.generate_bullets(origin, target), bullet_speed_scale())

func build_states() -> void:
	states = {
		"enter": EnterState.new(),
		"attack": AttackState.new(),
		"reposition": RepositionState.new(),
	}
	match type_def.behavior:
		"diver":
			states["dive"] = DiveState.new()
		"weaver":
			states["weave"] = WeaveState.new()
	for s in states.values():
		s.enemy = self
	change_state("enter")

# Which state the enemy loops back into after entering / repositioning.
func combat_state_name() -> String:
	match type_def.behavior:
		"diver":
			return "dive"
		"weaver":
			return "weave"
		_:
			return "attack"

func dive_speed() -> float:
	return attack_speed * 2.4

func change_state(state_name: String) -> void:
	if not states.has(state_name):
		return
	if current_state:
		current_state.exit()
	current_state = states[state_name]
	current_state.enter()

func start_shooting() -> void:
	shoot_timer.start()

func stop_shooting() -> void:
	shoot_timer.stop()

func get_player_position() -> Vector2:
	return player.global_position if player else Vector2.ZERO
