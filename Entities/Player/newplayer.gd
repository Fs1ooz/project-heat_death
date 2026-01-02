extends RigidBody2D
## Il codice del giocatore per RigidBody2D, per simulare meglio la fisica forse tocca usare questo
## - Mode: Character
## - Gravity Scale: 0 (per top-down)
## - Mass: 1 (regolare a piacere)

@export var life_bar: ProgressBar = null
@export var alignment_safe_zone: float = 0.8
@export var collision: CollisionShape2D
## Configurazione movimento
@export var max_hp: int = 300
@export var hp: int = 100

@export var speed: float = UpgradeManager.get_current_power(UpgradeManager.UpgradeType.SPEED)  ## Velocità massima (pixel/sec)
@export var acceleration: float = UpgradeManager.get_current_power(UpgradeManager.UpgradeType.ACCELERATION)  ## Accelerazione lineare (pixel/sec²)

@export var sprite: Sprite2D
@export var trail: GPUParticles2D

var rotation_responsiveness: float = 10.0 ## Responsività della rotazione verso il mouse
var regen_tick: float = 3.0
var auto_revive: bool = true
var _last_velocity: Vector2 = Vector2.ZERO

var gravity_force: Vector2 = Vector2.ZERO

var accumulated_forces: Vector2 = Vector2.ZERO

var energy_threshold: float = 300.0

var gravity: bool = true

@onready var regen_timer: Timer = $RegenTimer

@onready var hit_audio_stream_player: AudioStreamPlayer = $HitAudioStreamPlayer

var initial_radius: float
var initial_height: float
var initial_scale: Vector2
var initial_mass: float

var old_mass: float = 1.0
var mass_percentage: float = 1.0

@onready var initial_particle_scale: Vector2
@onready var mat: ParticleProcessMaterial = trail.process_material

func _ready() -> void:
	initial_mass = mass
	initial_radius = collision.shape.radius
	initial_height = collision.shape.height
	initial_scale = sprite.scale

	initial_particle_scale = Vector2(mat.scale_min, mat.scale_max)
	#global_position.x = 2_900_000

	if life_bar:
		life_bar.value = max_hp

	await get_tree().create_timer(5).timeout



#region Movement

var can_reset: bool = false

func _physics_process(delta: float) -> void:
	_last_velocity = linear_velocity

	if EntropyManager.entropy_value < 0:  # se entropia negativa
		apply_entropy()  # applica caos
	else:
		can_reset = true
	if can_reset:
		reset_entropy_stats()

	# Applicazione forze fisiche (sostituisce _integrate_forces)
	_handle_gravity(delta)
	_handle_rotation(delta)
	_handle_collision_resistance(delta)

func reset_entropy_stats() -> void:
	speed = UpgradeManager.get_current_power(UpgradeManager.UpgradeType.SPEED)
	acceleration = UpgradeManager.get_current_power(UpgradeManager.UpgradeType.ACCELERATION)
	gravity_force = Vector2.ZERO
	can_reset = false


func apply_entropy() -> void:
	var entropy: float = max(EntropyManager.entropy_value, 0.0)
	if entropy == 0.0:
		return

	# 1. MOVIMENTO
	speed = max(100.0, speed + randf_range(-entropy, entropy * 1.5))
	acceleration = max(50.0, acceleration + randf_range(-entropy * 0.5, entropy))

	# 2. FISICA
	gravity_force = Vector2.from_angle(randf() * TAU) * entropy * randf_range(0.5, 1.5)

	if randf() < entropy:
		mass *= randf_range(0.9, 1.1)

	# 3. ROTAZIONE
	if randf() < entropy:
		apply_torque_impulse(randf_range(-entropy, entropy) * 10.0)

	# 4. VISUAL
	if randf() < entropy:
		sprite.modulate = Color(
			randf_range(0.7, 1.3),
			randf_range(0.7, 1.3),
			randf_range(0.7, 1.3)
		)
		sprite.scale = initial_scale * randf_range(0.9, 1.1)

	# 5. IMPULSO
	if randf() < entropy:
		apply_central_impulse(
			Vector2.from_angle(randf() * TAU) * entropy * 30
		)


func _handle_collision_resistance(delta: float) -> void:
	var max_resistance: float = 0.0
	var colliding_bodies: Array = get_colliding_bodies()

	for body in colliding_bodies:
		if body is CelestialBody:
			var collider: CelestialBody = body as CelestialBody
			var mass_ratio: float = mass / collider.mass

			if mass_ratio >= 5.0:
				max_resistance = 1.0
				print("💥 BULLDOZER MODE vs ", collider.name)
				break
			elif mass_ratio > 0.3:
				var resistance: float = smoothstep(1.0, 3.0, mass_ratio)
				max_resistance = max(max_resistance, resistance)
				print("⚡ Resistenza: %.0f%% vs %s" % [resistance * 100, collider.name])

	if max_resistance > 0.0:
		# Applica resistenza come forza opposta alla velocità
		var resistance_force: Vector2 = -linear_velocity * max_resistance * mass / max(delta, 0.001)
		apply_central_force(resistance_force)


