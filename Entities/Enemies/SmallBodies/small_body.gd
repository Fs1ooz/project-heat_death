extends CelestialBody
class_name SmallBody

@export var min_size: float = 1.5
@export var max_size: float = 2.5
#@export var spin_range: float = 2.0
#

#@export var visible_on_screen_notifier: VisibleOnScreenEnabler2D
#
func _ready() -> void:
	rotation = randf_range(0.0, TAU)
	_setup_random_scale()
	super()
	#visible_on_screen_notifier.position = visible_on_screen_notifier.rect.position
#
	#visible_on_screen_notifier.rect.position = Vector2.ZERO



func _on_visible_screen_enabler_component_screen_entered() -> void:
	set_sleeping(false)
	#print("ENTRATO: ", sleeping)



func _on_visible_screen_enabler_component_screen_exited() -> void:
	set_sleeping(true)
	#print("USCITO: ", sleeping)


func _setup_random_scale() -> void:
	var scale_rand: float = randf_range(min_size, max_size)
	_setup_scale(scale_rand)



#func _ready() -> void:

	#super()
	#("_kick")
#
#
#func _kick() -> void:
	#rotation = randf_range(0.0, TAU)
	#var direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0.0, TAU)).normalized()
	#var speed: float = randf_range(min_speed, max_speed)
	#apply_impulse(direction * speed * mass)
#
	#apply_torque_impulse(randf_range(-spin_range, spin_range) * inertia)
#@export var min_speed: float = 1.0
#@export var max_speed: float = 1.5

#
#enum Size { LARGE, MEDIUM, SMALL}
#
## Configurazioni centralizzate per ogni stadio
#const STAGE_CONFIG: Dictionary = {
	#Size.LARGE: {
		#"next_stage": Size.MEDIUM,
		#"fragments": 4,
		#"min_size": 8.5,
		#"max_size": 10.0,
		#"internal_energy": 1,
		#"impulse": 3000,
	#},
	#Size.MEDIUM: {
		#"next_stage": Size.SMALL,
		#"fragments": 2,
		#"min_size": 1.5,
		#"max_size": 1.8,
		#"internal_energy": 1,
		#"impulse": 1500,
	#},
	#Size.SMALL: {
		#"next_stage": null,
		#"min_size": 0.5,
		#"max_size": 0.8,
		#"internal_energy": 1,
#}
#}
#
#const METEOROID_SCENE_PATH: String = "res://Entities/Enemies/SmallBodies/Meteoroid.tscn"
#const FRAGMENT_SPAWN_OFFSET: float = 75.0
#
#
#@export var current_stage: Size = Size.LARGE
#@export var randomize_stage: bool = true
#
#
#var _meteoroid_scene: PackedScene = null
#

#func _ready() -> void:
	#_load_scenes()
	#if randomize_stage:
		#_initialize_random_stage()
	#_apply_stage_configuration()
	#_setup_random_scale()
	#_kick.call_deferred()
	#super()
#
#func _load_scenes() -> void:
	#_meteoroid_scene = load(METEOROID_SCENE_PATH)
#
#func _initialize_random_stage() -> void:
	#current_stage = randi_range(0, 2) as Size
#
#func _apply_stage_configuration() -> void:
	#var config: Dictionary = STAGE_CONFIG[current_stage]
	#min_size = config["min_size"]
	#max_size = config["max_size"]
	#internal_energy = config.get("internal_energy", 0)
#
#
#
#func _setup_random_scale() -> void:
	#var scale_rand: float = randf_range(min_size, max_size)
	#_setup_scale(scale_rand)
#
#
#func die() -> void:
	#var config: Dictionary = STAGE_CONFIG[current_stage]
#
	#if _should_spawn_fragments(config):
		#_spawn_fragments(config)
#
	#super.die()
#
#func _should_spawn_fragments(config: Dictionary) -> bool:
	#return config["next_stage"] != null and config["fragments"] > 0
#
#func _spawn_fragments(config: Dictionary) -> void:
	#var next_stage: Size = config["next_stage"]
#
	## Scegliamo la scena corretta in base allo stadio
	#var scene_to_spawn: PackedScene = _meteoroid_scene
#
	#if not scene_to_spawn:
		#return
#
	#for i: int in range(config["fragments"]):
		#var fragment: SmallBody = scene_to_spawn.instantiate()
#
		## Se è ancora un asteroide, impostiamo lo stadio
		#fragment.randomize_stage = false
		#fragment.current_stage = next_stage
#
		#_add_fragment_to_scene(fragment, config)
#
## Modifica leggermente questa per accettare Node2D generici
#func _add_fragment_to_scene(fragment: SmallBody, config: Dictionary) -> void:
	#var random_direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0, TAU))
	## Calcolo dell'offset basato sulla scala attuale
	#var spawn_offset: float = sprite.scale.x * FRAGMENT_SPAWN_OFFSET
#
	#fragment.global_position = global_position + random_direction * spawn_offset
	#get_parent().add_child.call_deferred(fragment)
#
	## Usiamo un approccio sicuro per l'impulso (se il meteoroide è un RigidBody)
	#if fragment is CelestialBody:
		#fragment.apply_central_impulse(random_direction * config["impulse"])
#
#
#
#func _kick() -> void:
	#var direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0.0, TAU)).normalized()
	#var speed: float = randf_range(min_speed, max_speed)
	#apply_impulse(direction * speed * mass / 2)
