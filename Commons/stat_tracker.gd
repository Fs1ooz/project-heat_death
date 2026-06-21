extends Node

const RECORDS_PATH: String = "user://records.cfg"

# --- Run corrente ---
var time_survived: float = 0.0
var enemies_killed: int = 0
var energy_collected: float = 0.0
var level_reached: int = 1

# --- Record persistenti (best di sempre) ---
var best_time: float = 0.0
var best_level: int = 1
var best_kills: int = 0
var best_energy: float = 0.0
## True se l'ultima run ha battuto il record di tempo (letto dal game over screen).
var last_run_new_record: bool = false

var _tracking: bool = false

func _ready() -> void:
	_load_records()
	GlobalSignals.game_over.connect(_on_game_over)
	GlobalSignals.death.connect(_on_death)
	UpgradeManager.energy_gained.connect(_on_energy_gained)
	UpgradeManager.energy_changed.connect(_on_energy_changed)
	_tracking = true

func _process(delta: float) -> void:
	if _tracking and not get_tree().paused:
		time_survived += delta

func _on_death(_body: CelestialBody) -> void:
	enemies_killed += 1

func _on_energy_gained(amount: float) -> void:
	energy_collected += amount

func _on_energy_changed(_current: float, _max: float, level: int) -> void:
	level_reached = level

func _on_game_over() -> void:
	_tracking = false
	# Il nuovo record è sul tempo sopravvissuto (metrica principale del survival).
	last_run_new_record = time_survived > best_time
	best_time = maxf(best_time, time_survived)
	best_level = maxi(best_level, level_reached)
	best_kills = maxi(best_kills, enemies_killed)
	best_energy = maxf(best_energy, energy_collected)
	_save_records()

func reset() -> void:
	time_survived = 0.0
	enemies_killed = 0
	energy_collected = 0.0
	level_reached = 1
	last_run_new_record = false
	_tracking = true


## Formatta i secondi come m:ss (riusato da game over e pause menu).
func format_time(seconds: float) -> String:
	var mins: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	return "%d:%02d" % [mins, secs]


# --- Persistenza record ---

func _load_records() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(RECORDS_PATH) != OK:
		return
	best_time = float(cfg.get_value("records", "best_time", best_time))
	best_level = int(cfg.get_value("records", "best_level", best_level))
	best_kills = int(cfg.get_value("records", "best_kills", best_kills))
	best_energy = float(cfg.get_value("records", "best_energy", best_energy))

func _save_records() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(RECORDS_PATH)
	cfg.set_value("records", "best_time", best_time)
	cfg.set_value("records", "best_level", best_level)
	cfg.set_value("records", "best_kills", best_kills)
	cfg.set_value("records", "best_energy", best_energy)
	cfg.save(RECORDS_PATH)
