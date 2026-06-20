extends AudioStreamPlayer

@export var min_distance: float = 2000.0
@onready var player: Player = get_tree().get_first_node_in_group("player")

# Indici dei clip
const CLIP_IDLE: int = 0
const CLIP_MOVING: int = 1
const CLIP_NEAR_BODY: int = 2

var current_clip: int = -1
var music: AudioStreamPlaybackInteractive = null

func _ready() -> void:
	play()  # serve per inizializzare il playback
	music = get_stream_playback() as AudioStreamPlaybackInteractive
	if music == null:
		push_error("AudioStreamPlaybackInteractive non trovato! Controlla che lo stream sia AudioStreamInteractive.")


func get_min_distance() -> float:
	return min_distance * player.mass

func _process(_delta: float) -> void:
	if not player or music == null:
		return

	var index: int = get_active_clip()
	if index != current_clip:
		current_clip = index
		music.switch_to_clip(current_clip)

func get_active_clip() -> int:
	if near_celestial_body():
		return CLIP_NEAR_BODY
	elif player.linear_velocity.length() > 500.0:
		return CLIP_MOVING
	else:
		return CLIP_IDLE

func near_celestial_body() -> bool:
	for body: CelestialBody in CelestialBody.celestial_bodies:
		var to_body: Vector2 = body.global_position - player.global_position
		var distance: float = to_body.length()
		if distance <= get_min_distance():
			var dir_to_body: Vector2 = to_body.normalized()
			var facing: Vector2 = Vector2(cos(player.rotation), sin(player.rotation))
			var dot: float = dir_to_body.dot(facing)
			if dot > 0.7:
					return true
	return false
