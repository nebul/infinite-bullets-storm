extends Node2D
class_name EnemySpawner

signal wave_changed(wave: int)
signal boss_spawned(boss)
signal boss_defeated

@export var enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var powerup_scene: PackedScene
@export var base_spawn_interval: float = 2.0
@export var base_enemies_per_wave: int = 5
@export var powerup_chance: float = 0.1
@export var between_wave_delay: float = 3.0

const BOSS_EVERY: int = 5

@onready var spawn_timer: Timer = $SpawnTimer

var current_wave: int = 0
var enemies_spawned: int = 0
var enemies_this_wave: int = 0
var viewport_rect: Rect2
var running: bool = true
var roster: Array[EnemyTypeDef] = []

func _ready() -> void:
	viewport_rect = get_viewport_rect()
	roster = EnemyTypes.build()
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func start_wave() -> void:
	if not running:
		return
	current_wave += 1
	enemies_spawned = 0
	wave_changed.emit(current_wave)

	if boss_scene and current_wave % BOSS_EVERY == 0:
		spawn_boss()
		return

	enemies_this_wave = base_enemies_per_wave + (current_wave - 1) * 2
	spawn_timer.wait_time = max(0.4, base_spawn_interval - (current_wave - 1) * 0.1)
	spawn_timer.start()

func spawn_boss() -> void:
	var boss = boss_scene.instantiate()
	boss.global_position = Vector2(viewport_rect.size.x / 2.0, -80)
	boss.wave = current_wave
	boss.def = BossTypes.for_index(current_wave / BOSS_EVERY)
	boss.boss_died.connect(_on_boss_died)
	# add to tree (runs _ready) before boss_spawned, so the HUD reads max_health
	get_tree().current_scene.add_child(boss)
	boss_spawned.emit(boss)

func _on_boss_died() -> void:
	if not running:
		return
	boss_defeated.emit()
	get_tree().create_timer(between_wave_delay).timeout.connect(start_wave)

func stop() -> void:
	running = false
	spawn_timer.stop()

func _on_spawn_timer_timeout() -> void:
	if not running:
		return
	spawn_enemy()
	enemies_spawned += 1

	if enemies_spawned >= enemies_this_wave:
		spawn_timer.stop()
		get_tree().create_timer(between_wave_delay).timeout.connect(start_wave)

func spawn_enemy() -> void:
	if not enemy_scene:
		return
	var enemy = enemy_scene.instantiate()

	var spawn_position = Vector2.ZERO
	spawn_position.x = randf_range(50, viewport_rect.size.x - 50)
	spawn_position.y = -50

	enemy.global_position = spawn_position
	enemy.add_to_group("enemy")
	enemy.wave = current_wave
	enemy.type_def = pick_enemy_def()

	get_tree().current_scene.add_child(enemy)

	if randf() < powerup_chance and powerup_scene:
		spawn_powerup(spawn_position)

func pick_enemy_def() -> EnemyTypeDef:
	return EnemyTypes.pick(roster, current_wave, randf())

func spawn_powerup(near_position: Vector2) -> void:
	if powerup_scene:
		var powerup = powerup_scene.instantiate()
		powerup.global_position = near_position + Vector2(randf_range(-50, 50), 0)
		powerup.power_type = randi() % PowerUp.PowerUpType.size()
		get_tree().current_scene.add_child(powerup)
