extends SmallBody
class_name Comet
## SmallBody Setup: min_speed = 150.0 max_speed = 210.0
## CelestialBody Setup: internal_energy = 3 game_energy = 80 min_size = 3.0 max_size = 15.0 round_base = 1
#
@export var energy_per_drop: int = 2
var initial_scale: Vector2
var initial_mass: float
var initial_game_energy: int
@onready var timer: Timer = $Timer

@export var min_speed: float = 5.0
@export var max_speed: float = 15.0




func _ready() -> void:
	super()
	initial_scale = collision.scale
	initial_mass = mass
	initial_game_energy = game_energy

	_kick.call_deferred()

func _process(_delta: float) -> void:
	if game_energy <= 0:
		timer.stop()
		_die_empty()


func _on_timer_timeout() -> void:
	_spawn_trail_drop()



func _kick() -> void:
	var direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0.0, TAU)).normalized()
	var speed: float = randf_range(min_speed, max_speed)
	apply_impulse(direction * speed * mass / 2)





func _spawn_trail_drop() -> void:
	if game_energy <= 0: return
	var energy_drop = energy_drop_scene.instantiate()
	energy_drop.energy = energy_per_drop
	energy_drop.global_position = global_position + (-linear_velocity.normalized() * 20.0)
	get_parent().call_deferred("add_child", energy_drop)
	game_energy = max(0, game_energy - energy_per_drop)
	var energy_ratio = float(game_energy) / float(initial_game_energy)
	collision.scale = initial_scale * energy_ratio
	if mass > 0:
		mass = initial_mass * energy_ratio

func _die_empty() -> void:
	queue_free()

func die() -> void:
	if game_energy > 0: _spawn_energy_drop()
	_spawn_explosion()
	queue_free()
