extends Node

const LANGUAGES := ["english", "french", "spanish"]

var translations: Dictionary = {}
var current_language: String = "english"

func _ready() -> void:
	load_language(SaveManager.language)

func load_language(lang: String) -> void:
	var path = "res://Localization/%s.json" % lang
	if not FileAccess.file_exists(path):
		return
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return
	var txt = f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	if typeof(data) == TYPE_DICTIONARY:
		translations = data
		current_language = lang

func set_language(lang: String) -> void:
	load_language(lang)
	SaveManager.language = lang
	SaveManager.save_data()

func cycle_language() -> void:
	var idx = LANGUAGES.find(current_language)
	idx = (idx + 1) % LANGUAGES.size()
	set_language(LANGUAGES[idx])

func t(key: String) -> String:
	return translations.get(key, key)
