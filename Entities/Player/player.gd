class_name Player
extends RigidBody2D
## Il codice del giocatore per RigidBody2D, per simulare meglio la fisica forse tocca usare questo
## - Mode: Character
## - Gravity Scale: 0 (per top-down)
## - Mass: 1 (regolare a piacere)

@export var life_bar: ProgressBar
@export var alignment_safe_zone: float = 0.8
@export var collision_shape: CollisionShape2D
## Configurazione movimento
var max_hp: int = 100
var hp: int = 100
var speed: float = 700.0 ## Velocità massima (pixel/sec)
var acceleration: float = 500.0 ## Accelerazione lineare (pixel/sec²)
var rotation_responsiveness: float = 10.0 ## Responsività della rotazione verso il mousewwwwwwwwwwwwws
var regen_tick: float = 3.0
var auto_revive: bool = true
var _last_velocity: Vector2 = Vector2.ZERO
## Safe zone per allineamento completo
@onready var regen_timer: Timer = $RegenTimer


@onready var hit_audio_stream_player: AudioStreamPlayer = $HitAudioStreamPlayer


func _ready() -> void:
	life_bar.value = max_hp

func _physics_process(_delta: float) -> void:
	# Salva la velocità PRIMA che la fisica modifichi tutto
	_last_velocity = linear_velocity


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:

	# Rotazione verso il mouse
	_handle_rotation(state)

	# Movimento WASD
	_handle_movement(state)

	# NUOVA LOGICA: Contrasta l'effetto delle collisioni in base alla massa
	_handle_collision_resistance(state)

func _handle_collision_resistance(state: PhysicsDirectBodyState2D) -> void:
	var max_resistance: float = 0.0

	# Trova la resistenza massima tra tutte le collisioni
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if collider is CelestialBody:
			var mass_ratio = mass / collider.mass
			if mass_ratio >= 5.0:
				max_resistance = 1.0
				print("💥 BULLDOZER MODE vs ", collider.name)
				break  # Non può essere più alto di 1
			elif mass_ratio > 1.0:

				var resistance = smoothstep(1.0, 3.0, mass_ratio)   # built-in Godot
				max_resistance = max(max_resistance, resistance)
				print("⚡ Resistenza: %.0f%% vs %s" % [resistance * 100, collider.name])


	if max_resistance > 0.0:
		state.linear_velocity = state.linear_velocity.lerp(_last_velocity, max_resistance)

func _handle_rotation(state: PhysicsDirectBodyState2D) -> void:
	var mouse_pos = get_global_mouse_position()
	var dir = mouse_pos - global_position

	# Non ruotare se il mouse è troppo vicino
	if dir.length_squared() < 1.0:
		state.angular_velocity = 0.0
		return

	var target_angle = dir.angle()
	var angle_diff = wrapf(target_angle - rotation, -PI, PI)

	# Imposta velocità angolare direttamente
	state.angular_velocity = angle_diff * rotation_responsiveness


func _handle_movement(state: PhysicsDirectBodyState2D) -> void:
	var input_dir: Vector2 = get_input()
	var mouse_dir = _handle_mouse_input()
	# Calcola velocità target
	var target_velocity: Vector2
	var movement_angle: float = input_dir.angle()
	if mouse_dir:
		movement_angle = mouse_dir.angle()
		target_velocity = mouse_dir  * speed
	else:
		movement_angle = input_dir.angle()
		target_velocity = input_dir * speed


	var alignment: float = cos(rotation - movement_angle)

	# Applica safe zone
	if alignment > alignment_safe_zone:
		alignment = 1.0

	# Fattore velocità basato su allineamento
	var speed_factor: float = remap(alignment, -1.0, 1.0, 0.2, 1.0)
	target_velocity *= speed_factor
	# Interpola verso la velocità target
	var current_velocity: Vector2 = state.linear_velocity
	var new_velocity: Vector2

	new_velocity = current_velocity.move_toward(target_velocity, acceleration * state.step)

	state.linear_velocity = new_velocity


## Restituisce un vettore normalizzato (modulo = 1) per l'input WASD.
func get_input() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")


## Calcola e restituisce il danno del giocatore usando la legge dell'energia cinetica (E = 1/2 mv^2), scherzo, usando la quantità di moto (p = m * v)
func get_damage() -> float:
	var velocity = linear_velocity.length()
	#var velocity_squared = linear_velocity.length_squared()

	print("massa: ", mass)
	print("velocità: ",velocity)

	#var kinetic_energy = 0.5 * mass * velocity_squared

	#var damage_scaling = 1000.0
	#var scaled_damage = kinetic_energy / damage_scaling
	var scaled_damage = mass * (velocity * 0.005)

	var round_base = 5
	print("Danno originale: ", scaled_damage)

	var damage = maxi(snappedi(scaled_damage, round_base), 1)

	print("Danno finale: ", damage)

	return damage


func change_size(amount: float) -> void:
	print(collision_shape.scale)
	var tween = create_tween()
	var scale_change = collision_shape.scale * amount
	tween.tween_property(collision_shape,"scale",scale_change, 0.1)

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
