extends RefCounted
class_name MSave

const PATH := "user://save.cfg"

static func load_data() -> Dictionary:
	var cfg := ConfigFile.new()
	var out := {"highscore": 0, "best_time": 0.0}
	if cfg.load(PATH) != OK:
		return out
	out["highscore"] = int(cfg.get_value("game", "highscore", 0))
	out["best_time"] = float(cfg.get_value("game", "best_time", 0.0))
	return out

static func save_data(highscore: int, best_time: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("game", "highscore", highscore)
	cfg.set_value("game", "best_time", best_time)
	cfg.save(PATH)
