extends Node

var time_survived: float = 0.0
var enemies_killed: int = 0
var energy_collected: float = 0.0
var level_reached: int = 1

var _tracking: bool = false

func _ready() -> void:
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

func reset() -> void:
	time_survived = 0.0
	enemies_killed = 0
	energy_collected = 0.0
	level_reached = 1
	_tracking = true
