extends CharacterBody2D
class_name Player

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


func get_input() -> Vector2:
	var input_dir = Input.get_vector("left", "right", "up", "down")
	return input_dir

func play_hit_sound():
	audio_stream_player_2d.play()
