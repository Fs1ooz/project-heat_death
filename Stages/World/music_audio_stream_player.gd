extends AudioStreamPlayer

## Musica a layer verticali (ADDITIVI) su un singolo AudioStreamSynchronized: i layer
## suonano insieme, sincronizzati a livello di campione dall'engine. Lo script si limita ad
## alzare/abbassare il volume di ciascun layer (set_sync_stream_volume) quando la sua
## condizione si verifica — non è uno switch, i layer si sovrappongono.
## Ordine atteso degli stream: [0] base (sempre), [1] movimento, [2] vicino a un corpo.

## Volume di un layer quando è attivo (dB; 0 = nessuna attenuazione oltre al volume_db del nodo).
@export var active_volume_db: float = 0.0
## Velocità di dissolvenza in dB al secondo (entrata/uscita di un layer).
@export var fade_db_per_sec: float = 70.0
@export var min_distance: float = 2000.0
## Soglia di velocità (px/s) oltre cui entra il layer "movimento".
@export var moving_speed_threshold: float = 500.0

const SILENCE_DB: float = -60.0

@onready var player: Player = get_tree().get_first_node_in_group("player")
var _sync: AudioStreamSynchronized = null


func _ready() -> void:
	_sync = stream as AudioStreamSynchronized
	if _sync == null:
		push_error("MusicAudioStreamPlayer: lo stream non è un AudioStreamSynchronized.")
		return
	# I clip non hanno il loop nell'import: si riparte a fine traccia (l'engine tiene la sync).
	finished.connect(play)
	# Stato iniziale: solo il layer base udibile, gli altri silenziati.
	for i: int in _sync.get_stream_count():
		_sync.set_sync_stream_volume(i, active_volume_db if i == 0 else SILENCE_DB)
	play()


func get_min_distance() -> float:
	if player == null:
		return min_distance
	return min_distance * player.mass


func _process(delta: float) -> void:
	if player == null or _sync == null:
		return
	var step: float = fade_db_per_sec * delta
	for i: int in _sync.get_stream_count():
		var target: float = active_volume_db if _layer_active(i) else SILENCE_DB
		var current: float = _sync.get_sync_stream_volume(i)
		_sync.set_sync_stream_volume(i, move_toward(current, target, step))


## Condizione di attivazione per ciascun layer.
func _layer_active(index: int) -> bool:
	match index:
		1:
			return player.linear_velocity.length() > moving_speed_threshold
		2:
			return near_celestial_body()
		_:
			return true  # layer base: sempre attivo


func near_celestial_body() -> bool:
	for body: CelestialBody in CelestialBody.celestial_bodies:
		var to_body: Vector2 = body.global_position - player.global_position
		var distance: float = to_body.length()
		if distance <= get_min_distance():
			var dir_to_body: Vector2 = to_body.normalized()
			var facing: Vector2 = Vector2(cos(player.rotation), sin(player.rotation))
			if dir_to_body.dot(facing) > 0.7:
				return true
	return false
