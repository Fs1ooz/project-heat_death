class_name DeathVFX
extends Node2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var explosion_red: GPUParticles2D = $ExplosionRed
@onready var shockwave: GPUParticles2D = $Shockwave

@onready var explosion_red_initial_scale: Vector2 = Vector2(explosion_red.process_material.scale_min, explosion_red.process_material.scale_max)
@onready var shockwave_initial_scale: Vector2 = Vector2(shockwave.process_material.scale_min, shockwave.process_material.scale_max)
@onready var explosion_red_initial_velocity: Vector2 = Vector2(explosion_red.process_material.initial_velocity_min, explosion_red.process_material.initial_velocity_max)

@onready var explosion_red_initial_trail_lifetime: float = explosion_red.trail_lifetime

var _debris: GPUParticles2D
var _debris_initial_velocity: Vector2
var _debris_initial_scale: Vector2

func _ready() -> void:
	_setup_debris()
	anim_player.play("explosion")
	# Flash overbright al momento dell'esplosione
	modulate = Color(3.0, 3.0, 3.0, 1.0)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.12)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func _setup_debris() -> void:
	_debris = GPUParticles2D.new()
	add_child(_debris)
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.direction = Vector3(0.0, 0.0, 0.0)
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 250.0
	mat.spread = 180.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 30.0
	mat.damping_max = 60.0
	mat.scale_min = explosion_red_initial_scale.x * 0.4
	mat.scale_max = explosion_red_initial_scale.y * 0.4
	var color_ramp_tex: GradientTexture1D = GradientTexture1D.new()
	var grad: Gradient = Gradient.new()
	grad.set_color(0, Color(1.0, 0.4, 0.1, 1.0))  # arancio caldo
	grad.add_point(0.6, Color(0.6, 0.2, 0.05, 0.6))
	grad.add_point(1.0, Color.TRANSPARENT)
	color_ramp_tex.gradient = grad
	mat.color_ramp = color_ramp_tex
	_debris.process_material = mat
	_debris.amount = 20
	_debris.lifetime = 1.8
	_debris.explosiveness = 0.6
	_debris.one_shot = true
	_debris.emitting = true
	_debris_initial_velocity = Vector2(mat.initial_velocity_min, mat.initial_velocity_max)
	_debris_initial_scale = Vector2(mat.scale_min, mat.scale_max)


func scale_explosion(scale_factor: float) -> void:
	scale *= scale_factor

	explosion_red.process_material = explosion_red.process_material.duplicate()
	explosion_red.process_material.scale_min = explosion_red_initial_scale.x * scale_factor
	explosion_red.process_material.scale_max = explosion_red_initial_scale.y * scale_factor
	explosion_red.process_material.initial_velocity_min = explosion_red_initial_velocity.x * scale_factor
	explosion_red.process_material.initial_velocity_max = explosion_red_initial_velocity.y * scale_factor

	shockwave.process_material = shockwave.process_material.duplicate()
	shockwave.process_material.scale_min = shockwave_initial_scale.y * scale_factor
	shockwave.process_material.scale_max = shockwave_initial_scale.y * scale_factor

	if _debris != null:
		_debris.process_material = _debris.process_material.duplicate()
		_debris.process_material.scale_min = _debris_initial_scale.x * scale_factor
		_debris.process_material.scale_max = _debris_initial_scale.y * scale_factor
		_debris.process_material.initial_velocity_min = _debris_initial_velocity.x * scale_factor
		_debris.process_material.initial_velocity_max = _debris_initial_velocity.y * scale_factor


# Questo segnale deve essere collegato dal pannello "Nodi" dell'AnimationPlayer
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "explosion":
		queue_free()
