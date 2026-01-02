extends RigidBody2D
class_name CelestialBody


const G: float = 6_674_300.0  # o anche * 50, * 100
const MAX_FORCE := 1_000_000_000_000.0
const SOFTENING := 10.0
var bodies_in_gravity: Array[RigidBody2D] = []

# Proprietà comuni
@export var internal_energy: int = 1
@export var game_energy: int = 10

@export var min_size: float = 1.0
@export var max_size: float = 2.0
@export var round_base: int = 5


@export var collision: Node2D
@export var gravity_area_collision: CollisionShape2D

@export var base_noise: float = 1.0
var current_noise: float = 0.0
var entropy_force: Vector2 = Vector2.ZERO
var health: float
var explosion_red_scene = preload("uid://dvg5n5eu3oyde")
var energy_drop_scene = preload("uid://ctismywjnvljg")

var _last_velocity: Vector2 = Vector2.ZERO
var health_bar: ProgressBar
var health_bar_container: Control

@export_flags_2d_physics var layers_2d_physics = 0x2
@export_flags_2d_physics var masks_2d_physics = 0x3


func _ready() -> void:
	for child in get_children():
		if child is AnimatedSprite2D:
			child.play()
	add_to_group("celestialbodies", true)
	_setup_physics()
	_setup_scale()
	_setup_mass()
	_setup_health()
	_setup_health_bar()
	EntropyManager.entropy_changed.connect(_on_entropy_changed)


func _physics_process(_delta: float) -> void:
	_last_velocity = linear_velocity
	for body in bodies_in_gravity:
		if not is_instance_valid(body):
			return
		_apply_gravity(body)
			# Applica la forza da entropia continuamente
	if entropy_force.length() > 0:
		apply_central_force(entropy_force)

# Configurazione fisica comune
func _setup_physics() -> void:
	z_index = 1
	gravity_scale = 0.0
	collision_layer = layers_2d_physics
	collision_mask = masks_2d_physics
	gravity_area_collision.get_parent().collision_layer = layers_2d_physics
	gravity_area_collision.get_parent().collision_mask = masks_2d_physics
	contact_monitor = true
	max_contacts_reported = 100
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.0
	physics_material_override.friction = 0.0


func _setup_scale() -> void:
	var scale_rand := randf_range(min_size, max_size)

	var sprite = collision.get_child(0)

	# IMPORTANTE: salva la scala ORIGINALE dello sprite dall'editor
	var original_sprite_scale = sprite.scale

	# Applica la nuova scala RELATIVA a quella originale
	sprite.scale = original_sprite_scale * scale_rand

	# Duplica lo shape
	var shape := collision.shape.duplicate() as Shape2D
	var area = null
	if gravity_area_collision:
		area = gravity_area_collision.shape.duplicate() as Shape2D

	if shape is CircleShape2D:
		# Scala RELATIVAMENTE al valore originale, non moltiplicare direttamente
		var original_radius = collision.shape.radius  # valore dall'editor
		shape.radius = original_radius * scale_rand
	if area is CircleShape2D:
		var original_radius = gravity_area_collision.shape.radius  # valore dall'editor
		area.radius = original_radius * scale_rand

	collision.shape = shape
	if gravity_area_collision:
		gravity_area_collision.shape = area


func _setup_mass() -> void:
	var radius: float = collision.shape.radius - 50
	var raw_mass = radius * mass
	mass = max(round_base, snappedi(raw_mass, round_base))
	#if mass > 1000:
		#print(get_class(), " MASSA: ", mass)

func _setup_health() -> void:
	var raw_health = mass * internal_energy
	health = max(round_base, snappedi(raw_health, round_base))
	#print(get_class(), " VITA: ", health)


# Gestione collisioni
func _on_body_entered(body: Node) -> void:
	var dmg_mult = 0.001
	var rel_vel = (linear_velocity - body._last_velocity).length() * dmg_mult
	var mass_ratio =  mass / body.mass
	var damage_to_player = rel_vel * snappedf(mass_ratio, dmg_mult)
	if body is Player:
		body.play_hit_sound()
		body.take_damage(int(damage_to_player))
		#print("rel_vel: ", rel_vel)
		#print("ratio: ", mass_ratio)
		#print("damage_to_player: ", damage_to_player)
		take_damage(body.get_damage())
	else:
		take_damage(body.get_damage())

# Gestione danno
func take_damage(damage: float) -> void:
	health -= damage
	if health_bar:
		health_bar.value = health
	print("Vita attuale: ", health)
	if health <= 0:
		die()

