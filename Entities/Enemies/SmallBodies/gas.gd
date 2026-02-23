class_name Gas
extends GPUParticles2D

var player_inside: Player = null
var damage_time: float = 0.2
var timer: float = 0.0

@onready var initial_particle_scale: Vector2 = Vector2(process_material.scale_min, process_material.scale_max)

@onready var gas_area: Area2D = $GasArea

func _ready() -> void:
	if process_material:
		process_material = process_material.duplicate()

func _process(delta: float) -> void:
	if player_inside == null:
		return
	timer += delta
	if timer >= damage_time:
		var damage: int = int(10)
		printerr("sto danneggiando ", damage)
		player_inside.take_damage(damage)

		timer = 0.0


func _on_gas_body_entered(body: Node2D) -> void:
	if body is Player:
		player_inside = body
		timer = 0.0
		print("Player entered gas")


func _on_gas_body_exited(body: Node2D) -> void:
	if body is Player and player_inside == body:
		player_inside = null
		timer = 0.0
		print("Player exited gas")
