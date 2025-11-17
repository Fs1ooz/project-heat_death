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

func _ready() -> void:
	_setup_physics()
	_setup_scale()
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

# Hook vuoto per le classi figlie
func _on_ready_custom() -> void:
	pass

# Gestione collisioni
func _on_body_entered(body: Node) -> void:
	if body is Player:

		body.play_hit_sound()
		var rel_vel = (linear_velocity - body.linear_velocity).length()
		var impact_force = mass * rel_vel
		var damage = impact_force * 0.002
		body.take_damage(damage)

		take_damage(body.get_damage())

# Gestione danno
func take_damage(damage: float) -> void:
	health -= damage
	if health <= 0:
		die()

# Morte e esplosione
func die() -> void:
	UpgradeManager.gain_energy(game_energy)
	_spawn_explosion()
	queue_free()

func _spawn_explosion() -> void:
	var explosion_red = explosion_red_scene.instantiate()
	explosion_red.global_position = global_position
	get_tree().get_root().add_child(explosion_red)
	explosion_red.restart()
	explosion_red.scale = scale

# Utility per suoni
func play_sound_once(sound: AudioStream) -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = sound
	player.global_position = global_position
	get_tree().get_root().add_child(player)
	player.play()
	player.connect("finished", Callable(player, "queue_free"))
