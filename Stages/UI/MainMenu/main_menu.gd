extends Control


const SOLAR_SYSTEM: String = "res://Stages/World/SolarSystem/solar_system.tscn"


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file(SOLAR_SYSTEM)


func _on_tributo_gormita_pressed() -> void:
	OS.shell_open("https://youtu.be/1UasLgvrg0w?si=fMJ31DeOpD6dlUiO&t=69")
