extends Control

@onready var death_camera: Camera2D = $"../../DeathCamera"
@onready var player: Player = $"../../Player"

func _ready() -> void:
	get_tree().paused = false
	hide()
	GlobalSignals.connect("game_over", _on_game_over)


func _on_retry_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_game_over()  -> void:
	death_camera.global_position = player.global_position
	death_camera.make_current()

	show()
