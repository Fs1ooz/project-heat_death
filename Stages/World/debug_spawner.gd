extends Node2D

## Array di scene da spawnare
var celestial_bodies: Array[PackedScene] = [
	preload("res://Entities/Enemies/RockyPlanets/rocky_planet.tscn"),
	preload("res://Entities/Enemies/SBs/asteroids.tscn")
]

func _on_timer_timeout() -> void:
	var scene_to_spawn = celestial_bodies[randi() % celestial_bodies.size()]
	var new_object = scene_to_spawn.instantiate()

	var space_state = get_world_2d().direct_space_state
	var max_attempts = 10
	var spawn_pos = Vector2.ZERO
	var valid_position = false

	for i in max_attempts:
		spawn_pos = Vector2(
			randf_range(-5200, 5200),
			randf_range(-3400, 3200)
		)

		# Controlla se c'è qualcosa nella posizione
		var query = PhysicsPointQueryParameters2D.new()
		query.position = spawn_pos
		query.collision_mask = 0b1  # o la maschera che usi per i corpi solidi

		var result = space_state.intersect_point(query)

		if result.is_empty():
			valid_position = true
			break

	if valid_position:
		new_object.global_position = spawn_pos
		get_tree().get_root().add_child(new_object)
	else:
		print("Non è stato trovato uno spazio libero per lo spawn.")
