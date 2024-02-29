extends Control

@onready var scrap_label: Label = $VBox/ScrapLabel
@onready var list: VBoxContainer = $VBox/List
@onready var back_button: Button = $VBox/BackButton

const ORDER := ["health", "damage", "firerate", "speed"]

var rows: Dictionary = {}

func _ready() -> void:
	back_button.text = Localization.t("back")
	back_button.pressed.connect(on_back)
	build_rows()
	refresh()
	back_button.grab_focus()   # so a gamepad can navigate the menu

func build_rows() -> void:
	for key in ORDER:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var name_label = Label.new()
		name_label.custom_minimum_size = Vector2(230, 0)
		var buy_button = Button.new()
		buy_button.custom_minimum_size = Vector2(150, 0)
		buy_button.pressed.connect(on_buy.bind(key))
		row.add_child(name_label)
		row.add_child(buy_button)
		list.add_child(row)
		rows[key] = {"name": name_label, "buy": buy_button}

func refresh() -> void:
	scrap_label.text = "%s: %d" % [Localization.t("scrap"), SaveManager.scrap]
	for key in ORDER:
		var def = SaveManager.UPGRADE_DEFS[key]
		var lvl = SaveManager.get_level(key)
		rows[key]["name"].text = "%s  [%s %d/%d]" % [Localization.t(def["name_key"]), Localization.t("level"), lvl, def["max_level"]]
		var btn = rows[key]["buy"]
		if SaveManager.is_maxed(key):
			btn.text = Localization.t("max")
			btn.disabled = true
		else:
			btn.text = "%s (%d)" % [Localization.t("buy"), SaveManager.get_cost(key)]
			btn.disabled = not SaveManager.can_buy(key)

func on_buy(key: String) -> void:
	if SaveManager.buy(key):
		refresh()

func on_back() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
