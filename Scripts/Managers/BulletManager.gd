extends Node2D

## Data-oriented danmaku bullet engine.
##
## Bullets are NOT nodes. They live in flat (Structure-of-Arrays) buffers and
## are advanced in one tight loop per frame, rendered with a single
## MultiMeshInstance2D per team (one draw call each), and collided manually:
##   - enemy bullets test only against the player's tiny point-hitbox
##   - player bullets test against the (few) enemies
## This is what lets thousands of bullets stay on screen at 60fps, which the
## old Area2D-node-per-bullet approach could never do.
##
## World space == screen space here (camera sits at the play-area center), so
## bullet positions are plain viewport coordinates.

const ENEMY_CAP := 8000
const PLAYER_CAP := 1500
const CULL_MARGIN := 48.0
const GRAZE_RADIUS := 18.0

# Fixed-capacity Structure-of-Arrays buffer with swap-remove compaction.
class BulletSet:
	var cap: int
	var count: int = 0
	var pos := PackedVector2Array()
	var ang := PackedFloat32Array()   # heading, radians
	var spd := PackedFloat32Array()   # px/s along heading
	var acc := PackedFloat32Array()   # px/s^2 along heading
	var avel := PackedFloat32Array()  # heading turn rate, rad/s (curving bullets)
	var rad := PackedFloat32Array()   # collision radius
	var dmg := PackedInt32Array()
	var grz := PackedByteArray()      # 1 once this bullet has been grazed

	func _init(capacity: int) -> void:
		cap = capacity
		pos.resize(cap); ang.resize(cap); spd.resize(cap); acc.resize(cap)
		avel.resize(cap); rad.resize(cap); dmg.resize(cap); grz.resize(cap)

	func spawn(p: Vector2, a: float, s: float, ac: float, av: float, r: float, d: int) -> void:
		if count >= cap:
			return
		var i := count
		pos[i] = p; ang[i] = a; spd[i] = s; acc[i] = ac
		avel[i] = av; rad[i] = r; dmg[i] = d; grz[i] = 0
		count += 1

	func remove_at(i: int) -> void:
		count -= 1
		pos[i] = pos[count]; ang[i] = ang[count]; spd[i] = spd[count]
		acc[i] = acc[count]; avel[i] = avel[count]; rad[i] = rad[count]
		dmg[i] = dmg[count]; grz[i] = grz[count]

	func clear() -> void:
		count = 0

var enemy: BulletSet
var player: BulletSet
var bounds: Vector2

var _enemy_mmi: MultiMeshInstance2D
var _player_mmi: MultiMeshInstance2D
var _player_node: Node2D = null

func _ready() -> void:
	enemy = BulletSet.new(ENEMY_CAP)
	player = BulletSet.new(PLAYER_CAP)
	bounds = get_viewport_rect().size
	_enemy_mmi = _make_layer(Vector2(9, 9), Color(1.0, 0.27, 0.45), ENEMY_CAP)
	_player_mmi = _make_layer(Vector2(15, 5), Color(0.45, 0.95, 1.0), PLAYER_CAP)

func _make_layer(quad_size: Vector2, color: Color, cap: int) -> MultiMeshInstance2D:
	var quad := QuadMesh.new()
	quad.size = quad_size
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.mesh = quad
	mm.instance_count = cap
	mm.visible_instance_count = 0
	var mmi := MultiMeshInstance2D.new()
	mmi.multimesh = mm
	mmi.modulate = color
	add_child(mmi)
	return mmi

# --- public spawn API -------------------------------------------------------

func spawn_enemy(p: Vector2, angle: float, speed: float, accel: float = 0.0, avel: float = 0.0, radius: float = 6.0, dmg: int = 1) -> void:
	enemy.spawn(p, angle, speed, accel, avel, radius, dmg)

func spawn_player(p: Vector2, angle: float, speed: float, dmg: int, radius: float = 5.0) -> void:
	player.spawn(p, angle, speed, 0.0, 0.0, radius, dmg)

