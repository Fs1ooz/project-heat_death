extends Node2D

signal ceres_should_spawn

## =========================
## CONFIGURAZIONE OGGETTI
## =========================

@export var spawn_config: Array[Dictionary] = [
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/Meteoroids/meteoroid.tscn"),
		"radius": 500.0 # 'R' (distanza minima Poisson)
	},
	{
		"scene": preload("res://Entities/Enemies/SmallBodies/Asteroids/asteroid.tscn"),
		"radius": 30_000.0
	},
	{
		"scene":preload("uid://8aj1dylerrl1"),
		"radius": 45_000.0
	}
]

## =========================
## CONFIGURAZIONE AREA (RETTANGOLARE)
## =========================

@export_group("Area di Spawn")
@export var spawn_margin_inner: float = 1000.0  # Distanza minima dal bordo schermo
@export var spawn_margin_outer: float = 50_000.0 # Spessore della "cornice" di spawn

@export var despawn_buffer: float = 5000.0     # Quanto oltre la cornice distruggere l'oggetto

@export_group("Parametri Poisson")
@export var max_attempts: int = 3             # Il valore 'k' del video
@export var target_object_count: int = 250
@export var max_objects: int = target_object_count + 50

@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Player

var spawned_objects: Array = []
var _ceres: Ceres = null

var spawn_interval: float = 0.01
var spawn_timer: float = spawn_interval

var _spawn_shape: CircleShape2D
var _spawn_query: PhysicsShapeQueryParameters2D

func _ready() -> void:
	UpgradeManager.tier_changed.connect(next_game_stage)
	GlobalSignals.ceres_spawned.connect(func(c: Node) -> void: _ceres = c as Ceres)
	_spawn_shape = CircleShape2D.new()
	_spawn_query = PhysicsShapeQueryParameters2D.new()
	_spawn_query.shape = _spawn_shape
	_spawn_query.collision_mask = 2


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
## CONFIGURAZIONE STADI (MATCH MASSA)
## =========================

# Definiamo i pesi per ogni stadio basati sulla massa del player
# Formato: massa_minima: [peso_meteoroid, peso_asteroid, peso_comet]


# 1. Definiamo l'Enum (I nomi devono essere coerenti)
enum GameStage {
	METEROIDS_1,
	METEROIDS_2,
	METEROIDS_3,
	ASTEROIDS_1,
	ASTEROIDS_2,
	ASTEROIDS_3,
	ASTEROIDS_4,
	ASTEROIDS_5,
	ASTEROIDS_6,
	ASTEROIDS_7,
	A,
	B,
	C,
	D,
	E,
	F,
}

# 2. Il "Dizionario-Corpo" (Sostituisce la logica Java)
const STAGE_DATA: Dictionary = {
	GameStage.METEROIDS_1: {
		"weights": [80.0, 15.0, 0.0],
		"label": "Polvere Spaziale"
	},
	GameStage.METEROIDS_2: {
		"weights": [50.0, 35.0, 0.0],
		"label": "Piccoli Detriti"
	},
	GameStage.METEROIDS_3: {
		"weights": [20.0, 50.0, 0.0],
		"label": "Fascia di Meteoroidi"
	},
	GameStage.ASTEROIDS_1: {
		"weights": [5.0, 40.0, 0.5],
		"label": "Primi Asteroidi"
	},
	GameStage.ASTEROIDS_2: {
		"weights": [2.0, 20.0, 2.0],
		"label": "Pioggia Rocciosa"
	},
	GameStage.ASTEROIDS_3: {
		"weights": [0.0, 10.0, 3.0],
		"label": "Pericolo Impatto"
	}
}


var current_stage: GameStage = GameStage.METEROIDS_1

func get_weights_for_current_stage() -> Array:
	# Invece del match, fai un accesso diretto al "finto enum"
	return STAGE_DATA[current_stage]["weights"]



func next_game_stage() -> void:
	if not is_instance_valid(player): return
	# STAGE_DATA definisce i pesi solo fino ad ASTEROIDS_3: l'enum GameStage ha più voci, ma oltre
	# l'ultimo stadio configurato non esistono pesi → clamp per evitare "Out of bounds" in
	# get_weights_for_current_stage. (STAGE_DATA usa chiavi contigue da 0, quindi size-1 = ultimo.)
	var last_stage: int = STAGE_DATA.size() - 1
	var prev_stage: int = current_stage
	current_stage = mini(current_stage + 1, last_stage) as GameStage
	if current_stage == GameStage.ASTEROIDS_3 and prev_stage != GameStage.ASTEROIDS_3:
		ceres_should_spawn.emit()


## =========================
## LOGICA POISSON (DISTRIBUZIONE)
## =========================

func spawn_object_poisson() -> void:
	var data: Dictionary = get_random_spawn_data()

	if data == {}:
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
		instance.tree_exiting.connect(func() -> void: spawned_objects.erase(instance))

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
	# 1) controllo fisico
	_spawn_shape.radius = radius
	_spawn_query.transform = Transform2D(0.0, pos)

	if not space_state.intersect_shape(_spawn_query).is_empty():
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

	# 3) zona esclusiva di Ceres: niente spawn nel suo campo gravitazionale
	if is_instance_valid(_ceres):
		if pos.distance_to(_ceres.global_position) < _ceres.get_gravity_radius():
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

	for obj: Node2D in spawned_objects:
		var diff: Vector2 = (obj.global_position - player.global_position).abs()
		if diff.x > limit_x or diff.y > limit_y:
			obj.queue_free()  # tree_exiting rimuove automaticamente da spawned_objects
