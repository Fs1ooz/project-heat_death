extends SmallBody
class_name Asteroid

enum SizeStage { LARGE, MEDIUM, SMALL, METEOROID }

# Configurazioni centralizzate per ogni stadio
const STAGE_CONFIG: Dictionary = {
	SizeStage.LARGE: {
		"next_stage": SizeStage.MEDIUM,
		"fragments": 3,
		"min_size": 35.0,
		"max_size": 50.0,
		"internal_energy": 2,
		"impulse": 3000,
	},
	SizeStage.MEDIUM: {
		"next_stage": SizeStage.SMALL,
		"fragments": 2,
		"min_size": 15.0,
		"max_size": 20.0,
		"internal_energy": 1,
		"impulse": 1500,
	},
	SizeStage.SMALL: {
		"next_stage": SizeStage.METEOROID, # Ora punta a meteoroid
		"fragments": 4, # Magari ne spawna tanti piccoli
		"min_size": 5.0,
		"max_size": 7.5,
		"internal_energy": 1,
		"impulse": 400,
	},
	SizeStage.METEOROID: {
		"next_stage": null,
		"fragments": 0,
	},
}

const ASTEROID_SCENE_PATH: String = "res://Entities/Enemies/SmallBodies/Asteroid.tscn"
const METEOROID_SCENE_PATH: String = "res://Entities/Enemies/SmallBodies/Meteoroid.tscn"
const GAS_SCENE_PATH: String = "res://Entities/Enemies/SmallBodies/gas.tscn"
const FRAGMENT_SPAWN_OFFSET: float = 75.0
const GAS_SCALE_MULTIPLIER: float = 10.0
const GAS_OFFSET: float = 50.0
const OUTGASSING_IMPULSE: float = 200.0


@export var current_stage: SizeStage = SizeStage.LARGE
@export var randomize_stage: bool = true


var _asteroid_scene: PackedScene = null
var _gas_scene: PackedScene = null
var _meteoroid_scene: PackedScene = null


func _ready() -> void:
	_load_scenes()
	if randomize_stage:
		_initialize_random_stage()
	_apply_stage_configuration()
	super()

func _load_scenes() -> void:
	_asteroid_scene = load(ASTEROID_SCENE_PATH)
	_meteoroid_scene = load(METEOROID_SCENE_PATH)
	_gas_scene = preload(GAS_SCENE_PATH)

func _initialize_random_stage() -> void:
	current_stage = randi_range(0, 2) as SizeStage

func _apply_stage_configuration() -> void:
	var config: Dictionary = STAGE_CONFIG[current_stage]
	min_size = config["min_size"]
	max_size = config["max_size"]
	internal_energy = config.get("internal_energy", 0)


func _outgassing() -> void:
	if not _gas_scene:
		return

	var gas: Node2D = _gas_scene.instantiate()
	var angle: float = randf_range(0.0, TAU)
	var direction: Vector2 = Vector2.RIGHT.rotated(angle)

	_configure_gas(gas, direction, angle)
	add_child(gas)
	apply_impulse(-direction * OUTGASSING_IMPULSE)

func _configure_gas(gas: Node2D, direction: Vector2, angle: float) -> void:
	gas.scale *= sprite.scale * GAS_SCALE_MULTIPLIER
	gas.global_position = global_position + direction * GAS_OFFSET
	gas.rotation = angle

	if gas.has_node("mat"):
		gas.mat.scale *= sprite.scale * GAS_SCALE_MULTIPLIER

func die() -> void:
	var config: Dictionary = STAGE_CONFIG[current_stage]

	if _should_spawn_fragments(config):
		_spawn_fragments(config)

	super.die()

func _should_spawn_fragments(config: Dictionary) -> bool:
	return config["next_stage"] != null and config["fragments"] > 0

func _spawn_fragments(config: Dictionary) -> void:
	var next_stage: SizeStage = config["next_stage"]

	# Scegliamo la scena corretta in base allo stadio
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
