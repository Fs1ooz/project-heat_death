extends Control

@onready var death_camera: Camera2D = $"../../DeathCamera"
@onready var player_camera: Camera2D = $"../../Player/PlayerCamera"
@onready var level_label: Label = %LevelLabel
@onready var time_label: Label = %TimeLabel
@onready var kills_label: Label = %KillsLabel
@onready var energy_label: Label = %EnergyLabel

func _ready() -> void:
	get_tree().paused = false
	hide()
	GlobalSignals.connect("game_over", _on_game_over)


func _on_retry_button_pressed() -> void:
	StatTracker.reset()
	get_tree().reload_current_scene()


func _on_main_menu_button_pressed() -> void:
	StatTracker.reset()
	get_tree().change_scene_to_file("res://Stages/UI/MainMenu/main_menu.tscn")


func _on_game_over() -> void:
	death_camera.global_position = player_camera.global_position
	death_camera.make_current()
	death_camera.zoom = player_camera.zoom * 0.75

	level_label.text = "Livello: %d" % StatTracker.level_reached
	time_label.text = "Tempo: %s" % _format_time(StatTracker.time_survived)
	kills_label.text = "Nemici: %d" % StatTracker.enemies_killed
	energy_label.text = "Energia: %.0f" % StatTracker.energy_collected

	show()


func _format_time(seconds: float) -> String:
	var mins: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	return "%d:%02d" % [mins, secs]
