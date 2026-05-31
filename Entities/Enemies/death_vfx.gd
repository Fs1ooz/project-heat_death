class_name DeathVFX
extends Node2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var explosion_red: GPUParticles2D = $ExplosionRed
@onready var shockwave: GPUParticles2D = $Shockwave
@onready var debris: GPUParticles2D = $Debris

@onready var explosion_red_initial_scale: Vector2 = Vector2(explosion_red.process_material.scale_min, explosion_red.process_material.scale_max)
@onready var shockwave_initial_scale: Vector2 = Vector2(shockwave.process_material.scale_min, shockwave.process_material.scale_max)
#@onready var explosion_red_initial_velocity: Vector2 = Vector2(explosion_red.process_material.initial_velocity_min, explosion_red.process_material.initial_velocity_max)
#@onready var shockwave_initial_velocity: Vector2 = Vector2(shockwave.process_material.initial_velocity_min, shockwave.process_material.initial_velocity_min)

@onready var debris_initial_scale: Vector2 = Vector2(debris.process_material.scale_min, debris.process_material.scale_max)
@onready var debris_initial_velocity: Vector2 = Vector2(debris.process_material.initial_velocity_min, debris.process_material.initial_velocity_max)

@onready var explosion_red_initial_trail_lifetime: float = explosion_red.trail_lifetime

func _ready() -> void:
	anim_player.play("explosion")
	# Flash overbright al momento dell'esplosione
	modulate = Color(3.0, 3.0, 3.0, 1.0)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.12)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func scale_explosion(scale_factor: float) -> void:
	scale *= scale_factor

	explosion_red.process_material = explosion_red.process_material.duplicate()
	explosion_red.process_material.scale_min = explosion_red_initial_scale.x * scale_factor
	explosion_red.process_material.scale_max = explosion_red_initial_scale.y * scale_factor
	#explosion_red.process_material.initial_velocity_min = explosion_red_initial_velocity.x * scale_factor
	#explosion_red.process_material.initial_velocity_max = explosion_red_initial_velocity.y * scale_factor

	#explosion_red.trail_lifetime = explosion_red_initial_trail_lifetime * scale_factor

	shockwave.process_material = shockwave.process_material.duplicate()
	shockwave.process_material.scale_min = shockwave_initial_scale.y * scale_factor
	shockwave.process_material.scale_max = shockwave_initial_scale.y * scale_factor
	#shockwave.process_material.initial_velocity_min = shockwave_initial_velocity.x * scale_factor
	#shockwave.process_material.initial_velocity_max = shockwave_initial_velocity.y * scale_factor

	debris.process_material = debris.process_material.duplicate()
	debris.process_material.scale_min = debris_initial_scale.x * scale_factor
	debris.process_material.scale_max = debris_initial_scale.y * scale_factor
	debris.process_material.initial_velocity_min = debris_initial_velocity.x * scale_factor
	debris.process_material.initial_velocity_max = debris_initial_velocity.y * scale_factor
	debris.emitting = true


# Questo segnale deve essere collegato dal pannello "Nodi" dell'AnimationPlayer
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "explosion":
		queue_free()
