extends Node2D
class_name MBullet

var main
var vel := Vector2.ZERO
var damage := 10.0
var pierce := 0
var life := 2.0
var radius := 8.0
var boomerang := false
var hit_set := {}

func setup(m: Node2D, p: Vector2, v: Vector2, d: float, pi: int, boom: bool) -> void:
	main = m
	position = p
	vel = v
	damage = d
	pierce = pi
	boomerang = boom
	if boom:
		radius = 11.0

func _process(delta: float) -> void:
	if main.state != main.State.RUNNING:
		return
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	position += vel * delta
	if absf(position.x) > 950.0 or absf(position.y) > 950.0:
		queue_free()
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get_instance_id() in hit_set:
			continue
		var rr = radius + e.radius
		if position.distance_squared_to(e.position) < rr * rr:
			hit_set[e.get_instance_id()] = true
			e.take_damage(damage)
			main.burst(position, Color("#FFD93D"), 4)
			if pierce <= 0:
				queue_free()
				return
			pierce -= 1
	queue_redraw()

func _draw() -> void:
	if boomerang:
		draw_circle(Vector2.ZERO, radius, Color("#00FF88"))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 16, Color("#0F0E17"), 2.5)
		draw_line(Vector2(-5, 0), Vector2(5, 0), Color("#0F0E17"), 3.0)
	else:
		draw_circle(Vector2.ZERO, radius, Color("#FFD93D"))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 16, Color("#0F0E17"), 2.5)
		draw_circle(Vector2.ZERO, 3.0, Color("#FFF8E7"))
