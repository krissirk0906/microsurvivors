extends Node2D
class_name MPlayer

signal died
signal leveled_up
signal changed

var main
var pos_arena := 900.0

var max_hp := 100.0
var hp := 100.0
var speed := 340.0
var level := 1
var xp := 0
var xp_next := 6
var magnet_radius := 90.0
var damage_mul := 1.0
var rate_mul := 1.0
var move_mul := 1.0

var stick := Vector2.ZERO
var iframes := 0.0
var blaster_t := 0.0
var fork_t := 0.0
var has_fork := false
var magnet_lv := 0
var dmg_lv := 0
var rate_lv := 0
var move_lv := 0
var hp_lv := 0
var flash := 0.0

const BLASTER_CD := 0.5
const FORK_CD := 1.1

func setup(m: Node2D) -> void:
	main = m
	position = Vector2.ZERO

func _process(delta: float) -> void:
	if main.state != main.State.RUNNING:
		return
	if iframes > 0.0:
		iframes -= delta
	if flash > 0.0:
		flash -= delta
		queue_redraw()
	var dir := stick
	if main.autotest:
		var threat := _nearest_enemy(420.0)
		if threat != null:
			var away := (position - threat.position).normalized()
			dir = (away + Vector2(-away.y, away.x) * 0.6).normalized()
		else:
			dir = Vector2.RIGHT.rotated(float(Time.get_ticks_msec()) / 900.0)
	var kb := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if kb.length() > 0.1:
		dir = kb.normalized()
	if dir.length() > 1.0:
		dir = dir.normalized()
	position += dir * speed * move_mul * delta
	position.x = clampf(position.x, -pos_arena, pos_arena)
	position.y = clampf(position.y, -pos_arena, pos_arena)
	blaster_t -= delta
	if blaster_t <= 0.0:
		_fire_blaster()
		blaster_t = BLASTER_CD * rate_mul
	if has_fork:
		fork_t -= delta
		if fork_t <= 0.0:
			_fire_fork()
			fork_t = FORK_CD * rate_mul
	changed.emit()

func _nearest_enemy(max_dist: float) -> Node2D:
	var best: Node2D = null
	var bd := max_dist
	for e in get_tree().get_nodes_in_group("enemies"):
		var d = position.distance_to(e.position)
		if d < bd:
			bd = d
			best = e
	return best

func _fire_blaster() -> void:
	var t := _nearest_enemy(700.0)
	if t == null:
		return
	var dir := (t.position - position).normalized()
	main.spawn_bullet(position + dir * 26.0, dir * 620.0, 14.0 * damage_mul, 0, false)
	main.sounds.shoot()

func _fire_fork() -> void:
	var t := _nearest_enemy(640.0)
	if t == null:
		return
	var base := (t.position - position).normalized()
	for a in [-0.18, 0.18]:
		main.spawn_bullet(position + base * 26.0, base.rotated(a) * 520.0, 8.0 * damage_mul, 2, true)
	main.sounds.shoot()

func take_damage(amount: float) -> void:
	if iframes > 0.0:
		return
	if main.state != main.State.RUNNING:
		return
	hp -= amount
	iframes = 0.6
	flash = 0.15
	main.sounds.hit()
	main.add_shake(4.0)
	changed.emit()
	queue_redraw()
	if hp <= 0.0:
		hp = 0.0
		died.emit()

func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)
	changed.emit()

func gain_xp(v: int) -> void:
	xp += v
	main.sounds.gem()
	while xp >= xp_next:
		xp -= xp_next
		level += 1
		xp_next = 5 + level * 4
		leveled_up.emit()
	changed.emit()

func apply_upgrade(id: String) -> void:
	match id:
		"dmg":
			damage_mul *= 1.2
			dmg_lv += 1
		"rate":
			rate_mul *= 0.85
			rate_lv += 1
		"move":
			move_mul *= 1.1
			move_lv += 1
		"magnet":
			magnet_radius *= 1.3
			magnet_lv += 1
		"hp":
			max_hp *= 1.2
			heal(max_hp * 0.3)
			hp_lv += 1
		"fork":
			has_fork = true
	changed.emit()

func upgrade_choices() -> Array:
	var pool: Array = []
	if dmg_lv < 5:
		pool.append({"id": "dmg", "name": "+20% Damage"})
	if rate_lv < 5:
		pool.append({"id": "rate", "name": "+15% Fire Rate"})
	if move_lv < 5:
		pool.append({"id": "move", "name": "+10% Speed"})
	if magnet_lv < 5:
		pool.append({"id": "magnet", "name": "+30% Magnet"})
	if hp_lv < 5:
		pool.append({"id": "hp", "name": "+20% Max HP & Heal"})
	if not has_fork:
		pool.append({"id": "fork", "name": "NEW: Fork Boomerang"})
	pool.shuffle()
	return pool.slice(0, 3)

func _draw() -> void:
	var body := Color("#FFD93D")
	if flash > 0.0:
		body = Color.WHITE
	# shadow
	draw_circle(Vector2(3, 5), 22.0, Color(0, 0, 0, 0.25))
	# body (lunchbox hero) with simple shading
	draw_circle(Vector2.ZERO, 22.0, body.darkened(0.2))
	draw_circle(Vector2(-3, -4), 18.0, body)
	draw_arc(Vector2.ZERO, 22.0, 0, TAU, 24, Color("#0F0E17"), 3.0)
	draw_circle(Vector2(-9, -10), 4.5, Color(1, 1, 1, 0.5))
	# face
	draw_circle(Vector2(-7, -3), 4.0, Color("#0F0E17"))
	draw_circle(Vector2(7, -3), 4.0, Color("#0F0E17"))
	var mouth_y := 7.0
	draw_line(Vector2(-6, mouth_y), Vector2(6, mouth_y), Color("#0F0E17"), 2.5)
	# direction tick
	if stick.length() > 0.1:
		draw_line(Vector2.ZERO, stick.normalized() * 30.0, Color("#00FF88"), 4.0)
	# iframe ring
	if iframes > 0.0:
		draw_arc(Vector2.ZERO, 27.0, 0, TAU, 24, Color(1, 1, 1, 0.5), 2.0)
