extends Node2D

## Configurazione spawn con probabilità, cooldown e scaling
var spawn_config = [
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/meteoroid.tscn"),
		"probability": 85.0,
		"min_probability": 5.0,
		"cooldown": 0,
		"current_cooldown": 0
	},
	{
		"scene": preload("res://Entities/EnergyDrop/energy_drop.tscn"),
		"probability": 14.0,
		"min_probability": 30.0,
		"cooldown": 0,
		"current_cooldown": 0
	},
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/comet.tscn"),
		"probability": 0.75,
		"min_probability": 25.0,
		"cooldown": 5,
		"current_cooldown": 0
	},
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/asteroid.tscn"),
		"probability": 0.25,
		"min_probability": 40.0,
		"cooldown": 8,
		"current_cooldown": 0
	},
]

## Riferimento al giocatore
@export var player: Node2D
## Raggio della zona sicura attorno al giocatore
@export var safe_zone_radius: float = 1000.0
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
	var max_attempts = 20
	var spawn_pos: Vector2

	for i in range(max_attempts):
		spawn_pos = Vector2(randf_range(-12200, 12200), randf_range(-12400, 12400))
		if player == null or spawn_pos.distance_to(player.global_position) > safe_zone_radius:
			return spawn_pos

	if player != null:
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		return player.global_position + direction * safe_zone_radius * 1.5

	return spawn_pos

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
