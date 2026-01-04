extends Node2D
## =========================
## CONFIGURAZIONE
## =========================
@export var energy_scene: PackedScene = preload("res://Entities/EnergyDrop/energy_drop.tscn")
@onready var player: Player = get_tree().get_first_node_in_group("player")
@export var max_energy: int = 500
## Spawn ring
@export var spawn_ring_min_distance: float = 800.0
@export var spawn_max_distance_multiplier: float = 30.0
## =========================
## STATO
## =========================
var time_elapsed: float = 0.0
var counter: int = 0
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
	var screen_radius: float = get_screen_radius()
	var min_distance: float = spawn_ring_min_distance
	var max_distance: float = max(min_distance * 1.5, screen_radius * spawn_max_distance_multiplier)
	var angle: float = randf() * TAU
	var distance: float = randf_range(min_distance, max_distance)
	return player.global_position + Vector2(
		cos(angle) * distance,
		sin(angle) * distance
	)
func get_screen_radius() -> float:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return spawn_ring_min_distance * 2.0
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var world_width: float = viewport_size.x / camera.zoom.x
	var world_height: float = viewport_size.y / camera.zoom.y
	return sqrt(world_width * world_width + world_height * world_height) / 2.0
## =========================
## CLEANUP
## =========================
func cleanup_old_energy() -> void:
	var energies: Array = get_tree().get_nodes_in_group("energy")
	if energies.size() <= max_energy:
		return
	energies.sort_custom(_sort_by_age)
	for i: int in range(energies.size() - max_energy):
		energies[i].queue_free()
func _sort_by_age(a: EnergyDrop, b: EnergyDrop) -> bool:
	return a._spawn_time < b._spawn_time
## =========================
## SPAWN
## =========================
func _on_timer_timeout() -> void:
	if energy_scene == null or player == null:
		return
	counter += 1

	# Cleanup ogni max_energy spawn
	if counter >= max_energy:
		cleanup_old_energy()
		counter = 0  # ← Reset del counter

	# Spawna nuova energia
	var energy: EnergyDrop = energy_scene.instantiate()
	energy.global_position = get_dynamic_ring_spawn_position()
	get_parent().add_child(energy)
