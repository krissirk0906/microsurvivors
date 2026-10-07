extends CanvasLayer
class_name MHud

var main
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var timer_label: Label
var score_label: Label
var level_label: Label
var stick_view: MStickView
var title_screen: Control
var level_screen: Control
var over_screen: Control
var level_btns: Array = []
var over_stats: Label
var title_best: Label

var touch_id := -1
var touch_base := Vector2.ZERO
var touch_cur := Vector2.ZERO
var mouse_down := false

const StickScript := preload("res://scripts/joystick_view.gd")

func setup(m: Node2D) -> void:
	main = m
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build_top()
	_build_stick()
	_build_title()
	_build_level()
	_build_over()
	show_title()

func _build_top() -> void:
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 12
	top.add_theme_constant_override("separation", 6)
	add_child(top)
	hp_bar = ProgressBar.new()
	hp_bar.min_value = 0
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.custom_minimum_size = Vector2(0, 18)
	hp_bar.show_percentage = false
	top.add_child(hp_bar)
	xp_bar = ProgressBar.new()
	xp_bar.min_value = 0
	xp_bar.max_value = 6
	xp_bar.value = 0
	xp_bar.custom_minimum_size = Vector2(0, 10)
	xp_bar.show_percentage = false
	top.add_child(xp_bar)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	top.add_child(row)
	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 44)
	timer_label.add_theme_color_override("font_color", Color("#FFF8E7"))
	timer_label.text = "0:00"
	row.add_child(timer_label)
	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", Color("#FFD93D"))
	score_label.text = "0"
	row.add_child(score_label)
	level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 28)
	level_label.add_theme_color_override("font_color", Color("#00FF88"))
	level_label.text = "Lv 1"
	row.add_child(level_label)
	var pause := Button.new()
	pause.text = "II"
	pause.custom_minimum_size = Vector2(64, 48)
	pause.pressed.connect(func() -> void: main.toggle_pause())
	row.add_child(pause)

func _build_stick() -> void:
	stick_view = StickScript.new()
	stick_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	stick_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stick_view)

func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(560, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1A1929F2")
	sb.set_corner_radius_all(24)
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	sb.content_margin_top = 32
	sb.content_margin_bottom = 32
	p.add_theme_stylebox_override("panel", sb)
	return p

func _title_label(t: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _big_button(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(0, 88)
	b.add_theme_font_size_override("font_size", 32)
	return b

func _build_title() -> void:
	title_screen = Control.new()
	title_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(title_screen)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_screen.add_child(dim)
	var p := _panel()
	title_screen.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)
	v.add_child(_title_label("MICRO SURVIVORS", 52, Color("#FFD93D")))
	v.add_child(_title_label("Lunch Break", 32, Color("#FFF8E7")))
	v.add_child(_title_label("Drag anywhere to move. Weapons fire on their own. Survive 3:00.", 24, Color("#A8A5C4")))
	title_best = _title_label("", 24, Color("#00FF88"))
	v.add_child(title_best)
	var play := _big_button("PLAY")
	play.pressed.connect(func() -> void: main.start_run())
	v.add_child(play)

func _build_level() -> void:
	level_screen = Control.new()
	level_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_screen.visible = false
	add_child(level_screen)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_screen.add_child(dim)
	var p := _panel()
	level_screen.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(_title_label("LEVEL UP! Pick one:", 36, Color("#00FF88")))
	level_btns.clear()
	for i in 3:
		var b := _big_button("...")
		var idx := i
		b.pressed.connect(func() -> void: main.choose_upgrade(idx))
		v.add_child(b)
		level_btns.append(b)

func _build_over() -> void:
	over_screen = Control.new()
	over_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	over_screen.visible = false
	add_child(over_screen)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	over_screen.add_child(dim)
	var p := _panel()
	over_screen.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)
	v.add_child(_title_label("RUN OVER", 48, Color("#FF3CAC")))
	over_stats = _title_label("", 28, Color("#FFF8E7"))
	v.add_child(over_stats)
	var retry := _big_button("RETRY")
	retry.pressed.connect(func() -> void: main.start_run())
	v.add_child(retry)
	var menu := _big_button("MENU")
	menu.pressed.connect(func() -> void: main.to_title())
	v.add_child(menu)

func show_title() -> void:
	title_screen.visible = true
	level_screen.visible = false
	over_screen.visible = false
	var d: Dictionary = MSave.load_data()
	title_best.text = "Best: %d pts · %s" % [int(d["highscore"]), _fmt(float(d["best_time"]))]

func show_hud() -> void:
	title_screen.visible = false
	level_screen.visible = false
	over_screen.visible = false

func show_upgrades(choices: Array) -> void:
	level_screen.visible = true
	for i in 3:
		if i < choices.size():
			level_btns[i].text = choices[i]["name"]
			level_btns[i].visible = true
		else:
			level_btns[i].visible = false

func hide_upgrades() -> void:
	level_screen.visible = false

func show_gameover(win: bool, score: int, time: float, kills: int, level: int) -> void:
	over_screen.visible = true
	var head := over_screen.get_child(1).get_child(0).get_child(0) as Label
	head.text = "YOU SURVIVED!" if win else "RUN OVER"
	head.add_theme_color_override("font_color", Color("#00FF88") if win else Color("#FF3CAC"))
	over_stats.text = "Score %d · Time %s · %d kills · Lv %d" % [score, _fmt(time), kills, level]

func _fmt(t: float) -> String:
	var m := int(t) / 60
	var s := int(t) % 60
	return "%d:%02d" % [m, s]

func _process(_delta: float) -> void:
	if main == null or main.player == null:
		return
	var pl = main.player
	hp_bar.max_value = pl.max_hp
	hp_bar.value = pl.hp
	xp_bar.max_value = pl.xp_next
	xp_bar.value = pl.xp
	timer_label.text = _fmt(main.run_time)
	score_label.text = str(main.score)
	level_label.text = "Lv %d" % pl.level

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1 and not _on_ui(event.position):
			touch_id = event.index
			touch_base = event.position
			touch_cur = event.position
			_push_stick()
		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			_push_stick()
	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			touch_cur = event.position
			_push_stick()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _on_ui(event.position):
			mouse_down = true
			touch_base = event.position
			touch_cur = event.position
			_push_stick()
		else:
			mouse_down = false
			touch_id = -1
			if main != null and main.player != null:
				main.player.stick = Vector2.ZERO
			stick_view.active = false
			stick_view.queue_redraw()
	elif event is InputEventMouseMotion and mouse_down:
		touch_cur = event.position
		_push_stick()

func _on_ui(pos: Vector2) -> bool:
	if title_screen.visible or level_screen.visible or over_screen.visible:
		return true
	return pos.y < 190.0

func _push_stick() -> void:
	if touch_id == -1 and not mouse_down:
		return
	var d := touch_cur - touch_base
	if d.length() > 90.0:
		touch_base = touch_cur - d.normalized() * 90.0
		d = touch_cur - touch_base
	var v := d / 90.0
	if main != null and main.player != null:
		main.player.stick = v
	stick_view.active = true
	stick_view.base = touch_base
	stick_view.knob = touch_base + d
	stick_view.queue_redraw()
