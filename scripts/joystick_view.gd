extends Control
class_name MStickView

var active := false
var base := Vector2.ZERO
var knob := Vector2.ZERO

func _draw() -> void:
	if not active:
		return
	draw_circle(base, 90.0, Color(1, 1, 1, 0.10))
	draw_arc(base, 90.0, 0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	draw_circle(knob, 38.0, Color(1, 1, 1, 0.30))
	draw_arc(knob, 38.0, 0, TAU, 32, Color(1, 1, 1, 0.6), 3.0)
