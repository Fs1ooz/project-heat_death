extends CelestialBody
class_name SmallBody

@export var min_speed: float = 100.0
@export var max_speed: float = 150.0
@export var spin_range: float = 2.0


func _ready() -> void:
	super()
	call_deferred("_kick")


func _kick() -> void:
	rotation = randf_range(0.0, TAU)
	var direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	var speed: float = randf_range(min_speed, max_speed)
	apply_impulse(direction * speed * mass)

	apply_torque_impulse(randf_range(-spin_range, spin_range) * inertia)
