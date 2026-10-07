extends Node2D
class_name MGem

var main
var value := 5
var age := 0.0
var pop_vel := Vector2.ZERO

func setup(m: Node2D, p: Vector2, v: int) -> void:
	main = m
	position = p
	value = v
	pop_vel = Vector2(randf_range(-120, 120), randf_range(-120, 120))

func _process(delta: float) -> void:
	if main.state != main.State.RUNNING:
		return
	age += delta
	if age < 0.4:
		position += pop_vel * delta
		pop_vel *= 0.9
		queue_redraw()
		return
	var pl = main.player
	if pl == null:
		return
	var d = position.distance_to(pl.position)
	if d < pl.magnet_radius:
		position = position.move_toward(pl.position, (220.0 + (pl.magnet_radius - d) * 4.0) * delta)
	if d < 26.0:
		pl.gain_xp(value)
		main.add_score(1)
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var bob := sin(age * 8.0) * 2.0
	var c := Color("#00FF88") if value < 20 else (Color("#FFD93D") if value < 60 else Color("#B967FF"))
	var s := 8.0 if value < 20 else 11.0
	var y := bob
	# diamond chip
	var pts := PackedVector2Array([Vector2(0, -s + y), Vector2(s * 0.7, y), Vector2(0, s + y), Vector2(-s * 0.7, y)])
	draw_colored_polygon(pts, c)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color("#0F0E17"), 2.0)
