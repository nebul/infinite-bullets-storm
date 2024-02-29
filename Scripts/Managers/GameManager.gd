extends Node
class_name GameManager

signal score_changed(new_score: int)
signal combo_changed(combo: int, multiplier: int)

var current_score: int = 0:
	set(value):
		current_score = value
		score_changed.emit(current_score)

var combo: int = 0
var combo_timer: float = 0.0
const COMBO_TIMEOUT: float = 2.5

const GRAZE_SCORE := 15
const CANCEL_SCORE := 8
const GRAZE_SFX_COOLDOWN := 0.06   # throttle the graze tick (grazing fires fast)

var _graze_sfx_cd: float = 0.0

func _ready() -> void:
	add_to_group("game_manager")
	EventBus.enemy_killed.connect(register_kill)
	EventBus.bullet_grazed.connect(_on_graze)
	EventBus.bullets_canceled.connect(_on_bullets_canceled)

func _on_graze() -> void:
	add_score(GRAZE_SCORE)
	if _graze_sfx_cd <= 0.0:
		AudioManager.play("graze")
		_graze_sfx_cd = GRAZE_SFX_COOLDOWN

func _on_bullets_canceled(count: int) -> void:
	add_score(count * CANCEL_SCORE)

func _process(delta: float) -> void:
	if _graze_sfx_cd > 0.0:
		_graze_sfx_cd -= delta
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			reset_combo()

func register_kill(points: int) -> void:
	combo += 1
	combo_timer = COMBO_TIMEOUT
	var mult = get_multiplier()
	add_score(points * mult)
	combo_changed.emit(combo, mult)

func get_multiplier() -> int:
	if combo >= 20:
		return 5
	if combo >= 12:
		return 4
	if combo >= 7:
		return 3
	if combo >= 3:
		return 2
	return 1

func reset_combo() -> void:
	combo = 0
	combo_timer = 0.0
	combo_changed.emit(0, 1)

func add_score(points: int) -> void:
	current_score += points
	SaveManager.update_high_score(current_score)

func reset_game() -> void:
	current_score = 0
	reset_combo()
