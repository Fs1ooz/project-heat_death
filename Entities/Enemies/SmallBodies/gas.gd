extends Area2D

		# Lista dei player dentro il gas
var bodies_inside: Array[Player] = []

@onready var mat: ParticleProcessMaterial = $GasParticles.process_material


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		bodies_inside.append(body)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		bodies_inside.erase(body)

func _process(delta: float) -> void:
	for body: Node2D in bodies_inside:
		body.take_damage(body.get_damage() * delta)
