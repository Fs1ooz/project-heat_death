class_name RotationComponent
extends Node

@export var base_speed: float = 1.0
var speed: float = base_speed

var _sprite: AnimatedSprite2D = null

func setup(sprite: AnimatedSprite2D) -> void:
	_sprite = sprite
	var frame_count: int = _sprite.sprite_frames.get_frame_count(_sprite.animation)
	_sprite.frame = randi() % frame_count

func _process(_delta: float) -> void:
	if _sprite:
		_sprite.speed_scale = speed

func reset(duration: float = 0.5) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "speed", base_speed, duration) \
		.set_trans(Tween.TRANS_SPRING)

func windup(duration: float) -> void:
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "speed", 400.0, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "speed", base_speed, 0.25) \
		.set_delay(duration)

func freeze(duration: float = 0.2) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "speed", 0.01, duration)
