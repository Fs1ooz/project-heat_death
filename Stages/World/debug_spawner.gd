extends Node2D

## Configurazione spawn con probabilità, cooldown e scaling
var spawn_config = [
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/meteoroid.tscn"),
		"probability": 85.0,
		"cooldown": 0,
		"current_cooldown": 0
	},
	{
		"scene": preload("res://Entities/EnergyDrop/energy_drop.tscn"),
		"probability": 14.0,
		"cooldown": 0,
		"current_cooldown": 0
	},
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/comet.tscn"),
		"probability": 0.75,
		"cooldown": 5,
		"current_cooldown": 0
	},
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/asteroid.tscn"),
		"probability": 0.25,
		"cooldown": 8,
		"current_cooldown": 0
	},
]

## Moltiplicatore che aumenta nel tempo (5 minuti = 300 secondi)
var difficulty_multiplier: float = 1.0
var time_elapsed: float = 0.0
const DIFFICULTY_RAMP_TIME: float = 300.0  # 5 minuti
const MAX_DIFFICULTY_MULTIPLIER: float = 2.0  # Raddoppia le probabilità dopo 5 min

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# Aumenta gradualmente la difficoltà nel tempo
	time_elapsed += delta
	difficulty_multiplier = lerp(1.0, MAX_DIFFICULTY_MULTIPLIER,
		min(time_elapsed / DIFFICULTY_RAMP_TIME, 1.0))

func _on_timer_timeout() -> void:
	var scene_to_spawn = get_weighted_random_scene()
	if scene_to_spawn == null:
		return  # Nessuno spawn disponibile (tutti in cooldown)

	var new_object = scene_to_spawn.instantiate()
	var spawn_pos = Vector2(randf_range(-9200, 9200), randf_range(-6400, 6400))
	new_object.global_position = spawn_pos

	await get_tree().create_timer(0.5).timeout
	get_parent().add_child(new_object)

func get_weighted_random_scene() -> PackedScene:
	# Riduci cooldown di tutti gli oggetti
	for config in spawn_config:
		if config.current_cooldown > 0:
			config.current_cooldown -= 1

	# Filtra solo gli spawn disponibili (cooldown = 0)
	var available_spawns = []
	var total_weight = 0.0

	for config in spawn_config:
		if config.current_cooldown <= 0:
			# Applica il moltiplicatore di difficoltà
			var adjusted_prob = config.probability * difficulty_multiplier
			available_spawns.append({"config": config, "weight": adjusted_prob})
			total_weight += adjusted_prob

	if available_spawns.is_empty():
		return null  # Nessuno spawn disponibile

	# Seleziona casualmente basandosi sui pesi
	var random_value = randf() * total_weight
	var cumulative = 0.0

	for spawn in available_spawns:
		cumulative += spawn.weight
		if random_value < cumulative:
			# Imposta il cooldown per questo tipo di spawn
			spawn.config.current_cooldown = spawn.config.cooldown
			return spawn.config.scene

	# Fallback
	return available_spawns[0].config.scene
