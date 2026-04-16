class_name Asteroid
extends SmallBody

enum SizeStage { LARGE, MEDIUM, SMALL, METEOROID }

# Configurazioni centralizzate per ogni stadio
const STAGE_CONFIG: Dictionary = {
	SizeStage.LARGE: {
		"next_stage": SizeStage.MEDIUM,
		"fragments": 2,
		"min_size": 123.0,
		"max_size": 125.0,
		"internal_energy": 1,
		"impulse": 10000,
	},
	SizeStage.MEDIUM: {
		"next_stage": SizeStage.SMALL,
		"fragments": 2,
		"min_size": 57.5,
		"max_size": 60.0,
		"internal_energy": 1,
		"impulse": 4000,
	},
	SizeStage.SMALL: {
		"next_stage": SizeStage.METEOROID, # Ora punta a meteoroid
		"fragments": 4, # Magari ne spawna tanti piccoli
		"min_size": 25.0,
		"max_size": 30.0,
		"internal_energy": 1,
		"impulse": 1000,
	},
	SizeStage.METEOROID: {
		"next_stage": null,
		"fragments": 0,
	},
}
@onready var kick_component: KickComponent = %KickComponent
@onready var outgassing_component: OutgassingComponent = %OutgassingComponent


const ASTEROID_SCENE_PATH: String = "res://Entities/Enemies/SmallBodies/asteroid.tscn"
const METEOROID_SCENE_PATH: String = "res://Entities/Enemies/SmallBodies/meteoroid.tscn"

const FRAGMENT_SPAWN_OFFSET: float = 70.0


@export var current_stage: SizeStage = SizeStage.LARGE
@export var randomize_stage: bool = true


var _asteroid_scene: PackedScene = null
var _meteoroid_scene: PackedScene = null


# Sostituisci gasses: Array con un array tipizzato
var gasses: Array[Gas] = []

func _ready() -> void:
	_load_scenes()
	if randomize_stage:
		_initialize_random_stage()
	_apply_stage_configuration()
	super()
	kick_component.kick_position()
	kick_component.kick_rotation()
	outgassing_component.setup(self, sprite)
	outgassing_component.prespawn(spawn_points.size())


func _on_entropy_changed(entropy: float) -> void:
	if entropy < ENTROPY_THRESHOLD:
		last_spawn_index = 0
		outgassing_component.stop()
		return

	var current_index: int = 0
	for spawn_point: float in spawn_points:
		if entropy > spawn_point:
			current_index += 1

	if current_index > last_spawn_index:
		for i: int in range(current_index - last_spawn_index):
			outgassing_component.activate()

	last_spawn_index = current_index

func _load_scenes() -> void:
	_asteroid_scene = load(ASTEROID_SCENE_PATH)
	_meteoroid_scene = load(METEOROID_SCENE_PATH)

func _initialize_random_stage() -> void:
	current_stage = randi_range(0, 2) as SizeStage

func _apply_stage_configuration() -> void:
	var config: Dictionary = STAGE_CONFIG[current_stage]
	min_size = config["min_size"]
	max_size = config["max_size"]
	internal_energy = config.get("internal_energy", 0)


const ENTROPY_THRESHOLD: float = 5.0
var spawn_points: Array[float] = [10.0, 30.0, 50.0, 80.0, 100.0]

var last_spawn_index: int = 0


var _has_died: bool = false

func die() -> void:
	if _has_died:
		return
	_has_died = true
	var config: Dictionary = STAGE_CONFIG[current_stage]

	if _should_spawn_fragments(config):
		_spawn_fragments(config)

	super.die()

func _should_spawn_fragments(config: Dictionary) -> bool:
	return config["next_stage"] != null and config["fragments"] > 0

func _spawn_fragments(config: Dictionary) -> void:
	var next_stage: SizeStage = config["next_stage"]

	var scene_to_spawn: PackedScene = _asteroid_scene
	if next_stage == SizeStage.METEOROID:
		scene_to_spawn = _meteoroid_scene

	if not scene_to_spawn:
		return

	for i: int in range(config["fragments"]):
		var fragment: SmallBody = scene_to_spawn.instantiate()

		# Se è ancora un asteroide, impostiamo lo stadio
		if fragment is Asteroid:
			fragment.randomize_stage = false
			fragment.current_stage = next_stage

		_add_fragment_to_scene(fragment, config)

# Modifica leggermente questa per accettare Node2D generici
func _add_fragment_to_scene(fragment: SmallBody, config: Dictionary) -> void:
	var random_direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0, TAU))
	# Calcolo dell'offset basato sulla scala attuale
	var spawn_offset: float = sprite.scale.x * FRAGMENT_SPAWN_OFFSET

	fragment.global_position = global_position + random_direction * spawn_offset
	get_parent().add_child.call_deferred(fragment)

	# Usiamo un approccio sicuro per l'impulso (se il meteoroide è un RigidBody)
	if fragment is CelestialBody:
		fragment.apply_central_impulse(random_direction * config["impulse"])
