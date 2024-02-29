extends Node

const SAVE_PATH := "user://progress.save"

var scrap: int = 0
var high_score: int = 0
var language: String = "english"
var master_volume: float = 1.0
var upgrade_levels: Dictionary = {
	"health": 0,
	"damage": 0,
	"firerate": 0,
	"speed": 0,
}

const UPGRADE_DEFS := {
	"health": {"name_key": "upg_health", "base_cost": 50, "max_level": 5},
	"damage": {"name_key": "upg_damage", "base_cost": 75, "max_level": 5},
	"firerate": {"name_key": "upg_firerate", "base_cost": 75, "max_level": 5},
	"speed": {"name_key": "upg_speed", "base_cost": 50, "max_level": 5},
}

const LEGACY_HIGHSCORE_PATH := "user://highscore.save"

func _ready() -> void:
	load_data()
	_migrate_legacy_highscore()

# High score used to live in its own file; fold it in once, then forget it.
func _migrate_legacy_highscore() -> void:
	if not FileAccess.file_exists(LEGACY_HIGHSCORE_PATH):
		return
	var f = FileAccess.open(LEGACY_HIGHSCORE_PATH, FileAccess.READ)
	if f:
		var legacy = f.get_32()
		f.close()
		if legacy > high_score:
			high_score = legacy
			save_data()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_HIGHSCORE_PATH))

func get_level(key: String) -> int:
	return int(upgrade_levels.get(key, 0))

func get_cost(key: String) -> int:
	return UPGRADE_DEFS[key]["base_cost"] * (get_level(key) + 1)

func is_maxed(key: String) -> bool:
	return get_level(key) >= UPGRADE_DEFS[key]["max_level"]

func can_buy(key: String) -> bool:
	return not is_maxed(key) and scrap >= get_cost(key)

func buy(key: String) -> bool:
	if not can_buy(key):
		return false
	scrap -= get_cost(key)
	upgrade_levels[key] = get_level(key) + 1
	save_data()
	return true

func add_scrap(amount: int) -> void:
	scrap += amount
	save_data()

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	save_data()

# Returns true if this became a new record.
func update_high_score(score: int) -> bool:
	if score > high_score:
		high_score = score
		save_data()
		return true
	return false

func get_health_bonus() -> int:
	return get_level("health") * 20

func get_damage_bonus() -> int:
	return get_level("damage")

func get_firerate_bonus() -> float:
	return get_level("firerate") * 0.01

func get_speed_bonus() -> float:
	return get_level("speed") * 25.0

func save_data() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		var data = {"scrap": scrap, "high_score": high_score, "upgrades": upgrade_levels, "language": language, "master_volume": master_volume}
		f.store_string(JSON.stringify(data))
		f.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var txt = f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		return
	scrap = int(data.get("scrap", 0))
	high_score = int(data.get("high_score", 0))
	language = data.get("language", "english")
	master_volume = clampf(float(data.get("master_volume", 1.0)), 0.0, 1.0)
	var ups = data.get("upgrades", {})
	for k in upgrade_levels.keys():
		upgrade_levels[k] = int(ups.get(k, 0))
