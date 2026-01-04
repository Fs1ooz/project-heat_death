class_name EnergyDrop
extends Area2D

static var starting_threshold: float = 500.0
@onready var energy: int = 1
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var sfx: AudioStreamPlayer = $EnergyAudioStreamPlayer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $CollisionShape2D/Sprite2D

var colors: Array = [
	Color("ffdd00ff"), Color("ffa500"), Color("ff0000"),
	Color("da0076ff"), Color("b5019cff"), Color("1f5bffff"),
	Color("5dd2ffff"), Color("00e2d5ff"), Color("00b69aff"),
	Color("00a952ff"), Color("00ff00"),
]

var playback: AudioStreamPlayback = null
var _spawn_time: float = 0.0
var _is_in_range: bool = false  # Flag per tracciare se è nel range

func _ready() -> void:
	_spawn_time = Time.get_unix_time_from_system()
	energy = weighted_random_energy(100, 3.0)
	update_color()

@export var energy_per_cycle: float = 100.0

func update_color() -> void:
	if energy <= 0:
		return
	var cycle_pos: float = (energy / energy_per_cycle) * colors.size()
	var i: int = int(cycle_pos) % colors.size()
	var next_i: int = (i + 1) % colors.size()
	var f: float = cycle_pos - int(cycle_pos)
	var scale_factor: float = 1.0 + (energy / energy_per_cycle)
	sprite.modulate = colors[i].lerp(colors[next_i], f) * Color(1,1,1,0.7)
	sprite.scale *= scale_factor

func weighted_random_energy(max_energy: int, weight_power: float) -> int:
	var r: float = randf()
	var weighted: float = pow(r, weight_power)
	return int(1 + weighted * (max_energy - 1))


func _physics_process(delta: float) -> void:
	if not _is_in_range or not player:
		return

	var distance: float = global_position.distance_to(player.global_position)
	var active_threshold: float = max(starting_threshold, player.energy_threshold)

	# Calcola velocità con un minimo garantito
	var normalized_distance: float = clamp(distance / active_threshold, 0.0, 1.0)
	var speed: float = lerp(1000.0, 50.0, normalized_distance) * delta  # velocità da 200 a 50

	global_position = global_position.move_toward(player.global_position, speed)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		sfx.reparent(body)
		sfx.play()
		sfx.connect("finished", queue_free)
		var amount: float = 1.0 + (0.1 / (body.mass + 1))
		body.change_size(amount)
		UpgradeManager.gain_energy(energy)
		queue_free()


func _on_range_body_entered(body: Node2D) -> void:
	if body is not Player:
		return
	_is_in_range = true


func _on_range_body_exited(body: Node2D) -> void:
	if body is not Player:
		return
	_is_in_range = false
