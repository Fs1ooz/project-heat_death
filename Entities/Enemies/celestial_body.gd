class_name CelestialBody
extends RigidBody2D

static var celestial_bodies: Array = []

func _enter_tree() -> void:
	celestial_bodies.append(self)

func _exit_tree() -> void:
	celestial_bodies.erase(self)

const G: float = 6_674_300.0  # o anche * 50, * 100
const MAX_FORCE: float = 1_000_000_000_000.0
const SOFTENING: float = 10.0
var bodies_in_gravity: Array[RigidBody2D] = []

# Proprietà comuni
@export var internal_energy: int = 1
@export var game_energy: int = 50

@export var round_base: int = 5

@export var collision: Node2D
@export var gravity_area_collision: CollisionShape2D

@export var sprite: Sprite2D

@export var base_noise: float = 5.0


@onready var mat: ShaderMaterial = sprite.material
var current_noise: float = 0.0
var entropy_force: Vector2 = Vector2.ZERO
var health: float
var death_vfx_scene: PackedScene = preload("uid://dvg5n5eu3oyde")
var energy_drop_scene: PackedScene = preload("uid://ctismywjnvljg")

var _last_velocity: Vector2 = Vector2.ZERO
var health_bar: ProgressBar
var health_bar_container: Control

@export_flags_2d_physics var layers_2d_physics: int = 0x2
@export_flags_2d_physics var masks_2d_physics: int = 0x3


func _ready() -> void:
	for child: Node in get_children():
		if child is AnimatedSprite2D:
			child.play()
	add_to_group("celestialbodies", true)
	_setup_physics()
	_setup_mass()
	_setup_health()
	#_setup_health_bar()
	EntropyManager.entropy_changed.connect(_on_entropy_changed)


func _physics_process(_delta: float) -> void:
	#print(celestial_bodies.size())
	_last_velocity = linear_velocity
	for body: RigidBody2D in bodies_in_gravity:
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


func _setup_scale(scale_factor: float) -> void:

	# IMPORTANTE: salva la scala ORIGINALE dello sprite dall'editor
	var original_sprite_scale: Vector2 = sprite.scale
	# Applica la nuova scala RELATIVA a quella originale
	sprite.scale = original_sprite_scale * scale_factor

	# Gestisci CollisionShape2D
	if collision is CollisionShape2D:
		var shape: Shape2D = collision.shape.duplicate()

		if shape is CircleShape2D:
			var original_radius: float = collision.shape.radius
			shape.radius = original_radius * scale_factor

		collision.shape = shape

	# Gestisci CollisionPolygon2D
	elif collision is CollisionPolygon2D:
		var original_points: PackedVector2Array = collision.polygon
		var new_points: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in original_points:
			new_points.append(p * scale_factor)
		collision.polygon = new_points

	# Stessa cosa per gravity_area_collision

	if gravity_area_collision is CollisionShape2D:
		var area: Shape2D = gravity_area_collision.shape.duplicate()

		if area is CircleShape2D:
			var original_radius: float = gravity_area_collision.shape.radius
			area.radius = original_radius * scale_factor

		gravity_area_collision.shape = area


var density: float = 0.1

func _setup_mass() -> void:
	var size_metric: float = 0.0

	# Calcola la metrica di dimensione in base al tipo di collisione
	if collision is CollisionShape2D:
		var shape: Shape2D = collision.shape
		if shape is CircleShape2D:
			size_metric = shape.radius
		elif shape is RectangleShape2D:
			# Usa la media delle dimensioni
			size_metric = (shape.size.x + shape.size.y) / 2.0
		elif shape is CapsuleShape2D:
			size_metric = shape.radius + shape.height / 2.0

	elif collision is CollisionPolygon2D:
		# Calcola l'area del poligono e derivane un "raggio equivalente"
		var area: float = _calculate_polygon_area(collision.polygon)
		# Raggio di un cerchio con la stessa area: r = sqrt(area / PI)
		size_metric = sqrt(area / PI)

	# Applica la formula della massa
	size_metric = max(0, size_metric - 50)
	var raw_mass: float = size_metric * density
	mass = max(round_base, snappedi(raw_mass, round_base))



func _calculate_polygon_area(points: PackedVector2Array) -> float:
	# Formula dell'area usando il metodo dello "Shoelace"
	var area: float = 0.0
	var n: int = points.size()

	for i: int in range(n):
		var j: int = (i + 1) % n
		area += points[i].x * points[j].y
		area -= points[j].x * points[i].y

	return abs(area) / 2.0

func _setup_health() -> void:
	var raw_health: float = mass * internal_energy
	health = max(round_base, snappedi(raw_health, round_base))
	#print(get_class(), " VITA: ", health)


