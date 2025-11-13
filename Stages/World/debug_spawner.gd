extends Node

## Array di scene da spawnare
var celestial_bodies: Array[PackedScene] = [
	preload("res://Entities/Enemies/RockyPlanets/rocky_planet.tscn"),
	preload("res://Entities/Enemies/SBs/asteroids.tscn")
]

func _on_timer_timeout() -> void:

	var scene_to_spawn = celestial_bodies[randi() % celestial_bodies.size()]
	var new_object = scene_to_spawn.instantiate()

	new_object.global_position = Vector2(
		randf_range(-1200, 1200),
		randf_range(-1400, -1200)
	)
	get_tree().get_root().add_child(new_object)
