extends Node

@warning_ignore("unused_signal")
signal game_over()
@warning_ignore("unused_signal")
signal death(body: CelestialBody)
@warning_ignore("unused_signal")
signal low_health(value: bool)
@warning_ignore("unused_signal")
signal windup_shake(intensity: float, time: float)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
