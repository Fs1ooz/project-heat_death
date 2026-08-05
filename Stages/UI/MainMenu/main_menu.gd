extends Control


const SOLAR_SYSTEM: String = "res://Stages/World/SolarSystem/solar_system.tscn"
const TUTORIAL: String = "res://Stages/UI/Tutorial/tutorial.tscn"

## Frequenza di aggiornamento della fisica selezionabile. Più alta = movimento più fluido su
## monitor ad alto refresh (es. 165Hz), ma più costosa in CPU (la gravità N-body gira a ogni tick).
## La persistenza è gestita da SettingsManager.
const PHYSICS_TICK_OPTIONS: Array[int] = [30, 60, 120, 165, 180, 240]

@onready var physics_tick_option: OptionButton = $SettingsBox/PhysicsTickOption
@onready var record_label: Label = %RecordLabel


func _ready() -> void:
	_setup_physics_tick_option()
	_setup_record_label()
	$Ceres.set_process(false)
	_animate_title()
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



## Titolo animato: dissolvenza incrociata in loop tra i due frame del logo
## (LogoA sempre visibile sotto, LogoB sopra che appare/sparisce in fade).
func _animate_title() -> void:
	var logo_b: TextureRect = $VBoxContainer/Title/LogoB
	var title_tween: Tween = create_tween()
	title_tween.set_loops()
	title_tween.set_trans(Tween.TRANS_SINE)
	title_tween.tween_property(logo_b, "modulate:a", 1.0, 1.5)
	title_tween.tween_interval(0.6)
	title_tween.tween_property(logo_b, "modulate:a", 0.0, 1.5)
	title_tween.tween_interval(0.6)


func _on_button_pressed() -> void:
	$Press.play()
	await $Press.finished
	get_tree().change_scene_to_file(SOLAR_SYSTEM)
	EntropyManager.reset_entropy()
	$Ceres.set_process(true)



func _on_tutorial_pressed() -> void:
	$Press.play()
	await $Press.finished
	EntropyManager.reset_entropy()
	get_tree().change_scene_to_file(TUTORIAL)



func _on_tributo_gormita_pressed() -> void:
	OS.shell_open("https://youtu.be/1UasLgvrg0w?si=fMJ31DeOpD6dlUiO&t=69")


# --- Record -----------------------------------------------------------------

func _setup_record_label() -> void:
	if StatTracker.best_time > 0.0:
		record_label.text = "Record: %s (lvl %d)" % [StatTracker.format_time(StatTracker.best_time), StatTracker.best_level]
		record_label.show()
	else:
		record_label.hide()


# --- Frequenza fisica -------------------------------------------------------

func _setup_physics_tick_option() -> void:
	physics_tick_option.clear()
	var saved: int = SettingsManager.physics_ticks
	var selected_idx: int = 0
	for i: int in PHYSICS_TICK_OPTIONS.size():
		var hz: int = PHYSICS_TICK_OPTIONS[i]
		physics_tick_option.add_item("Fisica: %d Hz" % hz, hz)
		if hz == saved:
			selected_idx = i
	physics_tick_option.select(selected_idx)
	SettingsManager.set_physics_ticks(PHYSICS_TICK_OPTIONS[selected_idx])


func _on_physics_tick_option_item_selected(index: int) -> void:
	SettingsManager.set_physics_ticks(PHYSICS_TICK_OPTIONS[index])




func _on_button_mouse_entered() -> void:
	$Focus.play()


func _on_tutorial_button_mouse_entered() -> void:
	$Focus.play()
