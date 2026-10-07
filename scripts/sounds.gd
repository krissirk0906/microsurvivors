extends Node
class_name MSounds

var p_shoot: AudioStreamPlayer
var p_hit: AudioStreamPlayer
var p_gem: AudioStreamPlayer
var p_level: AudioStreamPlayer
var p_click: AudioStreamPlayer
var enabled := true

func _ready() -> void:
	p_shoot = _mk(740.0, 0.05, 0.25)
	p_hit = _mk(180.0, 0.09, 0.4)
	p_gem = _mk(1180.0, 0.04, 0.2)
	p_level = _mk(660.0, 0.16, 0.35)
	p_click = _mk(520.0, 0.035, 0.22)

func _mk(freq: float, dur: float, vol: float) -> AudioStreamPlayer:
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n)
	for i in n:
		var t := float(i) / rate
		var env := 1.0 - float(i) / n
		var s := sin(TAU * freq * t) * env * vol
		data[i] = int(127 + 127 * clampf(s, -1.0, 1.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = rate
	wav.data = data
	var p := AudioStreamPlayer.new()
	p.stream = wav
	add_child(p)
	return p

func shoot() -> void:
	if enabled:
		p_shoot.play()

func hit() -> void:
	if enabled:
		p_hit.play()

func gem() -> void:
	if enabled:
		p_gem.play()

func level() -> void:
	if enabled:
		p_level.play()

func click() -> void:
	if enabled:
		p_click.play()
