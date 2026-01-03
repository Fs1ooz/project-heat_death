extends Node

@onready var shockwave_renderer: ColorRect = $ShockwaveRenderer

#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("space"):
		#trigger_shockwave(Vector2(480,480), 3)

func trigger_shockwave(target_global_position: Vector2, shockwave_amount: int) -> void:
	shockwave_renderer.trigger_shockwave(target_global_position, shockwave_amount)
