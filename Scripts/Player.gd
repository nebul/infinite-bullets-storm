extends CharacterBody2D
class_name Player

signal health_changed(new_health: int)
signal player_died
signal bombs_changed(count: int)

@export var speed: float = 250.0
@export var max_health: int = 100
@export var homing_missile_scene: PackedScene

const LAYER_PLAYER := 1
const LAYER_ENEMY := 2

# Ram hitbox (touching an enemy ship). Bullet collisions use the tiny point
# hit_radius below instead — that's the danmaku-fair grazing hitbox.
const HURTBOX_SIZE := Vector2(12, 12)
const RAPID_FIRE_INTERVAL := 0.05
const PLAYER_BULLET_SPEED := 620.0
const FOCUS_FACTOR := 0.45   # focus mode: precise, slow movement
const START_BOMBS := 3
const MAX_BOMBS := 5
const BOMB_DAMAGE := 40

var bombs: int = START_BOMBS

# Read by BulletManager for enemy-bullet collisions.
var hit_radius: float = 4.0
var hitbox_dot: ColorRect

var current_health: int = max_health:
	set(value):
		current_health = clampi(value, 0, max_health)
		health_changed.emit(current_health)
		if current_health <= 0:
			die()

var sprite: ColorRect
@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var bullet_spawn: Marker2D = $BulletSpawn
@onready var shoot_timer: Timer = $ShootTimer

var is_invincible: bool = false
var speed_multiplier: float = 1.0

# Timed buffs are driven by remaining-time counters so picking up a second
# copy refreshes the duration instead of an early timer cutting it short.
var spread_shot_active: bool = false
var rapid_fire_active: bool = false
var homing_missiles_active: bool = false
var spread_time_left: float = 0.0
var rapid_time_left: float = 0.0
var speed_time_left: float = 0.0
var homing_time_left: float = 0.0

var base_shoot_interval: float = 0.1
var bullet_damage_bonus: int = 0

var touch_target = null
var _touches: Dictionary = {}   # finger index -> screen position
var _move_finger: int = -1

func _ready() -> void:
	add_to_group("player")
	collision_layer = LAYER_PLAYER
	collision_mask = 0
	apply_upgrades()
	create_visual()
	setup_hurtbox()
	health_changed.emit(current_health)
	bombs_changed.emit(bombs)
	shoot_timer.timeout.connect(shoot)
	shoot_timer.wait_time = base_shoot_interval
	shoot_timer.start()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("bomb"):
		use_bomb()

# Danmaku bomb: wipe the enemy bullet field, nuke on-screen enemies, brief safety.
func use_bomb() -> void:
	if bombs <= 0 or current_health <= 0:
		return
	bombs -= 1
	bombs_changed.emit(bombs)
	BulletManager.clear_enemy_bullets()
	is_invincible = true
	if sprite:
		sprite.color.a = 0.5
	invincibility_timer.start()
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("take_damage"):
			e.take_damage(BOMB_DAMAGE)
	AudioManager.play("bomb")
	Input.vibrate_handheld(140)   # mobile haptics (no-op elsewhere)
	EventBus.bomb_detonated.emit()
	EventBus.screen_shake_requested.emit(10.0)

func add_bomb() -> void:
	bombs = mini(bombs + 1, MAX_BOMBS)
	bombs_changed.emit(bombs)

func apply_upgrades() -> void:
	max_health += SaveManager.get_health_bonus()
	current_health = max_health
	speed += SaveManager.get_speed_bonus()
	base_shoot_interval = maxf(0.03, 0.1 - SaveManager.get_firerate_bonus())
	bullet_damage_bonus = SaveManager.get_damage_bonus()

func create_visual() -> void:
	sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)
	sprite.color = Color.GREEN
	add_child(sprite)

	# Precise hitbox indicator, shown only while focusing.
	hitbox_dot = ColorRect.new()
	var d := hit_radius * 2.0
	hitbox_dot.size = Vector2(d, d)
	hitbox_dot.position = Vector2(-hit_radius, -hit_radius)
	hitbox_dot.color = Color(1, 1, 1, 0.9)
	hitbox_dot.z_index = 2
	hitbox_dot.visible = false
	add_child(hitbox_dot)

func setup_hurtbox() -> void:
	var hurtbox = Area2D.new()
	hurtbox.collision_layer = 0
	hurtbox.collision_mask = LAYER_ENEMY
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = HURTBOX_SIZE
	shape.shape = rect
	hurtbox.add_child(shape)
	add_child(hurtbox)
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)

