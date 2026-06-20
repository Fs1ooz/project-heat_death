extends Control


const SOLAR_SYSTEM: String = "res://Stages/World/SolarSystem/solar_system.tscn"
const TUTORIAL: String = "res://Stages/UI/Tutorial/tutorial.tscn"

## Impostazioni persistenti (sopravvivono al riavvio).
const SETTINGS_PATH: String = "user://settings.cfg"
## Frequenza di aggiornamento della fisica selezionabile. Più alta = movimento più fluido su
## monitor ad alto refresh (es. 165Hz), ma più costosa in CPU (la gravità N-body gira a ogni tick).
const PHYSICS_TICK_OPTIONS: Array[int] = [60, 120, 165, 180, 240]
const DEFAULT_PHYSICS_TICKS: int = 60

@onready var physics_tick_option: OptionButton = $SettingsBox/PhysicsTickOption


func _ready() -> void:
	_setup_physics_tick_option()
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


func _on_tutorial_pressed() -> void:
	EntropyManager.reset_entropy()
	get_tree().change_scene_to_file(TUTORIAL)


func _on_tributo_gormita_pressed() -> void:
	OS.shell_open("https://youtu.be/1UasLgvrg0w?si=fMJ31DeOpD6dlUiO&t=69")


func _on_no_3d_toggled(toggled_on: bool) -> void:
	GlobalSignals.use_3d.emit(toggled_on)


# --- Frequenza fisica -------------------------------------------------------

func _setup_physics_tick_option() -> void:
	physics_tick_option.clear()
	var saved: int = _load_physics_ticks()
	var selected_idx: int = 0
	for i: int in PHYSICS_TICK_OPTIONS.size():
		var hz: int = PHYSICS_TICK_OPTIONS[i]
		physics_tick_option.add_item("Fisica: %d Hz" % hz, hz)
		if hz == saved:
			selected_idx = i
	physics_tick_option.select(selected_idx)
	_apply_physics_ticks(PHYSICS_TICK_OPTIONS[selected_idx])


func _on_physics_tick_option_item_selected(index: int) -> void:
	var hz: int = PHYSICS_TICK_OPTIONS[index]
	_apply_physics_ticks(hz)
	_save_physics_ticks(hz)


func _apply_physics_ticks(hz: int) -> void:
	Engine.physics_ticks_per_second = hz


func _load_physics_ticks() -> int:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return DEFAULT_PHYSICS_TICKS
	return int(cfg.get_value("video", "physics_ticks", DEFAULT_PHYSICS_TICKS))


func _save_physics_ticks(hz: int) -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(SETTINGS_PATH)  # se manca, partiamo da un file nuovo
	cfg.set_value("video", "physics_ticks", hz)
	cfg.save(SETTINGS_PATH)
