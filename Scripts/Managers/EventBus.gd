extends Node

## Global signal hub. Lets gameplay entities report things without knowing
## about the current scene's structure (no get_tree().current_scene probing,
## no group lookups for the GameManager).

# Emitted by enemies/bosses when they die. GameManager listens to award score.
signal enemy_killed(score_value: int)

# Emitted by anything that wants the camera to shake. Main listens.
signal screen_shake_requested(amount: float)

# Emitted by BulletManager when the player narrowly dodges an enemy bullet.
signal bullet_grazed

# Enemy bullets wiped into points (boss death / spell break). GameManager scores it.
signal bullets_canceled(count: int)

# Player set off a bomb. Main flashes the screen.
signal bomb_detonated