# Gestione collisioni
func _on_body_entered(body: Node) -> void:
	var dmg_mult: float = 0.0075
	var rel_vel: float = (linear_velocity - body._last_velocity).length() * dmg_mult
	var mass_ratio: float =  mass / body.mass
	var damage_to_player: float = rel_vel * snappedf(mass_ratio, dmg_mult)
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
	flash(0.05)
	if health <= 0:
		die()

func flash(duration: float) -> void:
	if not mat:
		return
	var tween: Tween = create_tween()
	tween.tween_property(mat, "shader_parameter/flash_value", 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(mat, "shader_parameter/flash_value", 0.0, duration * 2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# Morte e esplosione
func die() -> void:
	await get_tree().create_timer(0.05).timeout
	_spawn_energy_drop()
	_spawn_explosion()
	for body: RigidBody2D in bodies_in_gravity:
		if body is Player:
			var death_entropy: float = - max(1.0, (50.0 * mass)/(mass + 1000.0))
			EntropyManager.change_entropy(death_entropy)
	bodies_in_gravity.clear()
	GlobalSignals.death.emit(self)
	queue_free()


func _spawn_explosion() -> void:
	var death_vfx: DeathVFX = death_vfx_scene.instantiate()
	death_vfx.global_position = global_position
	get_parent().add_child(death_vfx)
	death_vfx.scale_explosion(sprite.scale.x * 0.9)


func _spawn_energy_drop() -> void:
	var spawn_radius: float = sprite.scale.x * 25.0
	var energy_spawned: int = 0
	var energy_to_spawn: int = int(game_energy * randf_range(1.0, 1.8))

	while energy_spawned < energy_to_spawn:
		# Weighted random - valori bassi più probabili
		var random_factor: float = pow(randf(), 3.0)  # Bias verso 0
		var energy_value: int = max(1, int(random_factor * energy_to_spawn))

		var energy_drop: Energy = energy_drop_scene.instantiate()
		energy_drop.energy = energy_value

		var angle: float = randf() * TAU
		var distance: float = randf_range(spawn_radius * 1.2, spawn_radius * 1.2)
		energy_drop.global_position = global_position + Vector2(cos(angle), sin(angle)) * distance

		get_parent().add_child.call_deferred(energy_drop)
		energy_spawned += energy_value


# Opzionale: per debug
# print("Target: %d | Ottenuto: %d | Differenza: %d" % [target_energy, current_total, abs(target_energy - current_total)])


# Aggiungi questa funzione dopo _ready()
func _setup_health_bar() -> void:
	# Container per posizionare la barra
	health_bar_container = Control.new()
	health_bar_container.z_index = 10
	add_child(health_bar_container)

	# ProgressBar
	health_bar = ProgressBar.new()
	health_bar.size = Vector2(sprite.scale.x * 150, 2)
	health_bar.position = Vector2(sprite.scale.x * -75, sprite.scale.y * 70)
	health_bar.show_percentage = false
	health_bar_container.add_child(health_bar)

	# Stile
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.643, 0.0, 0.0, 0.8)
	stylebox.border_color = Color(0.1, 0.1, 0.1, 0.9)
	stylebox.set_border_width_all(1)
	health_bar.add_theme_stylebox_override("fill", stylebox)

	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
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

var gravity_force: float = 0.0


func _apply_gravity(body: RigidBody2D) -> void:
	var dir: Vector2 = global_position - body.global_position
	var dist_sq: float = dir.length_squared()

	dist_sq = max(dist_sq, 100.0) # Impedisce che la forza diventi infinita troppo vicino

	gravity_force = G * mass * body.mass / dist_sq + SOFTENING
	var gravity_force_vector: Vector2 = dir.normalized() * gravity_force

	body.apply_central_force(gravity_force_vector)
	apply_central_force(-gravity_force_vector)


func _on_entropy_changed(entropy: float) -> void:
	if entropy < 0:
		return
	current_noise = 1 + pow(entropy, 2.0)

	entropy_force = Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized() * current_noise * mass

	#gravity_force += pow(entropy, 2.0)
	#print("Entropy force: ", entropy_force.length())


func get_damage() -> float:
	var velocity: float = linear_velocity.length()
	#var velocity_squared = linear_velocity.length_squared()

	print("massa: ", mass)
	#print("velocità: ", velocity)

	#var kinetic_energy = 0.5 * mass * velocity_squared

	#var damage_scaling = 1000.0
	#var scaled_damage = kinetic_energy / damage_scaling
	var scaled_damage: float = mass * (velocity * 0.005)

	#print("Danno originale: ", scaled_damage)

	var damage: int = maxi(snappedi(scaled_damage, round_base), 1)

	print("Danno finale: ", damage)

	return damage


func get_gravity_radius() -> float:
	return gravity_area_collision.shape.radius
