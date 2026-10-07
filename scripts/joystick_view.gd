extends Control
class_name MStickView

var active := false
var base := Vector2.ZERO
var knob := Vector2.ZERO

func _draw() -> void:
	if not active:
		return
	draw_circle(base, 96.0, Color(0, 1, 0.53, 0.07))
	draw_arc(base, 96.0, 0, TAU, 48, Color(0, 1, 0.53, 0.45), 4.0)
	draw_arc(base, 96.0, 0, TAU, 48, Color(1, 1, 1, 0.25), 1.5)
	draw_circle(knob, 40.0, Color(0, 1, 0.53, 0.35))
	draw_arc(knob, 40.0, 0, TAU, 32, Color(1, 1, 1, 0.75), 3.0)
	draw_circle(knob + Vector2(-10, -12), 9.0, Color(1, 1, 1, 0.35))
