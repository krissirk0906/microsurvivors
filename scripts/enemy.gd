extends Node2D
class_name MEnemy

var main
var hp := 20.0
var max_hp := 20.0
var speed := 140.0
var damage := 10.0
var xp_value := 5
var radius := 18.0
var color := Color("#FF3CAC")
var is_boss := false
var touch_cd := 0.0
var flash := 0.0
var wob := 0.0

const ENEMY_TYPES := {
	"chimp": {"hp": 20.0, "speed": 122.0, "dmg": 8.0, "xp": 5, "r": 18.0, "c": "#FF3CAC"},
	"slime": {"hp": 45.0, "speed": 92.0, "dmg": 12.0, "xp": 12, "r": 24.0, "c": "#00FF88"},
	"boss": {"hp": 800.0, "speed": 110.0, "dmg": 25.0, "xp": 100, "r": 46.0, "c": "#B967FF"},
}

func setup(m: Node2D, type: String, p: Vector2, hp_scale: float) -> void:
	main = m
	position = p
	var s: Dictionary = ENEMY_TYPES[type]
	max_hp = s["hp"] * hp_scale
	hp = max_hp
	speed = s["speed"]
	damage = s["dmg"]
	xp_value = s["xp"]
	radius = s["r"]
	color = Color(s["c"])
	is_boss = type == "boss"
	if is_boss:
		speed *= 1.0
	add_to_group("enemies")

func _process(delta: float) -> void:
	if main == null or main.state != main.State.RUNNING:
		return
	if touch_cd > 0.0:
		touch_cd -= delta
	if flash > 0.0:
		flash -= delta
		queue_redraw()
	wob += delta * 6.0
	var pl = main.player
	if pl == null:
		return
	var to = pl.position - position
	var d = to.length()
	if d > 1.0:
		var sp := speed
		if is_boss and d < 300.0:
			sp *= 1.5  # charge when close
		position += to.normalized() * sp * delta
	if d < radius + 22.0 and touch_cd <= 0.0:
		pl.take_damage(damage)
		touch_cd = 0.8

func take_damage(amount: float) -> void:
	hp -= amount
	flash = 0.0 if main.reduce_motion else 0.08
	queue_redraw()
	if hp <= 0.0:
		die()

func die() -> void:
	main.on_enemy_killed(self)
	queue_free()

func _draw() -> void:
	var c := Color.WHITE if flash > 0.0 else color
	var bob := sin(wob) * 2.0
	draw_circle(Vector2(2, 4), radius, Color(0, 0, 0, 0.25))
	draw_circle(Vector2(0, bob), radius, c.darkened(0.25))
	draw_circle(Vector2(-radius * 0.18, -radius * 0.22 + bob), radius * 0.82, c)
	draw_arc(Vector2(0, bob), radius, 0, TAU, 24, Color("#0F0E17"), 3.0)
	# angry eyes
	var ex := radius * 0.35
	draw_circle(Vector2(-ex, -4 + bob), 3.5, Color("#0F0E17"))
	draw_circle(Vector2(ex, -4 + bob), 3.5, Color("#0F0E17"))
	draw_line(Vector2(-ex - 5, -11 + bob), Vector2(-ex + 4, -8 + bob), Color("#0F0E17"), 2.5)
	draw_line(Vector2(ex + 5, -11 + bob), Vector2(ex - 4, -8 + bob), Color("#0F0E17"), 2.5)
	if is_boss:
		draw_arc(Vector2(0, bob), radius + 6.0, 0, TAU, 32, Color("#FFD93D"), 3.0)
	# hp pips for tanky enemies
	if max_hp > 30.0:
		var f := clampf(hp / max_hp, 0.0, 1.0)
		draw_line(Vector2(-radius, -radius - 8), Vector2(-radius + radius * 2.0 * f, -radius - 8), Color("#00FF88"), 4.0)