# Emit a whole pattern (array of bullet-spec dicts). The spec format lives here,
# so emitters (Enemy, Boss, ...) don't each re-unpack the dictionary.
func spawn_enemy_pattern(specs: Array, speed_scale: float = 1.0, dmg: int = 1) -> void:
	for b in specs:
		enemy.spawn(b.position, b.angle, b.get("speed", 120.0) * speed_scale,
			b.get("accel", 0.0), b.get("avel", 0.0), b.get("radius", 6.0), dmg)

func clear() -> void:
	if enemy:
		enemy.clear()
	if player:
		player.clear()

# Wipe only enemy bullets, no reward — used by the player's bomb (defensive).
func clear_enemy_bullets() -> void:
	if enemy:
		enemy.clear()

# Wipe enemy bullets into points (boss death). Returns how many were canceled.
func cancel_enemy_bullets() -> int:
	var n := enemy.count if enemy else 0
	if enemy:
		enemy.clear()
	if n > 0:
		EventBus.bullets_canceled.emit(n)
	return n

# Cancel enemy bullets within `radius` of a point (a normal kill amid fire →
# satisfying chain). Returns how many were canceled.
func cancel_enemy_bullets_near(center: Vector2, radius: float) -> int:
	if enemy == null:
		return 0
	var r2 := radius * radius
	var n := 0
	var i := 0
	while i < enemy.count:
		if enemy.pos[i].distance_squared_to(center) <= r2:
			enemy.remove_at(i)
			n += 1
		else:
			i += 1
	if n > 0:
		EventBus.bullets_canceled.emit(n)
	return n

# --- frame step -------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_advance(enemy, delta)
	_advance(player, delta)
	_collide_enemy_bullets()
	_collide_player_bullets()
	_render(_enemy_mmi, enemy)
	_render(_player_mmi, player)

func _advance(s: BulletSet, delta: float) -> void:
	var max_x := bounds.x + CULL_MARGIN
	var max_y := bounds.y + CULL_MARGIN
	var i := 0
	while i < s.count:
		s.spd[i] += s.acc[i] * delta
		s.ang[i] += s.avel[i] * delta
		var np: Vector2 = s.pos[i] + Vector2(cos(s.ang[i]), sin(s.ang[i])) * s.spd[i] * delta
		if np.x < -CULL_MARGIN or np.x > max_x or np.y < -CULL_MARGIN or np.y > max_y:
			s.remove_at(i)
			continue
		s.pos[i] = np
		i += 1

func _collide_enemy_bullets() -> void:
	var p := _get_player()
	if p == null:
		return
	var pp: Vector2 = p.global_position
	var hit_r: float = p.hit_radius
	var i := 0
	while i < enemy.count:
		var d2 := enemy.pos[i].distance_squared_to(pp)
		var hit_sum := enemy.rad[i] + hit_r
		if d2 <= hit_sum * hit_sum:
			p.take_damage(enemy.dmg[i])
			enemy.remove_at(i)
			continue
		var graze_sum := enemy.rad[i] + GRAZE_RADIUS
		if enemy.grz[i] == 0 and d2 <= graze_sum * graze_sum:
			enemy.grz[i] = 1
			EventBus.bullet_grazed.emit()
		i += 1

func _collide_player_bullets() -> void:
	var targets := get_tree().get_nodes_in_group("enemy")
	if targets.is_empty():
		return
	var i := 0
	while i < player.count:
		var bp := player.pos[i]
		var hit := false
		for t in targets:
			if not is_instance_valid(t):
				continue
			var tr: float = (t.hurt_radius() if t.has_method("hurt_radius") else 16.0) + player.rad[i]
			if bp.distance_squared_to(t.global_position) <= tr * tr:
				if t.has_method("take_damage"):
					t.take_damage(player.dmg[i])
				hit = true
				break
		if hit:
			player.remove_at(i)
			continue
		i += 1

func _render(mmi: MultiMeshInstance2D, s: BulletSet) -> void:
	var mm := mmi.multimesh
	mm.visible_instance_count = s.count
	for i in range(s.count):
		mm.set_instance_transform_2d(i, Transform2D(s.ang[i], s.pos[i]))

func _get_player() -> Node2D:
	if _player_node and is_instance_valid(_player_node):
		return _player_node
	var ps := get_tree().get_nodes_in_group("player")
	_player_node = ps[0] if ps.size() > 0 else null
	return _player_node
