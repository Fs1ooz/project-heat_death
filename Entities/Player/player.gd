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
@export var max_hp: int = int(UpgradeManager.get_current_power(UpgradeManager.UpgradeType.MAX_HEALTH))  ## Velocità massima (pixel/sec)
@export var hp: int = max_hp

@export var speed: float = UpgradeManager.get_current_power(UpgradeManager.UpgradeType.SPEED)  ## Velocità massima (pixel/sec)
@export var acceleration: float = UpgradeManager.get_current_power(UpgradeManager.UpgradeType.ACCELERATION)  ## Accelerazione lineare (pixel/sec²)

@export var sprite: Sprite2D
@export var trail: GPUParticles2D

@export var shockwave: ShockwaveRenderer
@onready var player_camera: PlayerCamera = $PlayerCamera
@onready var attraction_radius: float = $Attraction/CollisionShape2D.shape.radius

var rotation_responsiveness: float = 8.0

var auto_revive: bool = true
var _last_velocity: Vector2 = Vector2.ZERO

var gravity_force: Vector2 = Vector2.ZERO

var accumulated_forces: Vector2 = Vector2.ZERO

var energy_threshold: float = 300.0

var gravity: bool = true

@onready var hit_audio_stream_player: AudioStreamPlayer = $HitAudioStreamPlayer

var initial_radius: float
var initial_height: float
var initial_scale: Vector2
var initial_mass: float

var old_mass: float = 1.0
var mass_percentage: float = 1.0

@onready var initial_particle_scale: Vector2
@onready var mat: ParticleProcessMaterial = trail.process_material

var orbit_unlocked: bool = true

func _ready() -> void:
	UpgradeManager.tier_changed.connect(_on_tier_changed)
	initial_mass = mass
	initial_radius = collision.shape.radius
	initial_height = collision.shape.height
	initial_scale = sprite.scale
	initial_particle_scale = Vector2(mat.scale_min, mat.scale_max)

	if life_bar:
		life_bar.value = max_hp

	await get_tree().create_timer(2).timeout


var regen_time: float = 0.0
var regen_timer: float = 2.0

func _process(delta: float) -> void:
	if hp == max_hp:
		return
	else:
		regen_time += delta
		if regen_time > regen_timer:
			_start_regen()
			regen_time = 0.0
	if hp >= max_hp * 0.25:
		if $AnimationPlayer.current_animation == "low_health":
			GlobalSignals.low_health.emit(false)
			$AnimationPlayer.play("RESET")
	else:
		GlobalSignals.low_health.emit(true)
		$AnimationPlayer.play("low_health")




#region Movement
var base_scale: Vector2 = Vector2.ONE



var nearby_energy: Array = []
var nearby_bodies: Array = []




func _physics_process(delta: float) -> void:
	_attract(delta)

	_last_velocity = linear_velocity

	if EntropyManager.entropy_value < 0:
		apply_entropy(delta)

	_handle_movement()


var current_tween: Tween

func _handle_movement() -> void:
	var mouse_dir: Vector2 = _handle_mouse_input()
	var dir: Vector2 = mouse_dir if mouse_dir.length() > 0.2 else get_input()

	if dir.length() > 0.2:
		apply_central_force(dir.normalized() * acceleration * mass)
		# Passiamo true perché stiamo accelerando
		_animate_player(true)
	else:
		# Passiamo false perché siamo in inerzia/frenata
		_animate_player(false)

	linear_velocity = linear_velocity.limit_length(speed)


var is_stretched: bool = false

func _animate_player(is_accelerating: bool) -> void:
	if is_accelerating == is_stretched:
		return  # Già nello stato corretto

	if current_tween:
		current_tween.kill()

	is_stretched = is_accelerating
	current_tween = create_tween()

	if is_accelerating:
		var release_target: Vector2 = base_scale * Vector2(0.8, 1.2)
		current_tween.tween_property(sprite, "scale", release_target, 0.1)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		current_tween.tween_property(sprite, "scale", base_scale, 0.4)\
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		var release_target: Vector2 = base_scale * Vector2(0.9, 1.1)
		current_tween.tween_property(sprite, "scale", release_target, 0.15)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		current_tween.tween_property(sprite, "scale", base_scale, 0.3)\
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


