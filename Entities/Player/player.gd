class_name Player
extends CharacterBody2D
## Il codice del giocatore
## Insomma un test per vedere come funzionano i commenti


var speed: float = 700.0 ## Velocità del giocatore
var acceleration: float = 350.0 ## Accelerazione del giocatore
var damage: float = 50.0 ## Danno del giocatore
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var dir = mouse_pos - global_position
	rotation = dir.angle()


func _physics_process(delta) -> void:
	var new_velocity = get_input() * speed
	velocity.x = move_toward(velocity.x, new_velocity.x, acceleration * delta)
	velocity.y = move_toward(velocity.y, new_velocity.y, acceleration * delta)
	move_and_collide(velocity * delta)

## Restituisce un vettore normalized (modulo = 1) che rappresenta la direzione dell’input (in questo caso WASD).
func get_input() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")

## Riproduce il suono di hit.
func play_hit_sound() -> void:
	audio_stream_player_2d.play()
