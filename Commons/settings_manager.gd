extends Node

## Gestore centralizzato delle impostazioni persistenti (autoload "SettingsManager").
## Unica fonte di verità: main menu e pause menu leggono/scrivono qui.
## Tutto viene salvato su user://settings.cfg e applicato all'avvio.

const SETTINGS_PATH: String = "user://settings.cfg"
const DEFAULT_PHYSICS_TICKS: int = 60

# --- Audio (valori lineari 0..1, come gli slider) ---
var master_volume: float = 1.0
var music_volume: float = 1.0
var sound_volume: float = 1.0

# --- Video ---
var physics_ticks: int = DEFAULT_PHYSICS_TICKS
var post_processing: bool = true
var hidpi: bool = true

# --- Accessibilità ---
var reduce_effects: bool = false


func _ready() -> void:
	_load()
	_apply_global()


## Applica le impostazioni globali (audio, fisica, hiDPI). Il post-processing dipende
## dal WorldEnvironment di scena, quindi lo applica il pause_menu quando la scena è pronta.
func _apply_global() -> void:
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("Music", music_volume)
	_apply_bus_volume("Sound", sound_volume)
	Engine.physics_ticks_per_second = physics_ticks
	_apply_hidpi(hidpi)


func _apply_bus_volume(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear))


func _apply_hidpi(enabled: bool) -> void:
	# Replica la logica storica del pause menu: senza hiDPI riportiamo lo scale a 1.0.
	get_tree().root.content_scale_factor = 1.0 if not enabled else get_tree().root.content_scale_factor


# --- Setter pubblici: applicano (dove possibile) e salvano ---

func set_volume(bus_name: String, linear: float) -> void:
	match bus_name:
		"Master": master_volume = linear
		"Music": music_volume = linear
		"Sound": sound_volume = linear
	_apply_bus_volume(bus_name, linear)
	_save()


func set_physics_ticks(hz: int) -> void:
	physics_ticks = hz
	Engine.physics_ticks_per_second = hz
	_save()


func set_post_processing(enabled: bool) -> void:
	post_processing = enabled
	_save()


func set_hidpi(enabled: bool) -> void:
	hidpi = enabled
	_apply_hidpi(enabled)
	_save()


func set_reduce_effects(enabled: bool) -> void:
	reduce_effects = enabled
	_save()


# --- Persistenza ---

func _load() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return  # nessun file: restano i default
	master_volume = float(cfg.get_value("audio", "master", master_volume))
	music_volume = float(cfg.get_value("audio", "music", music_volume))
	sound_volume = float(cfg.get_value("audio", "sound", sound_volume))
	physics_ticks = int(cfg.get_value("video", "physics_ticks", physics_ticks))
	post_processing = bool(cfg.get_value("video", "post_processing", post_processing))
	hidpi = bool(cfg.get_value("video", "hidpi", hidpi))
	reduce_effects = bool(cfg.get_value("accessibility", "reduce_effects", reduce_effects))


func _save() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(SETTINGS_PATH)  # preserva eventuali chiavi non gestite qui
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sound", sound_volume)
	cfg.set_value("video", "physics_ticks", physics_ticks)
	cfg.set_value("video", "post_processing", post_processing)
	cfg.set_value("video", "hidpi", hidpi)
	cfg.set_value("accessibility", "reduce_effects", reduce_effects)
	cfg.save(SETTINGS_PATH)
