class_name Player
extends RigidBody2D
## Il codice del giocatore per RigidBody2D, per simulare meglio la fisica forse tocca usare questo
## - Mode: Character
## - Gravity Scale: 0 (per top-down)
## - Mass: 1 (regolare a piacere)


@export var life_bar: ProgressBar
@export var alignment_safe_zone: float = 0.8
@export var collision: CollisionShape2D
## Configurazione movimento
@export var max_hp: int = 100
@export var hp: int = 100

@export var speed: float = 1000.0 ## Velocità massima (pixel/sec)
@export var acceleration: float = 500.0 ## Accelerazione lineare (pixel/sec²)
@export var trail: GPUParticles2D

@export var sprite: Sprite2D

var rotation_responsiveness: float = 10.0 ## Responsività della rotazione verso il mousewwwwwwwwwwwwws
var regen_tick: float = 3.0
var auto_revive: bool = true
var _last_velocity: Vector2 = Vector2.ZERO

var gravity_force = Vector2.ZERO

var accumulated_forces := Vector2.ZERO

var energy_threshold: float = 300.0

var gravity: bool = false

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
#region Movement

func _physics_process(_delta: float) -> void:
	_last_velocity = linear_velocity


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:

	if not gravity:
		_handle_movement(state)
		#print("NON GRAVITO")
	else:
		_handle_gravity(state)
		#printerr(" GRAVITO")
	_handle_rotation(state)
	_handle_collision_resistance(state)


func _handle_collision_resistance(state: PhysicsDirectBodyState2D) -> void:
	var max_resistance: float = 0.0

	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if collider is CelestialBody:
			var mass_ratio = mass / collider.mass

			if mass_ratio >= 5.0:
				max_resistance = 1.0
				print("💥 BULLDOZER MODE vs ", collider.name)
				break
			elif mass_ratio > 1.0:
				var resistance = smoothstep(1.0, 3.0, mass_ratio)
				max_resistance = max(max_resistance, resistance)
				print("⚡ Resistenza: %.0f%% vs %s" % [resistance * 100, collider.name])

	if max_resistance > 0.0:
		state.linear_velocity = state.linear_velocity.lerp(_last_velocity, max_resistance)


func _handle_rotation(state: PhysicsDirectBodyState2D) -> void:
	var mouse_pos = get_global_mouse_position()
	var dir = mouse_pos - global_position

	if dir.length_squared() < 1.0:
		state.angular_velocity = 0.0
		return

	var target_angle = dir.angle()
	var angle_diff = wrapf(target_angle - rotation, -PI, PI)
	state.angular_velocity = angle_diff * rotation_responsiveness

func _handle_movement(state: PhysicsDirectBodyState2D) -> void:
	var input_dir := get_input()
	var mouse_dir := _handle_mouse_input()
	var dir := mouse_dir if mouse_dir.length() > 0.1 else input_dir

	# NESSUN INPUT → rallenta (attrito)
	if dir.length() < 0.1:
		state.linear_velocity = state.linear_velocity.move_toward(
			Vector2.ZERO,
			acceleration * state.step
		)
		return

	# Velocità target
	var movement_angle := dir.angle()
	var alignment := cos(rotation - movement_angle)
	if alignment > alignment_safe_zone:
		alignment = 1.0

	var speed_factor := remap(alignment, -1.0, 1.0, 0.2, 1.0)
	var target_velocity := dir.normalized() * speed * speed_factor

	# Accelerazione verso il target
	state.linear_velocity = state.linear_velocity.move_toward(
		target_velocity,
		acceleration * state.step
	)

func _handle_gravity(state: PhysicsDirectBodyState2D) -> void:
	# Input
	var input_dir := get_input()
	var mouse_dir := _handle_mouse_input()
	var dir := mouse_dir if mouse_dir.length() > 0.1 else input_dir

	# Calcola la gravità come vettore velocità
	var gravity_accel: Vector2 = gravity_force / mass
	var gravity_velocity: Vector2 = gravity_accel * state.step

	# APPLICA SEMPRE LA GRAVITÀ sottraendola dalla velocità
	state.linear_velocity += gravity_velocity

	# Se c'è input, applica anche il movimento
	if dir.length() > 0.1:
		var movement_angle := dir.angle()
		var alignment := cos(rotation - movement_angle)
		if alignment > alignment_safe_zone:
			alignment = 1.0

		var speed_factor := remap(alignment, -1.0, 1.0, 0.2, 1.0)
		var target_velocity := dir.normalized() * speed * speed_factor

		# Accelera verso la velocità target (contrasta la gravità con l'input)
		state.linear_velocity = state.linear_velocity.move_toward(
			target_velocity,
			acceleration * state.step
		)

func get_input() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")

#endregion

## Calcola e restituisce il danno del giocatore usando la legge dell'energia cinetica (E = 1/2 mv^2), scherzo, usando la quantità di moto (p = m * v)
func get_damage() -> float:
	var velocity = linear_velocity.length()
	#var velocity_squared = linear_velocity.length_squared()

	print("massa: ", mass)
	print("velocità: ", velocity)

	#var kinetic_energy = 0.5 * mass * velocity_squared

	#var damage_scaling = 1000.0
	#var scaled_damage = kinetic_energy / damage_scaling
	var scaled_damage = mass * (velocity * 0.005)

	var round_base = 5
	print("Danno originale: ", scaled_damage)

	var damage = maxi(snappedi(scaled_damage, round_base), 1)

	print("Danno finale: ", damage)

	return damage

var lvl: int = 0

func change_size(amount: float) -> void:
	change_mass(amount)
	change_scale(amount)
	lvl += 1
	# Emetti il segnale con i nuovi valori
	energy_threshold *= amount
	print(lvl, " energytresh: ", energy_threshold)

func change_mass(amount: float):
	old_mass = mass
	mass *= amount
	mass_percentage = mass / old_mass


func change_scale(amount: float):
	var scale_change = sprite.scale * amount
	collision.shape.radius = initial_radius * scale_change.x
	collision.shape.height = initial_height * scale_change.x

	mat.scale_min = initial_particle_scale.x * amount
	mat.scale_max = initial_particle_scale.y * amount

	if mat:
		var initial_x = -25.0
		mat.set("emission_shape_offset", Vector3(initial_x * amount, 0.0, 0.0))

	sprite.scale = scale_change
	#var tween = create_tween()
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
	life_bar.value = hp
	#life_bar.start_fade()

func _on_regen_timer_timeout() -> void:
	if hp == max_hp:
		return

	hp = min(hp + int(max_hp * 0.15), max_hp)

	_update_life_bar()

	regen_timer.wait_time = regen_tick
