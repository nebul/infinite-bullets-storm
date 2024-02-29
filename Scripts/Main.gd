extends Node2D

## Game-flow orchestrator: starts/restarts the run, handles pause and game over.
## The in-game HUD is owned by the UI node (HUD.gd); screen shake by the camera
## (ScreenShake.gd).

@onready var player = $Player
@onready var enemy_spawner = $EnemySpawner
@onready var game_manager = $GameManager
@onready var hud: HUD = $UI

@onready var game_over_panel: Panel = $UI/GameOverPanel
@onready var final_score_label: Label = $UI/GameOverPanel/FinalScoreLabel
@onready var restart_button: Button = $UI/GameOverPanel/RestartButton
@onready var menu_button: Button = $UI/GameOverPanel/MenuButton
@onready var scrap_label: Label = $UI/GameOverPanel/ScrapLabel
@onready var pause_panel: Panel = $UI/PausePanel
@onready var pause_label: Label = $UI/PausePanel/PauseLabel
@onready var resume_button: Button = $UI/PausePanel/ResumeButton
@onready var pause_menu_button: Button = $UI/PausePanel/PauseMenuButton

var is_game_over: bool = false

func _ready() -> void:
	game_over_panel.hide()
	pause_panel.hide()
	localize_ui()
	hud.bind(player, game_manager, enemy_spawner)
	setup_connections()
	start_game()

func localize_ui() -> void:
	pause_label.text = Localization.t("paused")
	resume_button.text = Localization.t("resume")
	pause_menu_button.text = Localization.t("menu")
	restart_button.text = Localization.t("restart")
	menu_button.text = Localization.t("menu")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not is_game_over:
		toggle_pause()

# Auto-pause when the window/app loses focus (alt-tab, phone call, etc.).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if not is_game_over and not get_tree().paused:
			get_tree().paused = true
			pause_panel.visible = true

func toggle_pause() -> void:
	var paused = not get_tree().paused
	get_tree().paused = paused
	pause_panel.visible = paused
	if paused:
		resume_button.grab_focus()   # gamepad-navigable pause menu

func setup_connections() -> void:
	player.player_died.connect(on_player_died)
	restart_button.pressed.connect(on_restart_button_pressed)
	menu_button.pressed.connect(on_menu_button_pressed)
	resume_button.pressed.connect(toggle_pause)
	pause_menu_button.pressed.connect(on_pause_menu_pressed)

func start_game() -> void:
	BulletManager.clear()
	game_manager.reset_game()
	enemy_spawner.start_wave()
	hud.reset(player)

func on_player_died() -> void:
	is_game_over = true
	enemy_spawner.stop()
	BulletManager.clear()
	game_over_panel.show()
	final_score_label.text = "%s: %d" % [Localization.t("final_score"), game_manager.current_score]
	var earned = game_manager.current_score / 10
	scrap_label.text = "%s: +%d" % [Localization.t("scrap"), earned]
	SaveManager.add_scrap(earned)
	restart_button.grab_focus()   # gamepad-navigable game-over menu

func on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

func on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func on_pause_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
