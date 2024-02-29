extends CanvasLayer
class_name HUD

## Owns the in-game heads-up display (labels, bars, flash). Subscribes to
## gameplay signals and renders them, so Main can stay a pure game-flow
## orchestrator. Pause / game-over panels are still owned by Main.

@onready var score_label: Label = $ScoreLabel
@onready var wave_label: Label = $WaveLabel
@onready var graze_label: Label = $GrazeLabel
@onready var combo_label: Label = $ComboLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var bomb_label: Label = $BombLabel
@onready var spell_card_label: Label = $SpellCardLabel
@onready var boss_health_bar: ProgressBar = $BossHealthBar
@onready var flash_overlay: ColorRect = $FlashOverlay
@onready var controls_hint: Label = $ControlsHint

var graze_count: int = 0
var _spell_tween: Tween
var _hint_tween: Tween

func _ready() -> void:
	combo_label.hide()
	boss_health_bar.hide()
	spell_card_label.modulate.a = 0.0
	controls_hint.modulate.a = 0.0
	EventBus.bullet_grazed.connect(on_graze)
	EventBus.bomb_detonated.connect(on_bomb_detonated)

# Connect to the gameplay nodes once they exist (called by Main).
func bind(player: Node, game_manager: Node, enemy_spawner: Node) -> void:
	player.health_changed.connect(update_health_bar)
	player.bombs_changed.connect(update_bomb_label)
	game_manager.score_changed.connect(update_score_label)
	game_manager.combo_changed.connect(update_combo_label)
	enemy_spawner.wave_changed.connect(update_wave_label)
	enemy_spawner.boss_spawned.connect(on_boss_spawned)
	enemy_spawner.boss_defeated.connect(on_boss_defeated)

# Push the starting values for a fresh run (initial signals fire before bind).
func reset(player: Node) -> void:
	update_health_bar(player.max_health)
	update_score_label(0)
	update_bomb_label(player.bombs)
	graze_count = 0
	update_graze_label()
	_show_controls_hint()

# Briefly teach focus + bomb (mechanics that aren't otherwise discoverable).
func _show_controls_hint() -> void:
	controls_hint.text = Localization.t("controls_hint")
	controls_hint.modulate.a = 1.0
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_interval(4.5)
	_hint_tween.tween_property(controls_hint, "modulate:a", 0.0, 1.5)

func on_graze() -> void:
	graze_count += 1
	update_graze_label()

func update_graze_label() -> void:
	graze_label.text = "%s: %d" % [Localization.t("graze"), graze_count]

func update_health_bar(new_health: int) -> void:
	health_bar.value = new_health

func update_score_label(new_score: int) -> void:
	score_label.text = "%s: %d" % [Localization.t("score"), new_score]

func update_wave_label(new_wave: int) -> void:
	if new_wave % 5 == 0:
		wave_label.text = "%s: %d - %s" % [Localization.t("wave"), new_wave, Localization.t("boss")]
	else:
		wave_label.text = "%s: %d" % [Localization.t("wave"), new_wave]

func update_bomb_label(count: int) -> void:
	bomb_label.text = "%s: %d" % [Localization.t("bombs"), count]

func update_combo_label(combo: int, multiplier: int) -> void:
	if multiplier > 1:
		combo_label.text = "%s x%d  (%d)" % [Localization.t("combo"), multiplier, combo]
		combo_label.show()
	else:
		combo_label.hide()

func on_boss_spawned(boss) -> void:
	boss_health_bar.max_value = boss.max_health
	boss_health_bar.value = boss.max_health
	boss_health_bar.show()
	boss.health_changed.connect(update_boss_health_bar)
	boss.spell_card_changed.connect(show_spell_card)

func update_boss_health_bar(current: int, maximum: int) -> void:
	boss_health_bar.max_value = maximum
	boss_health_bar.value = current

func on_boss_defeated() -> void:
	boss_health_bar.hide()
	if _spell_tween and _spell_tween.is_valid():
		_spell_tween.kill()
	spell_card_label.modulate.a = 0.0

# Flash the boss attack name, then fade it out.
func show_spell_card(card_name: String) -> void:
	spell_card_label.text = card_name
	spell_card_label.modulate.a = 1.0
	if _spell_tween and _spell_tween.is_valid():
		_spell_tween.kill()
	_spell_tween = create_tween()
	_spell_tween.tween_interval(1.8)
	_spell_tween.tween_property(spell_card_label, "modulate:a", 0.0, 1.0)

func on_bomb_detonated() -> void:
	flash_overlay.color.a = 0.55
	var t = create_tween()
	t.tween_property(flash_overlay, "color:a", 0.0, 0.35)
