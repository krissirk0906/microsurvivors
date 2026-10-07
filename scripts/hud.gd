extends CanvasLayer
class_name MHud

const FONT_UI := preload("res://assets/fonts/Nunito-ExtraBold.ttf")
const FONT_DISPLAY := preload("res://assets/fonts/Orbitron-Black.ttf")

const C_BG := Color("#0F0E17")
const C_PANEL := Color("#1A1929")
const C_SURFACE := Color("#252336")
const C_TEXT := Color("#FFF8E7")
const C_DIM := Color("#A8A5C4")
const C_YELLOW := Color("#FFD93D")
const C_GREEN := Color("#00FF88")
const C_PINK := Color("#FF3CAC")
const C_PURPLE := Color("#B967FF")

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

func setup(m) -> void:
	main = m
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build_vignette()
	_build_top()
	_build_stick()
	_build_title()
	_build_level()
	_build_over()
	show_title()

# ---------- theme helpers ----------

func _font(l: Label, display: bool, size: int, color: Color) -> Label:
	l.add_theme_font_override("font", FONT_DISPLAY if display else FONT_UI)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 3)
	return l

func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(C_PANEL, 0.96)
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(2)
	sb.border_color = Color(1, 1, 1, 0.14)
	sb.content_margin_left = 40
	sb.content_margin_right = 40
	sb.content_margin_top = 36
	sb.content_margin_bottom = 36
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 18
	return sb

func _btn(b: Button, text: String, bg: Color, fg: Color) -> Button:
	b.text = text
	b.custom_minimum_size = Vector2(0, 92)
	b.add_theme_font_override("font", FONT_UI)
	b.add_theme_font_size_override("font_size", 32)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_corner_radius_all(20)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.12)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.15)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b

func _bar(bar: ProgressBar, fill: Color, h: float) -> void:
	bar.min_value = 0
	bar.value = 0
	bar.custom_minimum_size = Vector2(0, h)
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(int(h / 2.0))
	bg.set_border_width_all(2)
	bg.border_color = Color(1, 1, 1, 0.18)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(int(h / 2.0))
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)

func _title_label(t: String, size: int, color: Color, display := false) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return _font(l, display, size, color)

# ---------- layout ----------

func _build_vignette() -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0.0))
	grad.set_color(1, Color(0, 0, 0, 0.5))
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.42)
	gtex.fill_to = Vector2(1.0, 0.4)
	gtex.width = 512
	gtex.height = 512
	var rect := TextureRect.new()
	rect.texture = gtex
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)

func _build_top() -> void:
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_right = -20
	top.offset_top = 14
	top.add_theme_constant_override("separation", 8)
	add_child(top)
	hp_bar = ProgressBar.new()
	hp_bar.max_value = 100
	hp_bar.value = 100
	_bar(hp_bar, C_GREEN, 20.0)
	top.add_child(hp_bar)
	xp_bar = ProgressBar.new()
	xp_bar.max_value = 6
	_bar(xp_bar, C_YELLOW, 12.0)
	top.add_child(xp_bar)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	top.add_child(row)
	timer_label = _font(Label.new(), true, 52, C_TEXT)
	timer_label.text = "0:00"
	row.add_child(timer_label)
	score_label = _font(Label.new(), true, 30, C_YELLOW)
	score_label.text = "0"
	row.add_child(score_label)
	level_label = _font(Label.new(), true, 30, C_GREEN)
	level_label.text = "Lv 1"
	row.add_child(level_label)
	var pause := Button.new()
	pause.custom_minimum_size = Vector2(72, 56)
	_btn(pause, "II", C_SURFACE, C_TEXT)
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
	p.custom_minimum_size = Vector2(600, 0)
	p.add_theme_stylebox_override("panel", _panel_style())
	return p

func _dim(parent: Control, alpha: float) -> void:
	var dim := ColorRect.new()
	dim.color = Color(4.0 / 255.0, 3.0 / 255.0, 10.0 / 255.0, alpha)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(dim)

func _build_title() -> void:
	title_screen = Control.new()
	title_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(title_screen)
	_dim(title_screen, 0.62)
	var p := _panel()
	title_screen.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	var kick := _title_label("ONE-THUMB SURVIVOR", 22, C_PURPLE, true)
	v.add_child(kick)
	var logo := _title_label("MICRO\nSURVIVORS", 76, C_YELLOW, true)
	v.add_child(logo)
	v.add_child(_title_label("Lunch Break", 34, C_TEXT))
	v.add_child(_title_label("Drag anywhere to move. Weapons fire on their own. Survive 3:00.", 24, C_DIM))
	title_best = _title_label("", 26, C_GREEN)
	v.add_child(title_best)
	var play := Button.new()
	_btn(play, "PLAY", C_GREEN, C_BG)
	play.pressed.connect(func() -> void: main.start_run())
	v.add_child(play)
	v.add_child(_title_label("v0.2 · best on device · no ads", 20, C_DIM))

func _build_level() -> void:
	level_screen = Control.new()
	level_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_screen.visible = false
	add_child(level_screen)
	_dim(level_screen, 0.6)
	var p := _panel()
	level_screen.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	v.add_child(_title_label("LEVEL UP!", 52, C_GREEN, true))
	v.add_child(_title_label("Pick one upgrade", 24, C_DIM))
	level_btns.clear()
	for i in 3:
		var b := Button.new()
		_btn(b, "...", C_SURFACE, C_YELLOW)
		var idx := i
		b.pressed.connect(func() -> void: main.choose_upgrade(idx))
		v.add_child(b)
		level_btns.append(b)

func _build_over() -> void:
	over_screen = Control.new()
	over_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	over_screen.visible = false
	add_child(over_screen)
	_dim(over_screen, 0.65)
	var p := _panel()
	over_screen.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	p.add_child(v)
	v.add_child(_title_label("RUN OVER", 60, C_PINK, true))
	over_stats = _title_label("", 28, C_TEXT)
	v.add_child(over_stats)
	var retry := Button.new()
	_btn(retry, "RETRY", C_GREEN, C_BG)
	retry.pressed.connect(func() -> void: main.start_run())
	v.add_child(retry)
	var menu := Button.new()
	_btn(menu, "MENU", C_SURFACE, C_TEXT)
	menu.pressed.connect(func() -> void: main.to_title())
	v.add_child(menu)

# ---------- state ----------

func show_title() -> void:
	title_screen.visible = true
	level_screen.visible = false
	over_screen.visible = false
	var d: Dictionary = MSave.load_data()
	title_best.text = "BEST  %d pts   ·   %s" % [int(d["highscore"]), _fmt(float(d["best_time"]))]

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
	_font(head, true, 60, C_GREEN if win else C_PINK)
	over_stats.text = "Score  %d\nTime  %s\nKills  %d   ·   Level %d" % [score, _fmt(time), kills, level]

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

# ---------- touch input ----------

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
	return pos.y < 210.0

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
