class_name CelestialBodySubViewport
extends SubViewport

@export var rotation_speed: float = 0.3

@export var mesh: MeshInstance3D

func _process(delta: float) -> void:
	mesh.rotate_y(delta * rotation_speed)
	if Engine.get_frames_drawn() % 2 == 0:
		render_target_update_mode = SubViewport.UPDATE_ONCE
