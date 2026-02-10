extends Node2D

## =========================
## CONFIGURAZIONE OGGETTI
## =========================

@export var spawn_config: Array[Dictionary] = [
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/meteoroid.tscn"),
		"weight": 90.0,
		"radius": 500.0 # 'R' (distanza minima Poisson)
	},
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/asteroid.tscn"),
		"weight": 9.99999,
		"radius": 35_000.0
	},
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/comet.tscn"),
		"weight": 0.00001,
		"radius": 200_000.0
	}
]


## =========================
## CONFIGURAZIONE AREA (RETTANGOLARE)
## =========================

@export_group("Area di Spawn")
@export var spawn_margin_inner: float = 1000.0  # Distanza minima dal bordo schermo
@export var spawn_margin_outer: float = 100_000.0 # Spessore della "cornice" di spawn

@export var despawn_buffer: float = 10000.0     # Quanto oltre la cornice distruggere l'oggetto

@export_group("Parametri Poisson")
@export var max_attempts: int = 5             # Il valore 'k' del video
@export var target_object_count: int = 200
@export var max_objects: int = target_object_count + 100

@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Player

var spawned_objects: Array = []

var spawn_interval: float = 0.01
var spawn_timer: float = spawn_interval


func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_on_timer_timeout()
		spawn_timer += spawn_interval


func _on_timer_timeout() -> void:
	if not is_instance_valid(player):
		return

	update_game_stage()
	cleanup_objects()
	var current_count: int = spawned_objects.size()
	if current_count < target_object_count:
		var to_spawn: int = min(5, target_object_count - current_count)
		for i: int in range(to_spawn):
			spawn_object_poisson()


## =========================
## CONFIGURAZIONE STADI (MATCH MASSA)
## =========================

# Definiamo i pesi per ogni stadio basati sulla massa del player
# Formato: massa_minima: [peso_meteoroid, peso_asteroid, peso_comet]
enum GameStage { METEROIDS, ASTEROIDS, SATELLITES, PLANETS, STARS }
var current_stage: GameStage = GameStage.METEROIDS

## Ritorna i pesi per [Meteoroidi, Asteroidi, Comete]
func get_weights_for_current_stage() -> Array[float]:
	match current_stage:
		GameStage.METEROIDS:  return [90.0, 10.0, 0.0]  # Solo polvere
		GameStage.ASTEROIDS:  return [54.0, 45.0, 1.0]  # Iniziano i primi asteroidi
		GameStage.SATELLITES: return [0.0, 60.0, 10.0] # Comete/Satelliti diventano visibili
		GameStage.PLANETS:    return [0.0, 20.0, 20.0] # Predominanza di oggetti grandi
		GameStage.STARS:      return [0.0, 10.0, 10.0]  # Quasi solo oggetti massicci
		_: return [1.0, 0.0, 0.0]



## Ritorna i pesi per [Meteoroidi, Asteroidi, Comete]
## NOTA: Se la somma < 100, il resto è probabilità di NON spawn

func update_game_stage() -> void:
	if not is_instance_valid(player): return

	var m: float = player.mass
	var old_stage: GameStage = current_stage

	# Soglie di massa (modifica i numeri in base al tuo bilanciamento)
	if m < 20:
		current_stage = GameStage.METEROIDS
	elif m < 500:
		current_stage = GameStage.ASTEROIDS
	elif m < 2000:
		current_stage = GameStage.SATELLITES
	elif m < 10000:
		current_stage = GameStage.PLANETS
	else:
		current_stage = GameStage.STARS

	if old_stage != current_stage:
		_on_stage_changed()

func _on_stage_changed() -> void:
	print("EVOLUZIONE: ", GameStage.keys()[current_stage])
	# Qui puoi aggiungere effetti: zoom camera, cambio musica, ecc.



## =========================
## LOGICA POISSON (DISTRIBUZIONE)
## =========================

func spawn_object_poisson() -> void:
	var data: Dictionary = get_random_spawn_data()

	if data == {}:
		print("non spawnare un caz")
		return

	var r: float = data["radius"]

	# Trova una posizione nella cornice rettangolare che rispetti la distanza 'r'
	var spawn_pos: Vector2 = find_valid_rectangular_pos(r)

	if spawn_pos != Vector2.ZERO:
		var instance: Node2D = data["scene"].instantiate() as Node2D
		instance.global_position = spawn_pos
		instance.set_meta("poisson_radius", r)
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
	# 1) controllo fisico (opzionale)
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius

	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, pos)
	query.collision_mask = 2

	if not space_state.intersect_shape(query).is_empty():
		return false

	# 2) controllo MANUALE Poisson (quello che manca)
	for obj: Node2D in spawned_objects:
		if not is_instance_valid(obj):
			continue

		var other_radius: float = 0.0
		if obj.has_meta("poisson_radius"):
			other_radius = obj.get_meta("poisson_radius")

		if pos.distance_to(obj.global_position) < radius + other_radius:
			return false

	return true


## =========================
## UTILITY
## =========================

func get_random_spawn_data() -> Dictionary: # Tolto il tipo Dictionary per permettere null
	var weights: Array = get_weights_for_current_stage()

	# Lanciamo il dado su base 100 (probabilità assoluta)
	var roll: float = randf() * 100.0
	var cursor: float = 0.0

	for i: int in range(spawn_config.size()):
		var weight: float = weights[i] if i < weights.size() else 0.0
		cursor += weight
		if roll <= cursor:
			return spawn_config[i]

	# Se il roll è tra la somma dei pesi e 100, non spawnare nulla
	return {}

func cleanup_objects() -> void:
	spawned_objects = spawned_objects.filter(is_instance_valid)

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
