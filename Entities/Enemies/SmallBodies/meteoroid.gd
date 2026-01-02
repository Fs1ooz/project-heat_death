extends SmallBody
class_name Meteoroid

@export var min_speed: float = 1.5
@export var max_speed: float = 3.0


func _ready() -> void:
	call_deferred("_kick")
	super()


func _kick() -> void:
	var direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0.0, TAU)).normalized()
	var speed: float = randf_range(min_speed, max_speed)
	apply_impulse(direction * speed * mass)
