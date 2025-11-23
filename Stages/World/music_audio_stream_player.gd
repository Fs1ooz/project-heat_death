extends AudioStreamPlayer

@export var min_distance: float = 2500.0
@export var player: Player

# Indici dei clip
const CLIP_IDLE := 0
const CLIP_MOVING := 1
const CLIP_NEAR_BODY := 2

var current_clip := -1
var music: AudioStreamPlaybackInteractive = null

func _ready():
	play()  # serve per inizializzare il playback
	music = get_stream_playback() as AudioStreamPlaybackInteractive
	if music == null:
		push_error("AudioStreamPlaybackInteractive non trovato! Controlla che lo stream sia AudioStreamInteractive.")



func _process(_delta):
	if not player or music == null:
		return
	var index := get_active_clip()
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
	for body in get_tree().get_nodes_in_group("celestial_bodies"):
		if body is CelestialBody:
			var to_body = body.global_position - player.global_position
			var distance = to_body.length()
			if distance <= min_distance:
				var dir_to_body = to_body.normalized()
				var facing = Vector2(cos(player.rotation), sin(player.rotation))
				var dot = dir_to_body.dot(facing)
				if dot > 0.7:
					return true
	return false
