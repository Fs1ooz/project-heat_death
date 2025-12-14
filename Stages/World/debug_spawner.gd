extends Node2D

## Configurazione spawn con probabilità, cooldown e scaling
@export var spawn_config = [
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/meteoroid.tscn"),
		"probability": 0.0,
		"min_probability": 0.0,
		"cooldown": 0,
		"current_cooldown": 0
	},
	{
		"scene": preload("res://Entities/EnergyDrop/energy_drop.tscn"),
		 "probability": 100.0,
		"min_probability": 50.0,
		"cooldown": 0,
		"current_cooldown": 0
	},
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/comet.tscn"),
		"probability": 0.0,
		"min_probability": 0.0,
		"cooldown": 5,
		"current_cooldown": 0
	},
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/asteroid.tscn"),
		"probability": 0.0,
		"min_probability": 0.0,
		"cooldown": 8,
		"current_cooldown": 0
	},
]


var max_energy: int = 10000
## Riferimento al giocatore
@export var player: Node2D

## Distanza minima FISSA in pixel dal player (zona "sicura")
@export var spawn_ring_min_distance: float = 800.0

## Moltiplicatore per la distanza massima basata su ciò che vede il player
@export var spawn_max_distance_multiplier: float = 3.0

## Moltiplicatore difficoltà e tempo
var time_elapsed: float = 0.0
const DIFFICULTY_RAMP_TIME: float = 600.0
@export var difficulty_exponent: float = 3.0

func _ready() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	time_elapsed += delta

func _on_timer_timeout() -> void:
	if get_tree().get_nodes_in_group("energy").size() > max_energy:
		return
	var scene_to_spawn = get_weighted_random_scene()
	if scene_to_spawn == null:
		return

	var new_object = scene_to_spawn.instantiate()
	var spawn_pos = get_dynamic_ring_spawn_position()
	new_object.global_position = spawn_pos
	cleanup_old_energy()


	await get_tree().create_timer(0.5).timeout
	get_parent().add_child(new_object)

func get_dynamic_ring_spawn_position() -> Vector2:
	if player == null:
		return Vector2.ZERO

	# Calcola la distanza massima basata su ciò che vede il player
	var screen_radius = get_screen_radius()
	var max_distance = max(spawn_ring_min_distance * 1.5, screen_radius * spawn_max_distance_multiplier)
	var min_distance = spawn_ring_min_distance

	# Spawn in un anello con distanze min/max
	var random_angle = randf() * TAU
	var random_distance = randf_range(min_distance, max_distance)

	var offset = Vector2(
		cos(random_angle) * random_distance,
		sin(random_angle) * random_distance
	)

	#print (player.global_position)
	return player.global_position + offset

func get_screen_radius() -> float:
	# Ottieni la camera e le dimensioni del viewport
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return spawn_ring_min_distance * 2  # Fallback

	var viewport_size = get_viewport().get_visible_rect().size

	# Calcola il raggio dello schermo visibile in world coordinates
	var screen_width_world = viewport_size.x / camera.zoom.x
	var screen_height_world = viewport_size.y / camera.zoom.y

	# Usa la metà della diagonale come raggio massimo
	var screen_radius = sqrt(screen_width_world * screen_width_world + screen_height_world * screen_height_world) / 2

	return screen_radius

func get_weighted_random_scene() -> PackedScene:
	# Riduci cooldown
	for config in spawn_config:
		if config.current_cooldown > 0:
			config.current_cooldown -= 1

	# Calcola progresso ESPONENZIALE (0.0 a 1.0)
	var linear_progress = min(time_elapsed / DIFFICULTY_RAMP_TIME, 1.0)
	var progress = pow(linear_progress, difficulty_exponent)

	# Filtra spawn disponibili
	var available_spawns = []
	var total_weight = 0.0

	for config in spawn_config:
		if config.current_cooldown <= 0:
			var current_prob = lerp(config.probability, config.min_probability, progress)
			available_spawns.append({"config": config, "weight": current_prob})
			total_weight += current_prob

	if available_spawns.is_empty():
		return null

	# Selezione pesata
	var random_value = randf() * total_weight
	var cumulative = 0.0

	for spawn in available_spawns:
		cumulative += spawn.weight
		if random_value < cumulative:
			spawn.config.current_cooldown = spawn.config.cooldown
			return spawn.config.scene

	return available_spawns[0].config.scene


# Assicurati che tutti i pellet di energia siano nel gruppo "energy"

func cleanup_old_energy() -> void:
	var energies = get_tree().get_nodes_in_group("energy")
	if energies.size() <= max_energy:
		return

	# Ordina per tempo di creazione (supponendo che tu abbia aggiunto un timestamp)
	energies.sort_custom(_sort_by_age)

	# Rimuovi quelli extra
	for i in range(energies.size() - max_energy):
		energies[i].queue_free()

# Funzione di ordinamento basata su variabile _spawn_time
func _sort_by_age(a, b):
	return int(a._spawn_time - b._spawn_time)
