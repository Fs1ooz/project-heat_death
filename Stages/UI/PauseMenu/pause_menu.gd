extends CanvasLayer

@export var world_env: WorldEnvironment

var saved_environment: Environment

func _ready() -> void:
	hide()
	saved_environment = world_env.environment

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
	get_tree().paused = false
	GlobalSignals.game_over.emit()
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Stages/UI/MainMenu/main_menu.tscn")


func _set_bus_volume(bus_name: String, value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), linear_to_db(value))

func _on_master_value_changed(value: float) -> void:
	_set_bus_volume("Master", value)
func _on_music_value_changed(value: float) -> void:
	_set_bus_volume("Music", value)
func _on_sound_value_changed(value: float) -> void:
	_set_bus_volume("Sound", value)


var post_processing_enabled: bool = true

func _on_post_processing_pressed() -> void:
	post_processing_enabled = !post_processing_enabled
	world_env.environment = saved_environment if post_processing_enabled else null

var hidpi_enabled: bool = true

func _on_hi_dpi_pressed() -> void:
	hidpi_enabled = !hidpi_enabled
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, false)
	get_tree().root.content_scale_factor = 1.0 if not hidpi_enabled else get_tree().root.content_scale_factor



func _on_models_3d_toggled(toggled_on: bool) -> void:
	GlobalSignals.use_3d.emit(toggled_on)
