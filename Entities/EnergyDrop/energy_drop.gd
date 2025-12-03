extends Area2D

static var energy: int = 10
static var starting_threshold: float = 500.0
static var threshold: float = starting_threshold

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sfx: AudioStreamPlayer = $EnergyAudioStreamPlayer


var playback: AudioStreamPlayback = null # Actual playback stream, assigned in _ready().

func _physics_process(delta: float) -> void:
	if not player:
		return
	var distance = global_position.distance_to(player.global_position)
	if distance < threshold:
		var speed = threshold / 1.5 * (1.0 - distance / threshold) * delta
		global_position = global_position.move_toward(player.global_position, speed)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		threshold = starting_threshold + (starting_threshold * body.mass) / 15
		print("Thresh:", threshold)

		# Genera e riproduci il suono proceduralmente
		sfx.reparent(player)
		sfx.play()
		sfx.connect("finished", queue_free)

		UpgradeManager.gain_energy(energy)
		queue_free()
