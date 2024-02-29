extends State
class_name EnterState

## Descend from the spawn point (off-screen top) into the arena, then hand off
## to the enemy's combat state. Fixes enemies hovering off-screen on spawn.

const SPEED := 130.0

func enter() -> void:
	enemy.stop_shooting()

func update(_delta: float) -> void:
	enemy.velocity = Vector2.DOWN * SPEED
	if enemy.global_position.y >= enemy.target_y:
		enemy.change_state(enemy.combat_state_name())
