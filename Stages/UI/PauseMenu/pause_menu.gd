extends CanvasLayer

@export var world_env: WorldEnvironment

var saved_environment: Environment

# Controlli (nomi unici nella scena)
@onready var master_slider: HSlider = %Master
@onready var music_slider: HSlider = %Music
@onready var sound_slider: HSlider = %Sound
@onready var post_processing_check: CheckButton = %PostProcessing
@onready var hidpi_check: CheckButton = %hiDPI
@onready var reduce_effects_check: CheckButton = %ReduceEffects

# Label statistiche live
@onready var stat_time: Label = %StatTime
@onready var stat_level: Label = %StatLevel
@onready var stat_kills: Label = %StatKills
@onready var stat_energy: Label = %StatEnergy

## Evita che l'inizializzazione dei controlli in _ready faccia ripartire i setter (e i salvataggi).
var _initializing: bool = true


func _ready() -> void:
	hide()
	saved_environment = world_env.environment
	_init_controls_from_settings()


## Allinea i controlli ai valori salvati e applica post-processing/hiDPI (dipendono dalla scena).
func _init_controls_from_settings() -> void:
	master_slider.value = SettingsManager.master_volume
	music_slider.value = SettingsManager.music_volume
	sound_slider.value = SettingsManager.sound_volume
	post_processing_check.button_pressed = SettingsManager.post_processing
	hidpi_check.button_pressed = SettingsManager.hidpi
	reduce_effects_check.button_pressed = SettingsManager.reduce_effects
	# Applica lo stato salvato al mondo corrente
	world_env.environment = saved_environment if SettingsManager.post_processing else null
	_initializing = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		visible = !visible
		if get_tree().paused:
			get_tree().paused = false
		else:
			get_tree().paused = true
			_refresh_stats()


## Aggiorna le statistiche della run corrente (lette da StatTracker) all'apertura del menu.
func _refresh_stats() -> void:
	stat_time.text = "Tempo: %s" % StatTracker.format_time(StatTracker.time_survived)
	stat_level.text = "Livello: %d" % StatTracker.level_reached
	stat_kills.text = "Nemici: %d" % StatTracker.enemies_killed
	stat_energy.text = "Energia: %.0f" % StatTracker.energy_collected


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


# --- Audio ---

func _on_master_value_changed(value: float) -> void:
	if _initializing:
		return
	SettingsManager.set_volume("Master", value)
func _on_music_value_changed(value: float) -> void:
	if _initializing:
		return
	SettingsManager.set_volume("Music", value)
func _on_sound_value_changed(value: float) -> void:
	if _initializing:
		return
	SettingsManager.set_volume("Sound", value)


# --- Performance / Accessibilità ---

func _on_post_processing_pressed() -> void:
	var on: bool = post_processing_check.button_pressed
	world_env.environment = saved_environment if on else null
	SettingsManager.set_post_processing(on)


func _on_hi_dpi_pressed() -> void:
	var on: bool = hidpi_check.button_pressed
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, false)
	SettingsManager.set_hidpi(on)


func _on_reduce_effects_toggled(toggled_on: bool) -> void:
	if _initializing:
		return
	SettingsManager.set_reduce_effects(toggled_on)
