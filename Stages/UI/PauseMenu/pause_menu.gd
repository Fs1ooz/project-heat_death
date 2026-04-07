extends CanvasLayer


func _ready() -> void:
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		visible = !visible
		if get_tree().paused:
			get_tree().paused = false
		else:
			get_tree().paused = true


func _on_close_pressed() -> void:
	hide()
	get_tree().paused = false


func _on_restart_pressed() -> void:
	GlobalSignals.death.emit()
	get_tree().reload_current_scene()

func _set_bus_volume(bus_name: String, value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), linear_to_db(value))

func _on_master_value_changed(value: float) -> void:
	_set_bus_volume("Master", value)
func _on_music_value_changed(value: float) -> void:
	_set_bus_volume("Music", value)
func _on_sound_value_changed(value: float) -> void:
	_set_bus_volume("Sound", value)
