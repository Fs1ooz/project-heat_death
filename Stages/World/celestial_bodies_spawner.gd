extends Node2D

## =========================
## CONFIGURAZIONE OGGETTI
## =========================

@export var spawn_config: Array[Dictionary] = [
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/meteoroid.tscn"),
		"weight": 80.0,
		"radius": 15_000.0 # 'R' (distanza minima Poisson)
	},
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/asteroid.tscn"),
		"weight": 20.0,
		"radius": 200_000.0
	},
	#{
		#"scene": preload("res://Entities/Enemies/SmallBodies/comet.tscn"),
		#"weight": 0.0,
		#"radius": 60_000.0
	#}
]

## =========================
## CONFIGURAZIONE AREA (RETTANGOLARE)
## =========================

@export_group("Area di Spawn")
@export var spawn_margin_inner: float = 500.0  # Distanza minima dal bordo schermo
@export var spawn_margin_outer: float = 500_000.0 # Spessore della "cornice" di spawn

@export var despawn_buffer: float = 10000.0     # Quanto oltre la cornice distruggere l'oggetto

@export_group("Parametri Poisson")
@export var max_attempts: int = 10             # Il valore 'k' del video
@export var target_object_count: int = 500
@export var max_objects: int = 800

@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D

var spawned_objects: Array[Node2D] = []

var spawn_interval: float = 0.01  # intervallo desiderato
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
	var camera = get_viewport().get_camera_2d()

	# Calcoliamo le dimensioni attuali della vista (adattive allo zoom)
	var view_size = get_viewport_rect().size
	if camera:
		view_size /= camera.zoom

	# Definiamo i limiti della cornice attorno al player/camera
	var center = player.global_position
	var inner_w = (view_size.x / 2) + spawn_margin_inner
	var inner_h = (view_size.y / 2) + spawn_margin_inner
	var outer_w = inner_w + spawn_margin_outer
	var outer_h = inner_h + spawn_margin_outer

	# Proviamo 'k' volte come nel video
	for i in range(max_attempts):
		var candidate_pos: Vector2 = Vector2.ZERO
		var side = randi() % 4

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
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius # Questo garantisce la distanza minima tra oggetti

	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collision_mask = 2 # Deve corrispondere al collision layer dei tuoi asteroidi

	var result = space_state.intersect_shape(query)
	return result.is_empty()

## =========================
## UTILITY
## =========================

func get_random_spawn_data() -> Dictionary:
	var total_weight: float = 0.0
	for item in spawn_config: total_weight += item["weight"]
	var roll: float = randf() * total_weight
	var cursor: float = 0.0
	for item in spawn_config:
		cursor += item["weight"]
		if roll <= cursor: return item
	return spawn_config[0]

func cleanup_objects() -> void:
	spawned_objects = spawned_objects.filter(func(obj): return is_instance_valid(obj))

	var view_size = get_viewport_rect().size
	var camera = get_viewport().get_camera_2d()
	if camera: view_size /= camera.zoom

	# Soglia di rimozione: oltre il margine esterno + buffer
	var limit_x = (view_size.x / 2) + spawn_margin_inner + spawn_margin_outer + despawn_buffer
	var limit_y = (view_size.y / 2) + spawn_margin_inner + spawn_margin_outer + despawn_buffer

	var objects_to_remove: Array[Node2D] = []
	for obj in spawned_objects:
		var diff = (obj.global_position - player.global_position).abs()
		if diff.x > limit_x or diff.y > limit_y:
			objects_to_remove.append(obj)

	for obj in objects_to_remove:
		spawned_objects.erase(obj)
		obj.queue_free()
