extends Control


func _ready() -> void:
	get_tree().paused = false
	hide()
	GlobalSignals.connect("game_over", _on_game_over)


func _on_retry_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_game_over()  -> void:
	get_tree().paused = true
	show()