var orbit_active: bool = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("space") and EntropyManager.entropy_value < 0:
		# Trigger shockwave usando la posizione modificata
		shockwave.trigger_shockwave(global_position, 3)
		EntropyManager.change_entropy(abs(EntropyManager.entropy_value) * 2)
		get_viewport().set_input_as_handled()
	if not orbit_unlocked:
		return
	if event.is_action_pressed("orbit"):
		printerr("PORCACCIO DI DIO PORCODIO")
		_activate_orbit()
	elif event.is_action_released("orbit"):
		_deactivate_orbit()


func _activate_orbit() -> void:
	orbit_active = true
	for body: CelestialBody in nearby_bodies:
		if body is SmallBody and body.orbit_state == SmallBody.OrbitState.FREE:
			body.start_attraction(self)

func _deactivate_orbit() -> void:
	orbit_active = false
	for body: CelestialBody in nearby_bodies:
		if body is SmallBody:
			if body.orbit_state == SmallBody.OrbitState.ATTRACTED \
			or body.orbit_state == SmallBody.OrbitState.ORBITING:
				body.leave_orbit()


func _attract(delta: float) -> void:
	if not orbit_active:
		return
	for energy: Energy in nearby_energy:
		if not is_instance_valid(energy):
			continue

		var distance: float = global_position.distance_to(energy.global_position)
		var normalized: float = clamp(distance / energy_threshold, 0.0, 1.0)

		var attraction_speed: float = lerp(500.0, 100.0, normalized) * delta * mass

		energy.global_position = energy.global_position.move_toward(
			global_position,
			attraction_speed
		)

	for body: CelestialBody in nearby_bodies:
		if not is_instance_valid(body):
			continue
		if body is SmallBody and body.orbit_state != SmallBody.OrbitState.FREE:
			continue  # questo manca
		var distance: float = global_position.distance_to(body.global_position)

		var direction: Vector2 = (global_position - body.global_position).normalized()

		var weight: float = clamp(distance / attraction_radius, 0.0, 1.0)
		var attraction_force: float = lerp(500.0, 100.0, weight) * sqrt(mass)

		body.apply_central_force(direction * attraction_force)


func _on_attraction_area_entered(area: Area2D) -> void:
	if area is Energy:
		nearby_energy.append(area)


func _on_attraction_area_exited(area: Area2D) -> void:
	if area is Energy:
		nearby_energy.erase(area)


func _on_attraction_body_entered(body: Node2D) -> void:
	if body is CelestialBody:
		nearby_bodies.append(body)
	if body is SmallBody and orbit_active:
		body.start_attraction(self)


func _on_attraction_body_exited(body: Node2D) -> void:
	if body is CelestialBody:
		nearby_bodies.erase(body)
	if body is SmallBody and body.orbit_state == SmallBody.OrbitState.ATTRACTED:
		body.leave_orbit()





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

var oscillation_speed: float = 1250.0   # Intensità della forza
var oscillation_frequency: float = 2.0  # Quante oscillazioni al secondo
var time_passed: float = 0.0            # Contatore del tempo


func apply_entropy(delta: float) -> void:
	var entropy: float = abs(EntropyManager.entropy_value)
	if entropy == 0.0:
		return

	time_passed += delta

	# 1. ONDULAZIONE CONTINUA (Esponenziale morbido, es: ^1.5)
	# A 10 = 31x; A 50 = 353x; A 100 = 1000x
	var force_multiplier: float = pow(entropy, 1.5)

	var oscillation: float = sin(time_passed * oscillation_frequency * TAU)  # -1..1
	var local_dir: Vector2 = Vector2(0, oscillation)
	var world_dir: Vector2 = local_dir.rotated(rotation)
	apply_central_force(world_dir * force_multiplier * oscillation_speed * mass)

	# 2. IMPULSI IMPROVVISI (Esponenziale aggressivo, es: ^2.0)
	# A 10 = 100x; A 50 = 2500x; A 100 = 10000x
	if entropy > 10.0 and randf() < 0.01:
		var impulse_multiplier: float = pow(entropy, 2.0)

		var rands_vec: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		rands_vec = rands_vec.rotated(rotation)
		apply_central_impulse(rands_vec * impulse_multiplier * mass)

	# 3. ROTAZIONE CASUALE (Esponenziale medio-alto, es: ^1.8)
	if entropy > 30.0:
		var torque_multiplier: float = pow(entropy, 1.8)

		# Ho aggiunto "* inertia" come ci dicevamo prima, fondamentale nello spazio!
		apply_torque(randf_range(-1.0, 1.0) * torque_multiplier * 0.05 * inertia)


