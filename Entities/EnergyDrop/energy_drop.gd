extends Area2D

var energy: int = 10
var threshold: float = 500.0

@onready var player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not player:
		return
	var distance = global_position.distance_to(player.global_position)
	if distance < threshold:
		var speed = threshold * (1.0 - distance / threshold) * delta
		global_position = global_position.move_toward(player.global_position, speed)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		UpgradeManager.gain_energy(energy)
		queue_free()
