extends Node2D

## =========================
## CONFIGURAZIONE
## =========================

@export var energy_scene: PackedScene = preload("res://Entities/EnergyDrop/energy_drop.tscn")
@export var player: Node2D

@export var max_energy: int = 300

## Spawn ring
@export var spawn_ring_min_distance: float = 900.0
@export var spawn_max_distance_multiplier: float = 30.0

## =========================
## STATO
## =========================

var time_elapsed: float = 0.0
@onready var spawn_timer: Timer = $Timer

## =========================
## LIFECYCLE
## =========================

func _ready() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	time_elapsed += delta


## =========================
## POSIZIONE SPAWN
## =========================

func get_dynamic_ring_spawn_position() -> Vector2:
	var screen_radius = get_screen_radius()

	var min_distance = spawn_ring_min_distance
	var max_distance = max(min_distance * 1.5, screen_radius * spawn_max_distance_multiplier)

	var angle = randf() * TAU
	var distance = randf_range(min_distance, max_distance)

	return player.global_position + Vector2(
		cos(angle) * distance,
		sin(angle) * distance
	)

func get_screen_radius() -> float:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return spawn_ring_min_distance * 2.0

	var viewport_size = get_viewport().get_visible_rect().size
	var world_width = viewport_size.x / camera.zoom.x
	var world_height = viewport_size.y / camera.zoom.y

	return sqrt(world_width * world_width + world_height * world_height) / 2.0

## =========================
## CLEANUP
## =========================

func cleanup_old_energy() -> void:
	var energies = get_tree().get_nodes_in_group("energy")
	if energies.size() <= max_energy:
		return

	energies.sort_custom(_sort_by_age)

	for i in range(energies.size() - max_energy):
		energies[i].queue_free()

func _sort_by_age(a, b) -> bool:
	return a._spawn_time < b._spawn_time


func _on_timer_timeout() -> void:
	if energy_scene == null or player == null:
		return

	# Prima fai il cleanup SE necessario
	var energies = get_tree().get_nodes_in_group("energy")
	if energies.size() >= max_energy:
		cleanup_old_energy()  # ← Rimuovi la più vecchia prima di spawnare

	# Poi spawna la nuova energia
	var energy = energy_scene.instantiate()
	energy.global_position = get_dynamic_ring_spawn_position()
	get_parent().add_child(energy)
