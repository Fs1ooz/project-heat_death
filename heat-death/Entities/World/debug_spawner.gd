extends Node

# Array di scene da spawnare
var celestial_bodies: Array[PackedScene] = [
	preload("res://Entities/Enemies/RockyPlanets/rocky_planet.tscn"),
	preload("res://Entities/Enemies/SBs/asteroids.tscn")
]

func _on_timer_timeout() -> void:
	printerr("Spawnato")

	# Scegli casualmente una scena dall'array
	var scene_to_spawn = celestial_bodies[randi() % celestial_bodies.size()]
	var new_object = scene_to_spawn.instantiate()

	# Posizione casuale
	new_object.global_position = Vector2(
		randf_range(-200, 200),
		randf_range(-400, -200)
	)

	get_tree().get_root().add_child(new_object)
