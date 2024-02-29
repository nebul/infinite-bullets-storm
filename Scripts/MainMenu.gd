extends Control

@onready var title_label: Label = $VBox/Title
@onready var high_score_label: Label = $VBox/HighScoreLabel
@onready var play_button: Button = $VBox/PlayButton
@onready var upgrades_button: Button = $VBox/UpgradesButton
@onready var quit_button: Button = $VBox/QuitButton
@onready var language_button: Button = $VBox/LanguageButton
@onready var volume_button: Button = $VBox/VolumeButton

const VOLUME_STEPS := [1.0, 0.75, 0.5, 0.25, 0.0]

func _ready() -> void:
	refresh_texts()
	play_button.pressed.connect(on_play)
	upgrades_button.pressed.connect(on_upgrades)
	quit_button.pressed.connect(on_quit)
	language_button.pressed.connect(on_language)
	volume_button.pressed.connect(on_volume)
	play_button.grab_focus()

func refresh_texts() -> void:
	title_label.text = Localization.t("game_title")
	high_score_label.text = "%s: %d" % [Localization.t("high_score"), SaveManager.high_score]
	play_button.text = Localization.t("play")
	upgrades_button.text = Localization.t("upgrades")
	quit_button.text = Localization.t("quit")
	language_button.text = "%s: %s" % [Localization.t("language"), Localization.current_language.capitalize()]
	volume_button.text = "%s: %d%%" % [Localization.t("volume"), roundi(SaveManager.master_volume * 100.0)]

func on_play() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func on_upgrades() -> void:
	get_tree().change_scene_to_file("res://Scenes/Upgrades.tscn")

func on_quit() -> void:
	get_tree().quit()

func on_language() -> void:
	Localization.cycle_language()
	refresh_texts()

func on_volume() -> void:
	# Advance to the next step at or below the current volume, wrapping around.
	var i := VOLUME_STEPS.find(snappedf(SaveManager.master_volume, 0.25))
	i = (i + 1) % VOLUME_STEPS.size() if i != -1 else 0
	AudioManager.set_master_volume(VOLUME_STEPS[i])
	refresh_texts()
