extends Control


const SOLAR_SYSTEM: String = "res://Stages/World/SolarSystem/solar_system.tscn"


func _ready() -> void:
	$Ceres.set_process(false)
	var tween: Tween = create_tween()
	tween.set_loops()

	# Fase 1: si allontana (rimpicciolisce, ruota, deriva)
	tween.tween_property($BackgroundLayer, "scale", Vector2(0.01, 0.01), 90)
	tween.parallel().tween_property($BackgroundLayer, "rotation", deg_to_rad(180), 90)
	tween.parallel().tween_property($BackgroundLayer, "offset", Vector2(80, 40), 90)

	# Fase 2: torna vicino
	tween.tween_property($BackgroundLayer, "scale", Vector2(0.15, 0.15), 50)
	tween.parallel().tween_property($BackgroundLayer, "rotation", deg_to_rad(0), 50)
	tween.parallel().tween_property($BackgroundLayer, "offset", Vector2(0, 0), 50)



func _on_button_pressed() -> void:
	get_tree().change_scene_to_file(SOLAR_SYSTEM)
	EntropyManager.reset_entropy()
	$Ceres.set_process(true)


func _on_tributo_gormita_pressed() -> void:
	OS.shell_open("https://youtu.be/1UasLgvrg0w?si=fMJ31DeOpD6dlUiO&t=69")


func _on_no_3d_toggled(toggled_on: bool) -> void:
	GlobalSignals.use_3d.emit(toggled_on)
