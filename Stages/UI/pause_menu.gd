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
