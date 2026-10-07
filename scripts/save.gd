extends RefCounted
class_name MSave

const PATH := "user://save.cfg"

static func load_data() -> Dictionary:
	var cfg := ConfigFile.new()
	var out := {"highscore": 0, "best_time": 0.0, "sound": 1, "motion": 0}
	if cfg.load(PATH) != OK:
		return out
	out["highscore"] = int(cfg.get_value("game", "highscore", 0))
	out["best_time"] = float(cfg.get_value("game", "best_time", 0.0))
	out["sound"] = int(cfg.get_value("prefs", "sound", 1))
	out["motion"] = int(cfg.get_value("prefs", "motion", 0))
	return out

static func save_data(highscore: int, best_time: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("game", "highscore", highscore)
	cfg.set_value("game", "best_time", best_time)
	cfg.save(PATH)

static func save_prefs(sound_on: bool, reduced_motion: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("prefs", "sound", 1 if sound_on else 0)
	cfg.set_value("prefs", "motion", 1 if reduced_motion else 0)
	cfg.save(PATH)
