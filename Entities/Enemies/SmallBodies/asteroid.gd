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

const ASTEROID_SCENE_PATH: String = "res://Entities/Enemies/SmallBodies/Asteroid.tscn"
const METEOROID_SCENE_PATH: String = "res://Entities/Enemies/SmallBodies/Meteoroid.tscn"
const GAS_SCENE_PATH: String = "res://Entities/Enemies/SmallBodies/gas.tscn"
const FRAGMENT_SPAWN_OFFSET: float = 50.0
const OUTGASSING_IMPULSE: float = 1000.0


@export var current_stage: SizeStage = SizeStage.LARGE
@export var randomize_stage: bool = true


var _asteroid_scene: PackedScene = null
var _gas_scene: PackedScene = null
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
	_prespawn_gasses()  # <-- spawna tutti i gas nascosti

# Crea tutti i gas subito, ma li tiene nascosti
func _prespawn_gasses() -> void:
	if not _gas_scene:
		return

	# Spawn un gas per ogni spawn_point (o quanti ne vuoi)
	for i: int in range(spawn_points.size()):
		var gas: Gas = _gas_scene.instantiate()
		var angle: float = randf_range(0.0, TAU)
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)

		sprite.add_child(gas)

		var scale_factor: float = sprite.scale.x
		var offset: float = scale_factor - 10

		gas.global_position = global_position
		gas.position = direction * offset
		gas.rotation = angle

		if gas.process_material:
			gas.process_material.scale_min = gas.initial_particle_scale.x * scale_factor
			gas.process_material.scale_max = gas.initial_particle_scale.y * scale_factor

		# Memorizza direzione per usarla dopo nell'impulso
		gas.set_meta("direction", direction)

		# Nasconde e mette in pausa le particelle
		gas.emitting = false
		gas.visible = false

		gasses.append(gas)


func _activate_outgassing() -> void:
	# Attiva il prossimo gas non ancora attivo
	for gas: Gas in gasses:
		if not gas.emitting:
			gas.visible = true
			gas.emitting = true
			var direction: Vector2 = gas.get_meta("direction", Vector2.RIGHT)
			apply_force(-direction.rotated(sprite.rotation) * OUTGASSING_IMPULSE)
			break


func _stop_outgassing() -> void:
	for gas: Gas in gasses:
		gas.emitting = false
		gas.visible = false

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


const ENTROPY_THRESHOLD: float = 5.0
var spawn_points: Array[float] = [10.0, 30.0, 50.0, 80.0, 100.0]

var last_spawn_index: int = 0


func _on_entropy_changed(entropy: float) -> void:
	if entropy < ENTROPY_THRESHOLD:
		last_spawn_index = 0
		_stop_outgassing()  # disattiva tutti (non li distrugge più)
		return

	var current_index: int = 0
	for spawn_point: float in spawn_points:
		if entropy > spawn_point:
			current_index += 1

	if current_index > last_spawn_index:
		for i: int in range(current_index - last_spawn_index):
			_activate_outgassing()  # attiva il prossimo gas inattivo

	last_spawn_index = current_index


func _spawn_gas() -> void:
	if not _gas_scene:
		return

	var gas: Gas = _gas_scene.instantiate()
	var angle: float = randf_range(0.0, TAU)
	var direction: Vector2 = Vector2.RIGHT.rotated(angle)

	sprite.add_child(gas)

	var scale_factor: float = sprite.scale.x

	var offset: float = scale_factor - 20

	gas.global_position = global_position
	gas.position = direction * offset
	gas.rotation = angle

	apply_force(-direction.rotated(sprite.rotation) * OUTGASSING_IMPULSE)

	if gas.process_material:
		print("prima:", gas.process_material.scale_min)
		gas.process_material.scale_min = gas.initial_particle_scale.x * scale_factor
		print("dopo:", gas.process_material.scale_min)
		gas.process_material.scale_max = gas.initial_particle_scale.y * scale_factor


func _get_gas_children() -> Array:
	var gas_children: Array = []
	for child: Node in sprite.get_children():
		if child is Gas:
			gas_children.append(child)
	return gas_children

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
