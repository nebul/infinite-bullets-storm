extends Resource
class_name BulletPattern

## A pattern emits a burst of bullet specs each time it's fired. Stateful
## patterns (e.g. a spiral that advances its angle) keep state between calls, so
## firing the same pattern rapidly produces an evolving field.
##
## Each spec is a Dictionary:
##   position : Vector2   (required) world spawn point
##   angle    : float     (required) heading in radians
##   speed    : float     (required) px/s
##   accel    : float     (optional) px/s^2 along heading
##   avel     : float     (optional) heading turn rate rad/s (curving bullets)
##   radius   : float     (optional) collision radius

func generate_bullets(_origin: Vector2, _target: Vector2) -> Array[Dictionary]:
	return []
