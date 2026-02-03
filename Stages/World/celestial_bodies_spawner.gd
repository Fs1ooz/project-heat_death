extends Node2D

## =========================
## CONFIGURAZIONE OGGETTI
## =========================

@export var spawn_config: Array[Dictionary] = [
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/meteoroid.tscn"),
		"weight": 95.0,
		"radius": 10_000.0 # 'R' (distanza minima Poisson)
	},
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/asteroid.tscn"),
		"weight": 4.99999,
		"radius": 300_000.0
	},
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/comet.tscn"),
		"weight": 0.00001,
		"radius": 800_000.0
	}
]

## =========================
## CONFIGURAZIONE AREA (RETTANGOLARE)
## =========================

@export_group("Area di Spawn")
@export var spawn_margin_inner: float = 1000.0  # Distanza minima dal bordo schermo
@export var spawn_margin_outer: float = 300_000.0 # Spessore della "cornice" di spawn

@export var despawn_buffer: float = 10000.0     # Quanto oltre la cornice distruggere l'oggetto

@export_group("Parametri Poisson")
@export var max_attempts: int = 3             # Il valore 'k' del video
@export var target_object_count: int = 500
@export var max_objects: int = 800

@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Player

var spawned_objects: Array = []

var spawn_interval: float = 0.0000001
var spawn_timer: float = spawn_interval


func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_on_timer_timeout()
		spawn_timer += spawn_interval


func _on_timer_timeout() -> void:
	if not is_instance_valid(player):
		return
	cleanup_objects()
	var current_count: int = spawned_objects.size()
	if current_count < target_object_count:
		var to_spawn: int = min(5, target_object_count - current_count)
		for i: int in range(to_spawn):
			spawn_object_poisson()

## =========================
## LOGICA POISSON (DISTRIBUZIONE)
## =========================

func spawn_object_poisson() -> void:
	var data: Dictionary = get_random_spawn_data()
	var r: float = data["radius"]

	# Trova una posizione nella cornice rettangolare che rispetti la distanza 'r'
	var spawn_pos: Vector2 = find_valid_rectangular_pos(r)

	if spawn_pos != Vector2.ZERO:
		var instance: Node2D = data["scene"].instantiate() as Node2D
		instance.global_position = spawn_pos

		# Aggiungi al parent (es. il mondo di gioco) per non farlo muovere con lo spawner
		get_parent().add_child(instance)
		spawned_objects.append(instance)

func find_valid_rectangular_pos(radius: float) -> Vector2:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var camera: Camera2D = get_viewport().get_camera_2d()

	# Calcoliamo le dimensioni attuali della vista (adattive allo zoom)
	var view_size: Vector2 = get_viewport_rect().size
	if camera:
		view_size /= camera.zoom

	# Definiamo i limiti della cornice attorno al player/camera
	var center: Vector2 = player.global_position
	var inner_w: float  = (view_size.x / 2) + spawn_margin_inner
	var inner_h: float = (view_size.y / 2) + spawn_margin_inner
	var outer_w: float  = inner_w + spawn_margin_outer
	var outer_h: float  = inner_h + spawn_margin_outer

	# Proviamo 'k' volte come nel video
	for i: int in range(max_attempts):
		var candidate_pos: Vector2 = Vector2.ZERO
		var side: int = randi() % 4

		# Scegliamo un punto casuale in uno dei 4 rettangoli della cornice
		match side:
			0: # SOPRA
				candidate_pos.x = randf_range(center.x - outer_w, center.x + outer_w)
				candidate_pos.y = randf_range(center.y - outer_h, center.y - inner_h)
			1: # SOTTO
				candidate_pos.x = randf_range(center.x - outer_w, center.x + outer_w)
				candidate_pos.y = randf_range(center.y + inner_h, center.y + outer_h)
			2: # SINISTRA
				candidate_pos.x = randf_range(center.x - outer_w, center.x - inner_w)
				candidate_pos.y = randf_range(center.y - outer_h, center.y + outer_h)
			3: # DESTRA
				candidate_pos.x = randf_range(center.x + inner_w, center.x + outer_w)
				candidate_pos.y = randf_range(center.y - outer_h, center.y + outer_h)

		# Controllo Poisson: non deve esserci nulla nel raggio 'radius'
		if is_position_empty(candidate_pos, radius, space_state):
			return candidate_pos

	return Vector2.ZERO

func is_position_empty(pos: Vector2, radius: float, space_state: PhysicsDirectSpaceState2D) -> bool:
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius

	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, pos)
	query.collision_mask = 2

	var result: Array[Dictionary] = space_state.intersect_shape(query)
	return result.is_empty()

## =========================
## UTILITY
## =========================

func get_random_spawn_data() -> Dictionary:
	var total_weight: float = 0.0
	for item: Dictionary in spawn_config:
		total_weight += item["weight"] as float

	var roll: float = randf() * total_weight
	var cursor: float = 0.0

	for item: Dictionary in spawn_config:
		cursor += item["weight"] as float
		if roll <= cursor:
			return item

	return spawn_config[0]

func cleanup_objects() -> void:
	spawned_objects = spawned_objects.filter(
		func(obj: Node2D) -> bool:
			return is_instance_valid(obj)
	)

	var view_size: Vector2 = get_viewport_rect().size
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera:
		view_size /= camera.zoom

	var limit_x: float = (view_size.x * 0.5) + spawn_margin_inner + spawn_margin_outer + despawn_buffer
	var limit_y: float = (view_size.y * 0.5) + spawn_margin_inner + spawn_margin_outer + despawn_buffer

	var to_remove: Array = []

	for obj: Node2D in spawned_objects:
		var diff: Vector2 = (obj.global_position - player.global_position).abs()
		if diff.x > limit_x or diff.y > limit_y:
			to_remove.append(obj)

	for obj: Node2D in to_remove:
		spawned_objects.erase(obj)
		obj.queue_free()