func _handle_rotation(delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = mouse_pos - global_position

	if dir.length_squared() < 1.0:
		angular_velocity = 0.0
		return

	var target_angle: float = dir.angle()
	var angle_diff: float = wrapf(target_angle - rotation, -PI, PI)

	# Applica torque per raggiungere velocità angolare target
	var target_angular_velocity: float = angle_diff * rotation_responsiveness
	var angular_acceleration: float = (target_angular_velocity - angular_velocity) / max(delta, 0.001)
	apply_torque(angular_acceleration * inertia)


func _handle_movement(delta: float, input_dir: Vector2, mouse_dir: Vector2) -> void:
	var dir: Vector2 = mouse_dir if mouse_dir.length() > 0.1 else input_dir

	# NESSUN INPUT → rallenta (attrito)
	if dir.length() < 0.1:
		var friction_force: Vector2 = -linear_velocity * mass / max(delta, 0.001) * 0.5
		apply_central_force(friction_force)
		return

	# Velocità target
	var movement_angle: float = dir.angle()
	var alignment: float = cos(rotation - movement_angle)
	if alignment > alignment_safe_zone:
		alignment = 1.0

	var speed_factor: float = remap(alignment, -1.0, 1.0, 0.2, 1.0)
	var target_velocity: Vector2 = dir.normalized() * speed * speed_factor

	# Forza di accelerazione verso velocità target
	var velocity_diff: Vector2 = target_velocity - linear_velocity
	var acceleration_force: Vector2 = velocity_diff * mass / max(delta, 0.001)
	apply_central_force(acceleration_force)


func get_input() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")

#endregion

## Calcola e restituisce il danno del giocatore usando la legge dell'energia cinetica (E = 1/2 mv^2), scherzo, usando la quantità di moto (p = m * v)
func get_damage() -> float:
	var velocity: float = linear_velocity.length()
	#var velocity_squared: float = linear_velocity.length_squared()

	print("massa: ", mass)
	print("velocità: ", velocity)

	#var kinetic_energy: float = 0.5 * mass * velocity_squared

	#var damage_scaling: float = 1000.0
	#var scaled_damage: float = kinetic_energy / damage_scaling
	var scaled_damage: float = mass * (velocity * 0.005)

	var round_base: int = 5
	print("Danno originale: ", scaled_damage)

	var damage: int = maxi(snappedi(scaled_damage, round_base), 1)

	print("Danno finale: ", damage)

	return damage

var lvl: int = 0

func change_size(amount: float) -> void:
	change_mass(amount)
	change_scale(amount)
	lvl += 1
	# Emetti il segnale con i nuovi valori
	energy_threshold *= amount

func change_mass(amount: float) -> void:
	old_mass = mass
	mass *= amount
	mass_percentage = mass / old_mass


func change_scale(amount: float) -> void:
	var scale_change: Vector2 = sprite.scale * amount
	collision.shape.radius = initial_radius * scale_change.x
	collision.shape.height = initial_height * scale_change.x

	# Calcola la scala totale rispetto all'inizio
	var total_scale_factor: float = scale_change.x / initial_scale.x

	# Applica la scala totale alle particelle
	mat.scale_min = initial_particle_scale.x * total_scale_factor
	mat.scale_max = initial_particle_scale.y * total_scale_factor

	if mat:
		var initial_x: float = -25.0
		mat.set("emission_shape_offset", Vector3(initial_x * amount, 0.0, 0.0))

	sprite.scale = scale_change

	#var tween: Tween = create_tween()
	#tween.set_parallel(true)
	#tween.tween_property(sprite, "scale", scale_change, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)



## Riproduce il suono di hit.
func play_hit_sound() -> void:
	print("Muori fra")
	hit_audio_stream_player.play()


func _handle_mouse_input() -> Vector2:
	# Se non sto premendo il tasto sinistro, nessun movimento
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return Vector2.ZERO

	# Direzione dal player verso il mouse
	var mouse_dir: Vector2 = (get_global_mouse_position() - global_position).normalized()

	# Ritorna la direzione * speed
	return mouse_dir


func take_damage(amount: int) -> void:
	hp -= amount
	_update_life_bar()

	if hp <= 0:
		if auto_revive:
			printerr("RINATO!!")
			auto_revive = false
			hp = 1
		else:
			game_over()

func game_over() -> void:
	GlobalSignals.emit_signal("game_over")
	queue_free()


func _update_life_bar() -> void:
	if life_bar:
		life_bar.value = hp
	#life_bar.start_fade()

func _on_regen_timer_timeout() -> void:
	if hp == max_hp:
		return

	hp = min(hp + int(max_hp * 0.15), max_hp)

	_update_life_bar()

	regen_timer.wait_time = regen_tick


func _handle_gravity(delta: float) -> void:
	# ===== GRAVITÀ =====
	var gravity_accel: Vector2 = gravity_force / mass
	var gravity_delta_v: Vector2 = gravity_accel * delta

	linear_velocity += gravity_delta_v  # ← applica direttamente

	# ===== MOVEMENT (STEERING) =====
	var input_dir: Vector2 = get_input()
	var mouse_dir: Vector2 = _handle_mouse_input()
	var dir: Vector2 = mouse_dir if mouse_dir.length() > 0.1 else input_dir

	# rimuovi la componente di gravità dalla velocità
	var planar_velocity: Vector2 = linear_velocity - gravity_delta_v

	if dir.length() > 0.1:
		planar_velocity += dir.normalized() * acceleration * delta

	# clamp SOLO il movimento
	planar_velocity = planar_velocity.limit_length(speed)

	# ricombina
	linear_velocity = planar_velocity + gravity_delta_v
