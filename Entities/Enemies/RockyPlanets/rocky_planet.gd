extends RigidBody2D
class_name RockyPlanet

@export var internal_energy: int = 2

@export var collision: CollisionShape2D
var health: float

var explosion_red_scene = preload("uid://dvg5n5eu3oyde")

@export var max_size: float = 1.0

func _ready() -> void:
	z_index = 1
	gravity_scale = 0.0
	collision_layer = 2
	collision_mask = 1
	angular_damp = 5.0
	linear_damp = 5.0
	contact_monitor = true
	max_contacts_reported = 5
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY


	var scale_rand: float = randf_range(0.1, max_size)
	collision.scale = Vector2(scale_rand, scale_rand)


	# Massa proporzionale al volume (area^1.5 simula volume 3D)
	health = mass * internal_energy

	var round_base = 50
	# Arrotonda al multiplo più vicino
	health = round(health / round_base) * round_base
	print("vita: ", health)
	lock_rotation = true

func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.play_hit_sound()
		take_damage(body.get_damage())

func take_damage(damage) -> void:
	health -= damage
	if health <= 0:
		die()

func die() -> void:
	var explosion_red = explosion_red_scene.instantiate()
	explosion_red.global_position = global_position
	get_tree().get_root().add_child(explosion_red)
	explosion_red.restart()
	explosion_red.scale = scale
	queue_free()

func play_sound_once(sound: AudioStream) -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = sound
	player.global_position = global_position
	get_tree().get_root().add_child(player)
	player.play()

	player.connect("finished", Callable(player, "queue_free"))
