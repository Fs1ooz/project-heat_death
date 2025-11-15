class_name Player
extends RigidBody2D
## Il codice del giocatore per RigidBody2D, per simulare meglio la fisica forse tocca usare questo
## - Mode: Character
## - Gravity Scale: 0 (per top-down)
## - Mass: 1 (regolare a piacere)


## Configurazione movimento
var speed: float = 700.0 ## Velocità massima (pixel/sec)
var acceleration: float = 500.0 ## Accelerazione lineare (pixel/sec²)
var rotation_responsiveness: float = 10.0 ## Responsività della rotazione verso il mousewwwwwwwwwwwwws

## Safe zone per allineamento completo
@export var alignment_safe_zone: float = 0.8
@export var collision_shape: CollisionShape2D
@onready var trail_2d: Line2D = $Trail2D

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D



func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	## Questa funzione è chiamata ad ogni step della fisica

	# Rotazione verso il mouse
	_handle_rotation(state)

	# Movimento WASD
	_handle_movement(state)


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
	if mouse_dir:
		target_velocity = mouse_dir  * speed
	else:
		target_velocity = input_dir * speed

	var movement_angle: float = input_dir.angle()
	var alignment: float = cos(rotation - movement_angle)

	# Applica safe zone
	if alignment > alignment_safe_zone:
		alignment = 1.0

	# Fattore velocità basato su allineamento
	var speed_factor: float = remap(alignment, -1.0, 1.0, 0.5, 1.0)
	target_velocity *= speed_factor

	# Interpola verso la velocità target
	var current_velocity: Vector2 = state.linear_velocity
	var new_velocity: Vector2 = current_velocity.move_toward(target_velocity, acceleration * state.step)
	state.linear_velocity = new_velocity


## Restituisce un vettore normalizzato (modulo = 1) per l'input WASD.
func get_input() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")


## Calcola e restituisce il danno del giocatore usando la legge dell'energia cinetica (E = 1/2 mv^2)
func get_damage() -> float:
	var velocity = linear_velocity.length_squared()
	print("massa: ", mass)
	print("velocità: ",velocity)
	var kinetic_energy = 0.5 * mass * velocity

	var damage_scaling = 100.0
	var scaled_damage = kinetic_energy / damage_scaling

	var round_base = 50
	print("Danno originale: ", scaled_damage)
	# Arrotonda al multiplo più vicino
	var damage = round(scaled_damage / round_base) * round_base
	print("Danno finale: ", damage)
	return damage


func change_size(amount: float) -> void:
	print(collision_shape.scale)
	var point = trail_2d.width_curve.get_point_position(0).y
	trail_2d.width_curve.set_point_value(0, point * amount)
	collision_shape.scale = collision_shape.scale * amount

## Riproduce il suono di hit.
func play_hit_sound() -> void:
	audio_stream_player_2d.play()


func _handle_mouse_input() -> Vector2:
	# Se non sto premendo il tasto sinistro, nessun movimento
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return Vector2.ZERO

	# Direzione dal player verso il mouse
	var mouse_dir: Vector2 = (get_global_mouse_position() - global_position).normalized()

	# Ritorna la direzione * speed
	return mouse_dir
