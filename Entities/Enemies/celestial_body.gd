extends RigidBody2D
class_name CelestialBody

# Proprietà comuni
@export var internal_energy: int = 1
@export var game_energy: int = 10
@export var collision: CollisionShape2D
@export var min_size: float = 1.0
@export var max_size: float = 2.0
@export var round_base: int = 50


var health: float
var explosion_red_scene = preload("uid://dvg5n5eu3oyde")
var energy_drop_scene = preload("uid://ctismywjnvljg")

func _ready() -> void:
	add_to_group("celestialbodies", true)
	_setup_physics()
	_setup_scale()
	_setup_mass()
	_setup_health()

# Configurazione fisica comune
func _setup_physics() -> void:
	z_index = 1
	gravity_scale = 0.0
	collision_layer = 2
	collision_mask = 2
	contact_monitor = true
	max_contacts_reported = 50
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY

# Scala casuale
func _setup_scale() -> void:
	var scale_rand: float = randf_range(min_size, max_size)
	collision.scale = Vector2(scale_rand, scale_rand)

# Calcolo salute
func _setup_health() -> void:
	health = snapped(mass * internal_energy, round_base)
	print(get_class(), " vita: ", health)

func _setup_mass() -> void:
	var size_x: float = collision.scale.x
	mass = snappedf(size_x * internal_energy * round_base, round_base)
	print(get_class(), " MASSA: ", mass)

# Hook vuoto per le classi figlie
func _on_ready_custom() -> void:
	pass

# Gestione collisioni
func _on_body_entered(body: Node) -> void:
	if body is Player:

		body.play_hit_sound()
		var rel_vel = (linear_velocity - body.linear_velocity).length()
		var impact_force = mass * rel_vel
		var damage = impact_force * 0.005
		body.take_damage(damage)

		take_damage(body.get_damage())

# Gestione danno
func take_damage(damage: float) -> void:
	health -= damage
	if health <= 0:
		die()

# Morte e esplosione
func die() -> void:
	_spawn_energy_drop()
	_spawn_explosion()
	queue_free()

func _spawn_explosion() -> void:
	var explosion_red = explosion_red_scene.instantiate()
	explosion_red.global_position = global_position
	get_parent().add_child(explosion_red)
	explosion_red.restart()
	explosion_red.scale = scale

func play_sound_once(sound: AudioStream) -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = sound
	player.global_position = global_position
	get_tree().get_root().add_child(player)
	player.play()
	player.connect("finished", Callable(player, "queue_free"))

func _spawn_energy_drop():
	var num_drops = int(game_energy)  # Calcola quanti drop vorresti
	num_drops = clamp(num_drops, 5, 20)  # Limita tra 5 e 20

	# IMPORTANTE: Ogni drop ha energia totale / numero effettivo di drop
	var energy_per_drop = float(game_energy) / num_drops

	var spawn_radius = max_size * 40.0

	for i in range(num_drops):
		var energy_drop = energy_drop_scene.instantiate()
		energy_drop.energy = int(energy_per_drop)  # Distribuisci l'energia equamente

		var angle = (TAU / num_drops) * i + randf_range(-0.3, 0.3)
		var distance = randf_range(spawn_radius * 0.5, spawn_radius)
		var offset = Vector2(cos(angle), sin(angle)) * distance

		energy_drop.global_position = global_position + offset

		if energy_drop is RigidBody2D:
			energy_drop.linear_velocity = offset.normalized() * randf_range(30, 60)

		get_parent().call_deferred("add_child", energy_drop)
