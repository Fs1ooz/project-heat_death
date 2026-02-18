class_name Comet
extends SmallBody

@export var energy_per_drop: int = 10
@onready var kick_component: KickComponent = %KickComponent
@onready var comet_trail: GPUParticles2D = %CometTrail

var mat: ParticleProcessMaterial

# Valori iniziali da cui scalare in modo assoluto
var initial_mat_scale: Vector2
var initial_sprite_scale: Vector2
var initial_mass: float
var initial_velocity_min: float
var initial_velocity_max: float

# Scale target verso cui interpolare smoothly
var target_scale: Vector2

@onready var initial_game_energy: float = game_energy

func _ready() -> void:
	super()
	mat = comet_trail.process_material.duplicate()
	comet_trail.process_material = mat

	initial_sprite_scale = sprite.scale
	initial_mat_scale = Vector2(mat.scale_min, mat.scale_max)
	initial_velocity_min = mat.initial_velocity_min
	initial_velocity_max = mat.initial_velocity_max
	initial_mass = mass

	target_scale = initial_sprite_scale

	mat.scale_min = initial_mat_scale.x * sprite.scale.x
	mat.scale_max = initial_mat_scale.y * sprite.scale.x

	rotation = kick_component.kick_position().angle()

var timer: float = 0.0
var next_drop_time: float = 0.25

func _process(delta: float) -> void:
	timer += delta
	if timer > next_drop_time:
		_spawn_trail_drop()
		timer = 0.0

	# Interpolazione smooth verso il target invece di scatti
	sprite.scale = sprite.scale.lerp(target_scale, delta * 4.0)
	mat.scale_min = initial_mat_scale.x * sprite.scale.x
	mat.scale_max = initial_mat_scale.y * sprite.scale.x

	if game_energy <= 0:
		_die_empty()

func _spawn_trail_drop() -> void:
	if game_energy <= 0:
		return

	var energy_drop: Exp = energy_drop_scene.instantiate()
	energy_drop.energy = energy_per_drop
	energy_drop.global_position = global_position + (-linear_velocity.normalized() * 20.0)
	get_parent().add_child.call_deferred(energy_drop)

	game_energy = max(0, game_energy - energy_per_drop)
	var energy_ratio: float = game_energy / initial_game_energy
	print(game_energy)
	# Tutto calcolato in modo ASSOLUTO rispetto ai valori iniziali
	target_scale = initial_sprite_scale * energy_ratio
	mass = initial_mass * energy_ratio
	mat.initial_velocity_min = initial_velocity_min * energy_ratio
	mat.initial_velocity_max = initial_velocity_max * energy_ratio

func _die_empty() -> void:
	queue_free()
