#class_name Player
extends CharacterBody2D
## Il codice del giocatore
## Insomma un test per vedere come funzionano i commenti


var speed: float = 700.0 ## Velocità del giocatore
var acceleration: float = 350.0 ## Accelerazione del giocatore
var damage: float = 50.0 ## Danno del giocatore
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var dir = mouse_pos - global_position
	if rotation != dir.angle():
		rotation = rotate_toward(rotation, dir.angle(), acceleration/100 * delta )


func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = get_input()

	var target_velocity: Vector2 = input_dir * speed

	var movement_angle: float = input_dir.angle()
	var alignment: float = cos(rotation - movement_angle)

	var safe_zone: float = 0.8
	if alignment > safe_zone:
		alignment = 1.0

	var speed_factor: float = remap(alignment, -1.0, 1.0, 0.5, 1.0)
	target_velocity *= speed_factor

	velocity = velocity.move_toward(target_velocity, acceleration * delta)
	move_and_collide(velocity * delta)


## Restituisce un vettore normalized (modulo = 1) che rappresenta la direzione dell’input (in questo caso WASD).
func get_input() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")



## Riproduce il suono di hit.
func play_hit_sound() -> void:
	audio_stream_player_2d.play()
