extends Node2D

## Configurazione spawn con probabilità, cooldown e scaling
var spawn_config = [
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
		"min_probability": 30.0,
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

## Riferimento al giocatore
@export var player: Node2D

## Distanza spawn basata sulla posizione del player
@export var spawn_distance_min_multiplier: float = 1.2  # Quanto lontano minimo (moltiplicatore dello schermo)
@export var spawn_distance_max_multiplier: float = 1.8  # Quanto lontano massimo
@export var safe_zone_multiplier: float = 0.8  # Zona sicura (moltiplicatore dello schermo)

## Moltiplicatore difficoltà e tempo
var time_elapsed: float = 0.0
const DIFFICULTY_RAMP_TIME: float = 600.0

## Esponente per la curva (più alto = più esponenziale)
@export var difficulty_exponent: float = 3.0

func _ready() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	time_elapsed += delta

func _on_timer_timeout() -> void:
	var scene_to_spawn = get_weighted_random_scene()
	if scene_to_spawn == null:
		return

	var new_object = scene_to_spawn.instantiate()
	var spawn_pos = get_safe_spawn_position()
	new_object.global_position = spawn_pos

	await get_tree().create_timer(0.5).timeout
	get_parent().add_child(new_object)

func get_safe_spawn_position() -> Vector2:
	if player == null:
		return Vector2.ZERO

	# Ottieni la dimensione dello schermo in world coordinates
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return player.global_position + Vector2(1000, 0)

	# Calcola il raggio dello schermo basato sullo zoom
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_radius = (viewport_size.length() * 0.5) / camera.zoom.x

	# Calcola distanze di spawn basate sullo schermo
	var min_spawn_distance = screen_radius * spawn_distance_min_multiplier
	var max_spawn_distance = screen_radius * spawn_distance_max_multiplier

	# Spawn in un anello attorno al player
	var random_angle = randf() * TAU
	var random_distance = randf_range(min_spawn_distance, max_spawn_distance)

	var offset = Vector2(
		cos(random_angle) * random_distance,
		sin(random_angle) * random_distance
	)

	return player.global_position + offset

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
