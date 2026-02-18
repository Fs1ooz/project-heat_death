class_name KickComponent
extends Node

@export var body: CelestialBody

@export var min_speed: float = 1.0
@export var max_speed: float = 1.5


enum KickMode { POSITION, ROTATION }

func kick_position() -> Vector2:
	var direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0.0, TAU)).normalized()
	var speed: float = randf_range(min_speed, max_speed)
	body.apply_impulse(direction * speed * body.mass / 2)
	return direction

func kick_rotation() -> void:
	body.rotation = randf_range(0.0, TAU)
	body.angular_velocity = randf_range(0.0, 0.1)
