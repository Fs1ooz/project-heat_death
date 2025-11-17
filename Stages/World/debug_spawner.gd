extends Node2D

## Array di scene da spawnare (ordinate per probabilità decrescente)
var celestial_bodies: Array[PackedScene] = [
	preload("res://Entities/Enemies/SmallBodies/asteroids.tscn"),
	preload("res://Entities/Enemies/RockyPlanets/rocky_planet.tscn"),
]

## Pesi per ogni scena (più alto = più probabilità)
var spawn_weights: Array[int] = [99, 1]


func _ready() -> void:
	# Verifica che ci siano tanti pesi quante scene
	assert(celestial_bodies.size() == spawn_weights.size(), "Il numero di pesi deve corrispondere al numero di scene!")

func _on_timer_timeout() -> void:
	var scene_to_spawn = get_weighted_random_scene()
	var new_object = scene_to_spawn.instantiate()

	var spawn_pos = Vector2(randf_range(-3200, 3200), randf_range(-2400, 2200))
	new_object.global_position = spawn_pos
	await get_tree().create_timer(0.5).timeout

	get_parent().add_child(new_object)


## Seleziona una scena basandosi sui pesi
func get_weighted_random_scene() -> PackedScene:
	# Calcola il peso totale
	var total_weight = 0
	for weight in spawn_weights:
		total_weight += weight

	# Genera un numero casuale tra 0 e il peso totale
	var random_value = randi() % total_weight

	# Trova quale scena corrisponde a questo valore
	var cumulative_weight = 0
	for i in range(celestial_bodies.size()):
		cumulative_weight += spawn_weights[i]
		if random_value < cumulative_weight:
			return celestial_bodies[i]

	# Fallback (non dovrebbe mai arrivare qui)
	return celestial_bodies[0]