# Morte e esplosione
func die() -> void:
	_spawn_energy_drop()
	_spawn_explosion()
	for body in bodies_in_gravity:
		if body is Player:
			var death_entropy: float = - max(1.0, (50.0 * mass)/(mass + 1000.0))
			EntropyManager.change_entropy(death_entropy)
#
	printerr("Sono scattato porc")
	bodies_in_gravity.clear()
	GlobalSignals.emit_signal("death", self)
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
	num_drops = clamp(num_drops, 5, 100)  # Limita tra 5 e 100

	# IMPORTANTE: Ogni drop ha energia totale / numero effettivo di drop
	var energy_per_drop = float(game_energy) / num_drops

	var spawn_radius = collision.shape.radius / 1.5

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


# Aggiungi questa funzione dopo _ready()
func _setup_health_bar() -> void:
	# Container per posizionare la barra
	health_bar_container = Control.new()
	health_bar_container.z_index = 10
	add_child(health_bar_container)

	# ProgressBar
	health_bar = ProgressBar.new()
	health_bar.size = Vector2(collision.shape.radius * 2, 2)
	health_bar.position = Vector2(-collision.shape.radius, collision.shape.radius + 15)
	health_bar.show_percentage = false
	health_bar_container.add_child(health_bar)

	# Stile
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.643, 0.0, 0.0, 0.8)
	stylebox.border_color = Color(0.1, 0.1, 0.1, 0.9)
	stylebox.set_border_width_all(1)
	health_bar.add_theme_stylebox_override("fill", stylebox)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.3, 0.3, 0.3, 0.6)
	health_bar.add_theme_stylebox_override("background", bg_style)

	# Valori iniziali
	health_bar.max_value = health
	health_bar.value = health

func _on_gravity_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		bodies_in_gravity.append(body)

func _on_gravity_body_exited(body: Node2D) -> void:
	#if body is Player:
		##body.gravity = false
	bodies_in_gravity.erase(body)


func _apply_gravity(body: RigidBody2D) -> void:
	var dir := global_position - body.global_position
	var dist_sq := dir.length_squared()

	dist_sq = max(dist_sq, 100.0) # Impedisce che la forza diventi infinita troppo vicino

	var force := G * mass * body.mass / dist_sq + SOFTENING
	var force_vector := dir.normalized() * force

	#if body is Player:
		##print("DIST: ", snapped(dist_sq, 0.1), " | FORZA: ", snapped(force_magnitude, 0.1))
		## PLAYER → custom integrator
		##body.gravity = true
		#body.gravity_force = force_vector
	#else:
		# ALTRI CELESTIAL BODY → fisica standard
	body.apply_central_force(force_vector)
	apply_central_force(-force_vector)

	#print("I'm gravitating it: ", body.mass, " ", mass,  " ", dist_sq, " forza di g: ", force_vector.length())

var orbital_center: Node2D = null
var orbit_clockwise: bool = true
var has_orbit: bool = false

#func set_circular_orbit(around: Node2D, clockwise := true) -> void:
	## Salva i parametri dell'orbita
	#orbital_center = around
	#orbit_clockwise = clockwise
	#has_orbit = true
#
	## Applica l'orbita
	#_apply_orbit()

#func _apply_orbit() -> void:
	#if not has_orbit or not is_instance_valid(orbital_center):
		#return
#
	#var r = global_position.distance_to(orbital_center.global_position)
	#var orbit_mass: float = orbital_center.mass if orbital_center is RigidBody2D else 10_000.0
	#var v = sqrt(G * orbit_mass / r)
	#var tangent = (global_position - orbital_center.global_position).orthogonal().normalized()
	#if not orbit_clockwise:
		#tangent = -tangent
	#linear_velocity = tangent * v
#
## Funzione pubblica per riapplicare l'orbita (chiamata dallo streaming manager)
#func reapply_orbit() -> void:
	#_apply_orbit()

func _on_entropy_changed(entropy: float):
	if not visible:
		return

	current_noise = base_noise + pow(entropy / 100.0, 2.0) * (100.0 - base_noise)

	entropy_force = Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized() * current_noise * mass

	#print("Entropy force: ", entropy_force.length())


func get_damage() -> float:
	var velocity = linear_velocity.length()
	#var velocity_squared = linear_velocity.length_squared()

	print("massa: ", mass)
	print("velocità: ", velocity)

	#var kinetic_energy = 0.5 * mass * velocity_squared

	#var damage_scaling = 1000.0
	#var scaled_damage = kinetic_energy / damage_scaling
	var scaled_damage = mass * (velocity * 0.005)

	print("Danno originale: ", scaled_damage)

	var damage = maxi(snappedi(scaled_damage, round_base), 1)

	print("Danno finale: ", damage)

	return damage


func get_gravity_radius():
	return gravity_area_collision.shape.radius
