extends Node2D
class_name MMain

enum State { TITLE, RUNNING, LEVELUP, GAMEOVER }

var state: int = State.TITLE
var run_time := 0.0
var score := 0
var kills := 0
var pending_levels := 0
var current_choices: Array = []
var won := false

var player
var spawner
var hud
var sounds
var cam: Camera2D

var shake := 0.0
var bursts: Array = []
var best := {"highscore": 0, "best_time": 0.0}
var autotest := false
var test_paused_once := false
var test_resumed_once := false
var test_pause_t := 0
var shot_mode := ""
var shot_frame := 0
var shot_done := false
var shot_armed := false
var shot_level_t := 0
var shot_end_t := 0

func snap(tag: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var path := "/tmp/opencode/shot_%s.png" % tag
	img.save_png(path)
	print("SHOT_SAVED: ", path)
var haptics_on := true
var reduce_motion := false
var sounds_on := true

func apply_prefs() -> void:
	sounds.enabled = sounds_on
	haptics_on = sounds_on
	MSave.save_prefs(sounds_on, reduce_motion)
	hud.sync_toggles()

const WIN_TIME := 180.0
const ARENA := 900.0

func _ready() -> void:
	best = MSave.load_data()
	sounds_on = int(best.get("sound", 1)) == 1
	reduce_motion = int(best.get("motion", 0)) == 1
	autotest = OS.get_cmdline_user_args().has("autotest")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("shot="):
			shot_mode = a.get_slice("=", 1)
			autotest = true
	sounds = MSounds.new()
	add_child(sounds)
	sounds.enabled = sounds_on
	haptics_on = sounds_on
	cam = Camera2D.new()
	cam.enabled = true
	add_child(cam)
	spawner = MSpawner.new()
	spawner.setup(self)
	add_child(spawner)
	hud = MHud.new()
	hud.setup(self)
	add_child(hud)
	to_title()
	if shot_mode == "title":
		Engine.time_scale = 1.0
	elif shot_mode == "game":
		Engine.time_scale = 4.0
		start_run()
	elif shot_mode == "levelup":
		Engine.time_scale = 8.0
		start_run()
	elif shot_mode == "over":
		Engine.time_scale = 20.0
		start_run()
	elif autotest:
		Engine.time_scale = 20.0
		start_run()

func to_title() -> void:
	get_tree().paused = false
	state = State.TITLE
	_clear_field()
	hud.show_title()

func start_run() -> void:
	get_tree().paused = false
	_clear_field()
	run_time = 0.0
	score = 0
	kills = 0
	pending_levels = 0
	won = false
	shake = 0.0
	bursts.clear()
	player = MPlayer.new()
	player.setup(self)
	add_child(player)
	player.died.connect(_on_player_died)
	player.leveled_up.connect(_on_player_leveled)
	spawner.reset()
	state = State.RUNNING
	hud.show_hud()

func toggle_pause() -> void:
	if state != State.RUNNING:
		return
	if get_tree().paused:
		resume_game()
	else:
		get_tree().paused = true
		sounds.click()
		hud.show_pause()

func resume_game() -> void:
	get_tree().paused = false
	sounds.click()
	hud.hide_pause()

func _clear_field() -> void:
	for n in get_tree().get_nodes_in_group("enemies"):
		n.queue_free()
	for b in get_tree().get_nodes_in_group("bullets"):
		b.queue_free()
	for g in get_tree().get_nodes_in_group("gems"):
		g.queue_free()
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = null
	bursts.clear()

func _process(delta: float) -> void:
	if state == State.RUNNING:
		run_time += delta
		if autotest and shot_mode in ["", "pause"] and not get_tree().paused and not test_paused_once and run_time > 8.0:
			test_paused_once = true
			toggle_pause()
		if run_time >= WIN_TIME and not won:
			won = true
			_win()
	if player != null and is_instance_valid(player):
		cam.position = player.position
	if shake > 0.0:
		shake = maxf(0.0, shake - delta * 20.0)
		cam.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	else:
		cam.offset = Vector2.ZERO
	_update_bursts(delta)
	queue_redraw()

func _shot_tick() -> void:
	shot_frame += 1
	if shot_mode == "title":
		if shot_frame == 90 and not shot_done:
			shot_done = true
			snap("title")
			get_tree().quit()
	elif shot_mode == "game":
		if shot_frame == 60 and not shot_done:
			shot_done = true
			snap("game")

func _win() -> void:
	state = State.GAMEOVER
	_finish(true)

func _on_player_died() -> void:
	if state != State.RUNNING:
		return
	state = State.GAMEOVER
	buzz(150)
	burst(player.position, Color("#FF3CAC"), 26)
	_finish(false)

func _finish(win: bool) -> void:
	var sc := score + int(run_time) * 2 + kills * 5
	score = sc
	var old_hi := int(best["highscore"])
	var hi := old_hi
	var bt := float(best["best_time"])
	var is_best := sc > old_hi and old_hi > 0
	if sc > hi:
		hi = sc
	if run_time > bt:
		bt = run_time
	best = {"highscore": hi, "best_time": bt}
	MSave.save_data(hi, bt)
	var lv := 1
	if player != null and is_instance_valid(player):
		lv = player.level
	hud.show_gameover(win, sc, run_time, kills, lv, is_best)

func _on_player_leveled() -> void:
	pending_levels += 1
	if state == State.RUNNING:
		_open_levelup()

func _open_levelup() -> void:
	state = State.LEVELUP
	get_tree().paused = true
	buzz(60)
	sounds.level()
	current_choices = player.upgrade_choices()
	if current_choices.is_empty():
		get_tree().paused = false
		state = State.RUNNING
		return
	hud.show_upgrades(current_choices)
	if autotest:
		if shot_mode == "levelup" and not shot_done:
			shot_armed = true
			shot_level_t = 0
		else:
			call_deferred("choose_upgrade", 0)

func choose_upgrade(idx: int) -> void:
	if state != State.LEVELUP:
		return
	sounds.click()
	if idx < current_choices.size():
		player.apply_upgrade(current_choices[idx]["id"])
		burst(player.position, Color("#00FF88"), 12)
	pending_levels = maxi(0, pending_levels - 1)
	get_tree().paused = false
	hud.hide_upgrades()
	if pending_levels > 0:
		_open_levelup()
	else:
		state = State.RUNNING

func on_enemy_killed(e) -> void:
	kills += 1
	add_score(5)
	add_shake(2.0 if not e.is_boss else 10.0)
	burst(e.position, e.color, 10 if not e.is_boss else 30)
	spawn_gem(e.position, e.xp_value)
	if e.is_boss:
		add_score(200)

func add_score(v: int) -> void:
	score += v

func add_shake(v: float) -> void:
	if reduce_motion:
		return
	shake = minf(14.0, shake + v)

func buzz(ms: int) -> void:
	if haptics_on:
		Input.vibrate_handheld(ms)

func spawn_bullet(p: Vector2, v: Vector2, d: float, pierce: int, boom: bool) -> void:
	var b := MBullet.new()
	b.setup(self, p, v, d, pierce, boom)
	b.add_to_group("bullets")
	add_child(b)

func spawn_gem(p: Vector2, v: int) -> void:
	var g := MGem.new()
	g.setup(self, p, v)
	g.add_to_group("gems")
	add_child(g)

func spawn_enemy(type: String) -> void:
	var e := MEnemy.new()
	var p := _ring_pos()
	e.setup(self, type, p, spawner.hp_scale())
	add_child(e)

func _ring_pos() -> Vector2:
	var c := Vector2.ZERO
	if player != null and is_instance_valid(player):
		c = player.position
	var a := randf() * TAU
	var r := randf_range(480.0, 600.0)
	var p := c + Vector2(cos(a), sin(a)) * r
	p.x = clampf(p.x, -ARENA, ARENA)
	p.y = clampf(p.y, -ARENA, ARENA)
	return p

func burst(p: Vector2, c: Color, n: int) -> void:
	if reduce_motion:
		return
	for i in n:
		var a := randf() * TAU
		var sp := randf_range(80.0, 320.0)
		bursts.append({"p": p, "v": Vector2(cos(a), sin(a)) * sp, "life": randf_range(0.25, 0.55), "c": c})

func _update_bursts(delta: float) -> void:
	for i in range(bursts.size() - 1, -1, -1):
		var b: Dictionary = bursts[i]
		b["life"] = float(b["life"]) - delta
		if float(b["life"]) <= 0.0:
			bursts.remove_at(i)
			continue
		b["p"] = (b["p"] as Vector2) + (b["v"] as Vector2) * delta
		b["v"] = (b["v"] as Vector2) * 0.92
		bursts[i] = b

func _draw() -> void:
	# floor (outer span larger than any camera view so clear color never shows)
	draw_rect(Rect2(-4000, -4000, 8000, 8000), Color("#0B0A12"))
	draw_rect(Rect2(-ARENA - 40, -ARENA - 40, (ARENA + 40) * 2, (ARENA + 40) * 2), Color("#0B0A12"))
	draw_rect(Rect2(-ARENA, -ARENA, ARENA * 2, ARENA * 2), Color("#14121F"))
	var step := 120.0
	var x := -ARENA
	while x <= ARENA:
		draw_line(Vector2(x, -ARENA), Vector2(x, ARENA), Color(1, 1, 1, 0.05), 2.0)
		x += step
	var y := -ARENA
	while y <= ARENA:
		draw_line(Vector2(-ARENA, y), Vector2(ARENA, y), Color(1, 1, 1, 0.05), 2.0)
		y += step
	# arena edge glow
	draw_rect(Rect2(-ARENA, -ARENA, ARENA * 2, ARENA * 2), Color(1, 0.85, 0.24, 0.9), false, 6.0)
	draw_rect(Rect2(-ARENA - 10, -ARENA - 10, (ARENA + 10) * 2, (ARENA + 10) * 2), Color(1, 0.85, 0.24, 0.18), false, 10.0)
	for b in bursts:
		var bd: Dictionary = b
		draw_circle(bd["p"], 5.0 * clampf(float(bd["life"]) * 2.0, 0.2, 1.0), bd["c"])