func _on_hurtbox_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		take_damage(20)

# The first finger down steers the ship; a second finger anywhere = focus mode.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _move_finger == -1:
				_move_finger = event.index
				touch_target = _touch_point(event.position)
		else:
			_touches.erase(event.index)
			if event.index == _move_finger:
				_move_finger = -1
				touch_target = null
				for idx in _touches:   # hand steering to a still-held finger
					_move_finger = idx
					touch_target = _touch_point(_touches[idx])
					break
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if event.index == _move_finger:
			touch_target = _touch_point(event.position)

func _is_focusing() -> bool:
	return Input.is_action_pressed("focus") or _touches.size() >= 2

# keep the ship above the finger
func _touch_point(screen_pos: Vector2) -> Vector2:
	return screen_pos + Vector2(0, -40)

func _physics_process(delta: float) -> void:
	_update_buffs(delta)

	var focusing := _is_focusing()
	hitbox_dot.visible = focusing
	var move_speed := speed * speed_multiplier * (FOCUS_FACTOR if focusing else 1.0)

	if touch_target != null:
		var to_target = (touch_target as Vector2) - global_position
		if to_target.length() > 6.0:
			velocity = to_target.normalized() * move_speed
		else:
			velocity = Vector2.ZERO
	else:
		var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = input_vector * move_speed
	move_and_slide()

	var vr = get_viewport_rect().size
	position.x = clampf(position.x, 16.0, vr.x - 16.0)
	position.y = clampf(position.y, 16.0, vr.y - 16.0)

func _update_buffs(delta: float) -> void:
	if spread_shot_active:
		spread_time_left -= delta
		if spread_time_left <= 0.0:
			spread_shot_active = false
	if rapid_fire_active:
		rapid_time_left -= delta
		if rapid_time_left <= 0.0:
			rapid_fire_active = false
			shoot_timer.wait_time = base_shoot_interval
	if speed_multiplier > 1.0:
		speed_time_left -= delta
		if speed_time_left <= 0.0:
			speed_multiplier = 1.0
	if homing_missiles_active:
		homing_time_left -= delta
		if homing_time_left <= 0.0:
			homing_missiles_active = false

func take_damage(amount: int) -> void:
	if not is_invincible:
		current_health -= amount
		AudioManager.play("player_hit")
		Input.vibrate_handheld(60)   # mobile haptics (no-op elsewhere)
		is_invincible = true
		invincibility_timer.start()
		if sprite:
			sprite.color.a = 0.5
		EventBus.screen_shake_requested.emit(8.0)

func heal(amount: int) -> void:
	current_health += amount

func die() -> void:
	AudioManager.play("death")
	player_died.emit()
	queue_free()

func shoot() -> void:
	AudioManager.play("shoot")
	if homing_missiles_active:
		shoot_homing_missile()
	elif spread_shot_active:
		shoot_spread()
	else:
		shoot_normal()

func shoot_normal() -> void:
	_fire(bullet_spawn.global_position, Vector2.UP)

func shoot_spread() -> void:
	for i in range(-1, 2):
		_fire(bullet_spawn.global_position, Vector2.UP.rotated(deg_to_rad(i * 15)))

func _fire(pos: Vector2, dir: Vector2) -> void:
	BulletManager.spawn_player(pos, dir.angle(), PLAYER_BULLET_SPEED, 1 + bullet_damage_bonus)

func shoot_homing_missile() -> void:
	if homing_missile_scene:
		var missile = homing_missile_scene.instantiate()
		missile.global_position = bullet_spawn.global_position
		missile.set_target(get_closest_enemy())
		get_tree().current_scene.add_child(missile)

func get_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var closest_enemy = null
	var closest_distance = INF
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_enemy = enemy
			closest_distance = distance
	return closest_enemy

func activate_spread_shot(duration: float) -> void:
	spread_shot_active = true
	spread_time_left = maxf(spread_time_left, duration)

func activate_rapid_fire(duration: float) -> void:
	rapid_fire_active = true
	rapid_time_left = maxf(rapid_time_left, duration)
	shoot_timer.wait_time = RAPID_FIRE_INTERVAL

func activate_speed_up(duration: float) -> void:
	speed_multiplier = 1.5
	speed_time_left = maxf(speed_time_left, duration)

func activate_homing_missiles(duration: float) -> void:
	homing_missiles_active = true
	homing_time_left = maxf(homing_time_left, duration)

func _on_invincibility_timer_timeout() -> void:
	is_invincible = false
	if sprite:
		sprite.color.a = 1.0
