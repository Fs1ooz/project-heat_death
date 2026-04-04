class_name CelestialBodySubViewport
extends SubViewport

@export var rotation_speed: float = 0.3

@export var mesh: MeshInstance3D

func _process(delta: float) -> void:
	mesh.rotate_y(delta * rotation_speed)
