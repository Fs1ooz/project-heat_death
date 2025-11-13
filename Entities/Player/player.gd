class_name Player
extends CharacterBody2D
## Hierarchical State machine for the player.
##
## Initializes states and delegates engine callbacks ([method Node._physics_process],
## [method Node._unhandled_input]) to the state.



var speed: float = 700.0
var acceleration: float = 350.0
var damage: float = 50.0
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

## Restituisce un vettore che rappresenta la direzione dell’input (WASD o frecce).
## Il vettore è normalized, quindi sarà di lunghezza ≤ 1.
func get_input() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")


func play_hit_sound():
	audio_stream_player_2d.play()