func _handle_collision_resistance(state: PhysicsDirectBodyState2D) -> void:
	var max_resistance: float = 0.0
	var min_res_ratio: float = 0.5

	# Array temporaneo per accumulare i corpi da inglobare
	var bodies_to_engulf: Array[CelestialBody] = []

	for i: int in range(state.get_contact_count()):
		var collider: CelestialBody = state.get_contact_collider_object(i)

		# USA CONTINUE INVECE DI RETURN!
		if collider is not CelestialBody:
			continue

		var mass_ratio: float = mass / collider.mass
		player_camera.apply_shake(1.0 / mass_ratio, 0.75)


		# 1. NUOVA LOGICA: Ingloba se la massa è immensamente superiore (es. 10x)
		if mass_ratio >= 8.0:
			print("🌌 INGLOBATO: ", collider.name)
			bodies_to_engulf.append(collider)

		# 2. LOGICA ESISTENTE: Bulldozer mode (es. 5x)
		elif mass_ratio >= 4.0:
			max_resistance = 1.0
			print("💥 BULLDOZER MODE vs ", collider.name)
			break

		# 3. LOGICA ESISTENTE: Resistenza normale
		elif mass_ratio > min_res_ratio:
			var resistance: float = smoothstep(min_res_ratio, 3.0, mass_ratio)
			max_resistance = max(max_resistance, resistance)
			print("⚡ Resistenza: %.0f%% vs %s" % [resistance * 100, collider.name])
			_animate_player(false)

	# Applica la resistenza se necessaria
	if max_resistance > 0.0:
		state.linear_velocity = state.linear_velocity.lerp(_last_velocity, max_resistance)

	# Gestisci l'inglobamento al di fuori del calcolo della fisica
	for body: CelestialBody in bodies_to_engulf:
		_engulf_body(body)

@onready var engulf_audio_stream_player: AudioStreamPlayer = $EngulfAudioStreamPlayer

func _engulf_body(body: CelestialBody) -> void:
	UpgradeManager.gain_energy(body.game_energy)
	_start_regen()
	engulf_audio_stream_player.play()

	# Distruggi il nemico in modo sicuro usando call_deferred per non far arrabbiare la fisica
	if is_instance_valid(body) and not body.is_queued_for_deletion():
		body.queue_free.call_deferred()

func get_input() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")
#endregion

## Calcola e restituisce il danno del giocatore usando la legge dell'energia cinetica (E = 1/2 mv^2), scherzo, usando la quantità di moto (p = m * v)
func get_damage() -> float:
	var velocity: Vector2 = linear_velocity
	var scaled_damage: float = mass * (velocity.length() * 0.5)
	var round_base: int = 5
	#print("Danno originale: ", scaled_damage)
	var damage: int = maxi(snappedi(scaled_damage, round_base), 1)

	return damage


func _on_tier_changed()-> void:
	sprite.material.set_shader_parameter("frequency", sprite.material.get_shader_parameter("frequency") * 1.2)


func change_size(amount: float) -> void:

	change_mass(amount)
	change_scale(amount)
	$Attraction/CollisionShape2D.shape.radius *= amount

	energy_threshold *= amount

func change_mass(amount: float) -> void:
	old_mass = mass
	mass *= amount
	mass_percentage = mass / old_mass


func change_scale(amount: float) -> void:
	printerr("cambio? essì")
	var scale_change: Vector2 = base_scale * amount
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



	var tween: Tween = create_tween()
	tween.tween_property(sprite, "scale", scale_change, 1.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	base_scale = scale_change



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
	regen_time = 0.0
	update_life_bar()
	if hp <= 0:
		if auto_revive:
			printerr("RINATO!!")
			auto_revive = false
			hp = 1
		else:
			game_over()


func game_over() -> void:
	GlobalSignals.game_over.emit()
	queue_free()


func update_life_bar() -> void:
	if life_bar:
		# 1. Aggiorna sempre il massimo prima
		if life_bar.max_value != max_hp:
			life_bar.max_value = max_hp

		# 2. Poi aggiorna il valore attuale
		life_bar.value = hp


func _start_regen() -> void:
	hp = min(hp + int(max_hp * 0.15), max_hp)
	update_life_bar()
