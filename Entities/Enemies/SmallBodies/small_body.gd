class_name SmallBody
extends CelestialBody

@export var min_size: float = 1.0
@export var max_size: float = 2.7


func _ready() -> void:
	_setup_random_scale()
	super()


func _setup_random_scale() -> void:
	var scale_rand: float = randf_range(min_size, max_size)
	print(scale_rand)
	_setup_scale(scale_rand)
