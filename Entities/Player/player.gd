class_name Player
extends RigidBody2D
## Il codice del giocatore per RigidBody2D, per simulare meglio la fisica forse tocca usare questo
## - Mode: Character
## - Gravity Scale: 0 (per top-down)
## - Mass: 1 (regolare a piacere)

@export var life_bar: ProgressBar = null
@export var alignment_safe_zone: float = 0.8
@export var collision: CollisionShape2D
## Configurazione movimento
@export var max_hp: int = 100
@export var hp: int = 100

@export var speed: float = UpgradeManager.get_current_power(UpgradeManager.UpgradeType.SPEED)  ## Velocità massima (pixel/sec)
@export var acceleration: float = UpgradeManager.get_current_power(UpgradeManager.UpgradeType.ACCELERATION)  ## Accelerazione lineare (pixel/sec²)

@export var sprite: Sprite2D
@export var trail: GPUParticles2D

@export var shockwave: Node

var rotation_responsiveness: float = 10.0

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


func _physics_process(delta: float) -> void:
	_last_velocity = linear_velocity

	if EntropyManager.entropy_value < 0:  # se entropia negativa
		apply_entropy(delta)  # applica caos

	_handle_movement()
	#_handle_rotation()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("space") and EntropyManager.entropy_value < 0:
		shockwave.trigger_shockwave(global_position, 3)
		EntropyManager.change_entropy(abs(EntropyManager.entropy_value) * 2)
		get_viewport().set_input_as_handled()


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	_handle_collision_resistance(state)
	_handle_rotation(state)


func _handle_rotation(state: PhysicsDirectBodyState2D) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = mouse_pos - global_position
	if dir.length_squared() < 1.0:
		state.angular_velocity = 0.0
		return
	var target_angle: float = dir.angle()
	var angle_diff: float = wrapf(target_angle - rotation, -PI, PI)
	state.angular_velocity = angle_diff * rotation_responsiveness



var oscillation_speed: float = 1000.0   # Intensità della forza
var oscillation_frequency: float = 2.0  # Quante oscillazioni al secondo
var time_passed: float = 0.0            # Contatore del tempo


func apply_entropy(delta: float) -> void:
	var entropy: float = abs(EntropyManager.entropy_value)
	if entropy == 0.0:
		return

	time_passed += delta

	# Oscillazione sinusoidale lungo Y locale
	var oscillation: float = sin(time_passed * oscillation_frequency * TAU)  # -1..1
	var local_dir: Vector2 = Vector2(0, oscillation)
	var world_dir: Vector2 = local_dir.rotated(rotation)
	apply_central_force(world_dir * entropy * oscillation_speed * mass)


	# 2. IMPULSI IMPROVVISI
	if entropy > 10.0 and randf() < 0.01:  # aggiungi probabilità per non sparare ogni frame
		var rands_vec: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		rands_vec = rands_vec.rotated(rotation)
		apply_central_impulse(rands_vec * entropy)

	# 3. ROTAZIONE CASUALE
	if entropy > 30.0:
		apply_torque(randf_range(-1.0, 1.0) * entropy * 0.05)


	## 4. VISUAL
	#if randf() < entropy:
		#sprite.modulate = Color(
			#randf_range(0.7, 1.3),
			#randf_range(0.7, 1.3),
			#randf_range(0.7, 1.3)
		#)
		#sprite.scale = initial_scale * randf_range(0.9, 1.1)
#
#

func _handle_collision_resistance(state: PhysicsDirectBodyState2D) -> void:
	var max_resistance: float = 0.0

	for i: int in range(state.get_contact_count()):
		var collider: CelestialBody = state.get_contact_collider_object(i)
		if collider is CelestialBody:
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
		state.linear_velocity = state.linear_velocity.lerp(_last_velocity, max_resistance)


#
#func _handle_rotation() -> void:
	#var mouse_pos = get_global_mouse_position()
	#var dir = mouse_pos - global_position
#
	#if dir.length_squared() < 1.0:
		#angular_velocity = 0.0
		#return
#
	#var target_angle = dir.angle()
	#var angle_diff = wrapf(target_angle - rotation, -PI, PI)
#
	## PD controller semplice
	#var torque = angle_diff * rotation_responsiveness - angular_velocity * damping
#
	#apply_torque(torque)
#
func _handle_movement() -> void:
	var dir: Vector2 = _handle_mouse_input() if _handle_mouse_input().length() > 0.1 else get_input()

	if dir.length() > 0.1:
		apply_central_force(dir.normalized() * acceleration * mass)

	linear_velocity = linear_velocity.limit_length(speed)

# Aggiungi questa variabile in cima alla classe Player

#var do_print := false

# E poi modifica la funzione così:
#func _handle_gravity(state: PhysicsDirectBodyState2D) -> void:
	##_debug_timer += state.step
##
##if _debug_timer >= DEBUG_INTERVAL:
		##_debug_timer = 0.0
		##do_print = true
	## ===== GRAVITÀ =====
	#var gravity_accel: Vector2 = gravity_force / mass
	#var gravity_delta_v := gravity_accel * state.step
#
	#state.linear_velocity += gravity_delta_v  # ← applica direttamente
#
	## ===== MOVEMENT (STEERING) =====
	#var input_dir := get_input()
	#var mouse_dir := _handle_mouse_input()
	#var dir := mouse_dir if mouse_dir.length() > 0.1 else input_dir
#
	## rimuovi la componente di gravità dalla velocità
	#var planar_velocity := state.linear_velocity - gravity_delta_v
#
	#if dir.length() > 0.1:
		#planar_velocity += dir.normalized() * acceleration * state.step
#
	## clamp SOLO il movimento
	#planar_velocity = planar_velocity.limit_length(speed)
#
	## ricombina
	#state.linear_velocity = planar_velocity + gravity_delta_v
#
	##if do_print:
		##print("---- DEBUG ----")
		##print("Planar velocity:", planar_velocity.length())
		##print("Gravity Δv:", gravity_delta_v.length())
		##print("FINAL velocity:", state.linear_velocity.length())

func get_input() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")

#endregion

## Calcola e restituisce il danno del giocatore usando la legge dell'energia cinetica (E = 1/2 mv^2), scherzo, usando la quantità di moto (p = m * v)
func get_damage() -> float:
	var velocity: Vector2 = linear_velocity
	#var velocity_squared = linear_velocity.length_squared()

	print("massa: ", mass)
	print("velocità: ", velocity.length())

	#var kinetic_energy = 0.5 * mass * velocity_squared

	#var damage_scaling = 1000.0
	#var scaled_damage = kinetic_energy / damage_scaling
	var scaled_damage: float = mass * (velocity.length() * 0.005)

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
	if life_bar:
		life_bar.value = hp
	#life_bar.start_fade()

func _on_regen_timer_timeout() -> void:
	if hp == max_hp:
		return

	hp = min(hp + int(max_hp * 0.15), max_hp)

	_update_life_bar()

	regen_timer.wait_time = regen_tick
