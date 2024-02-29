extends RefCounted
class_name State

## Base enemy state. States are plain RefCounted objects owned by the enemy's
## FSM (Enemy.states) — they don't live in the scene tree. They drive the
## enemy by setting enemy.velocity and request transitions with
## enemy.change_state("name").

var enemy

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass
