extends Node

@warning_ignore("unused_signal")
signal game_over()
@warning_ignore("unused_signal")
signal death(body: CelestialBody)
@warning_ignore("unused_signal")
signal low_health(value: bool)
@warning_ignore("unused_signal")
signal windup_shake(intensity: float, time: float)
@warning_ignore("unused_signal")
signal ceres_spawned(ceres: Node2D)
@warning_ignore("unused_signal")
signal show_tip(tip: String)
## Scarica d'entropia partita. power: 0..1, quanta entropia è stata scaricata rispetto al massimo.
@warning_ignore("unused_signal")
signal entropy_released(power: float)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
