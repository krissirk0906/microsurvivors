extends Node
class_name MSpawner

var main
var t := 0.0
var spawn_t := 0.0
var boss_spawned := false

const MAX_ALIVE := 70

func setup(m: Node2D) -> void:
	main = m
	t = 0.0
	spawn_t = 0.5
	boss_spawned = false

func reset() -> void:
	t = 0.0
	spawn_t = 0.5
	boss_spawned = false

func interval() -> float:
	if t < 60.0:
		return 1.0
	if t < 120.0:
		return 0.5
	return 0.35

func slime_chance() -> float:
	if t < 45.0:
		return 0.0
	if t < 100.0:
		return 0.25
	return 0.4

func hp_scale() -> float:
	return 1.0 + t / 180.0 * 1.2

func _process(delta: float) -> void:
	if main.state != main.State.RUNNING:
		return
	t += delta
	spawn_t -= delta
	if t >= 180.0 and not boss_spawned:
		boss_spawned = true
		main.spawn_enemy("boss")
	if spawn_t <= 0.0:
		spawn_t = interval()
		var alive := get_tree().get_nodes_in_group("enemies").size()
		if alive < MAX_ALIVE:
			var type := "chimp"
			if randf() < slime_chance():
				type = "slime"
			main.spawn_enemy(type)
