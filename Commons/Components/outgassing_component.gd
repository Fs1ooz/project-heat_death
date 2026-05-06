class_name OutgassingComponent
extends Node

@export var outgassing_impulse: float = 500.0
@export var activate_impulse: bool = false
@export var offset_multiplier: float = 0.85
@export var gas_scenes: Array[PackedScene] = [preload("uid://uf4irjwjm6pd"), preload("uid://cmh6regh1ook3")]


var _gasses: Array[Gas] = []
var _body: RigidBody2D = null
var _sprite: Node2D = null


func setup(body: RigidBody2D, sprite: Node2D) -> void:
	_body = body
	_sprite = sprite


func _pick_scene() -> PackedScene:
	return gas_scenes[randi() % gas_scenes.size()]


func prespawn(spawn_points_count: int) -> void:
	if gas_scenes.is_empty() or not _body or not _sprite:
		return
	for i: int in range(spawn_points_count):
		var gas: Gas = _pick_scene().instantiate()
		var angle: float = randf_range(0.0, TAU)
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		_sprite.add_child(gas)
		var scale_factor: float = _sprite.scale.x * 0.8
		gas.global_position = _body.global_position
		var sprite_radius: float
		if _sprite is AnimatedSprite2D:
			var tex: AtlasTexture = _sprite.sprite_frames.get_frame_texture(_sprite.animation, 0)
			sprite_radius = tex.get_width() / 2.0
		else:
			sprite_radius = _sprite.texture.get_width() / 2.0
		gas.position = direction * sprite_radius * offset_multiplier
		gas.rotation = angle
		if gas.process_material:
			gas.process_material.scale_min = gas.initial_particle_scale.x * scale_factor
			gas.process_material.scale_max = gas.initial_particle_scale.y * scale_factor
		gas.set_meta("direction", direction)
		gas.set_process(false)
		gas.emitting = false
		gas.visible = false
		_gasses.append(gas)


func activate() -> void:
	for gas: Gas in _gasses:
		if not gas.emitting:
			gas.set_process(true)
			gas.emitting = true
			gas.visible = true
			var direction: Vector2 = gas.get_meta("direction", Vector2.RIGHT)
			_body.apply_impulse(-direction.rotated(_body.rotation) * outgassing_impulse * EntropyManager.entropy_value)
			break


func activate_all() -> void:
	for gas: Gas in _gasses:
		if not gas.emitting:
			gas.set_process(true)
			gas.visible = true
			gas.emitting = true
			var direction: Vector2 = gas.get_meta("direction", Vector2.RIGHT)
			_body.apply_impulse(-direction.rotated(_body.rotation) * outgassing_impulse * EntropyManager.entropy_value)


func stop() -> void:
	for gas: Gas in _gasses:
		gas.emitting = false
		gas.visible = false


func erase_spawn_points() -> void:
	for gas: Gas in _gasses:
		gas.queue_free()
	_gasses.clear()
