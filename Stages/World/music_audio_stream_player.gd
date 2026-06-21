extends AudioStreamPlayer

## Musica a layer verticali (ADDITIVI): i layer partono insieme e restano in sincronia;
## ogni layer SALE di volume quando la sua condizione si verifica e CALA quando non è più
## vera. Non è uno switch — i layer suonano sovrapposti, uno sopra l'altro.
## Ordine atteso in "layers": [0] base (sempre attivo), [1] movimento, [2] vicino a un corpo.

@export var layers: Array[AudioStream] = []
@export var layer_bus: StringName = &"Music"
## Volume di un layer quando è attivo (dB).
@export var active_volume_db: float = -5.0
## Velocità di dissolvenza in dB al secondo (entrata/uscita di un layer).
@export var fade_db_per_sec: float = 40.0
@export var min_distance: float = 2000.0
## Soglia di velocità (px/s) oltre cui entra il layer "movimento".
@export var moving_speed_threshold: float = 500.0

const SILENCE_DB: float = -60.0

@onready var player: Player = get_tree().get_first_node_in_group("player")

var _layer_players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for stream: AudioStream in layers:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.stream = stream
		p.bus = layer_bus
		p.volume_db = SILENCE_DB
		# I clip non hanno il loop attivo nell'import: si ri-avviano da soli a fine
		# traccia. Stessa lunghezza + avvio simultaneo = restano sempre in sincronia.
		p.finished.connect(p.play)
		add_child(p)
		_layer_players.append(p)
	# Il layer base parte già a volume pieno; gli altri entrano in dissolvenza.
	if not _layer_players.is_empty():
		_layer_players[0].volume_db = active_volume_db
	# Avvio nello stesso frame: i layer restano allineati.
	for p: AudioStreamPlayer in _layer_players:
		p.play()


func get_min_distance() -> float:
	if player == null:
		return min_distance
	return min_distance * player.mass


func _process(delta: float) -> void:
	if player == null or _layer_players.is_empty():
		return
	var step: float = fade_db_per_sec * delta
	for i: int in _layer_players.size():
		var target: float = active_volume_db if _layer_active(i) else SILENCE_DB
		_layer_players[i].volume_db = move_toward(_layer_players[i].volume_db, target, step)


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
