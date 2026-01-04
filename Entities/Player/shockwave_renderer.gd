extends ColorRect

var shockwaves: Array = []
var original_pos = global_position


func _ready() -> void:
	# Initialize shader parameters with empty arrays
	material.set_shader_parameter("shockwave_positions", [])
	material.set_shader_parameter("shockwave_progresses", [])
	material.set_shader_parameter("shockwave_count", 0)

func _process(delta: float) -> void:
	if shockwaves.size() > 0:
		var positions: Array = []
		var progresses: Array = []
		var i: int = 0

		# Update each shockwave
		while i < shockwaves.size():
			var shockwave = shockwaves[i]
			shockwave.progress += delta
			if shockwave.progress > 1.5: # Adjust for duration
				shockwaves.remove_at(i)
			else:
				positions.append(shockwave.position)
				progresses.append(shockwave.progress)
				i += 1

		# Update shader parameters
		material.set_shader_parameter("shockwave_positions", positions)
		material.set_shader_parameter("shockwave_progresses", progresses)
		material.set_shader_parameter("shockwave_count", shockwaves.size())
	else:
		# Clear shader parameters when no shockwaves are active
		material.set_shader_parameter("shockwave_positions", [])
		material.set_shader_parameter("shockwave_progresses", [])
		material.set_shader_parameter("shockwave_count", 0)


func trigger_shockwave(target_global_position: Vector2, shockwave_amount: int) -> void:
	global_position = target_global_position + original_pos * scale
	scale = get_parent().scale
	var viewport = get_viewport()
	var viewport_pos = viewport.get_canvas_transform() * target_global_position
	var viewport_size = viewport.get_visible_rect().size
	var normalized_pos = Vector2(
		viewport_pos.x / viewport_size.x,
		viewport_pos.y / viewport_size.y
	)

	# Add new shockwave to the array
	for i in shockwave_amount:
		var shockwave = {
		"position": normalized_pos,
		"progress": -i * 0.12  # offset temporale
		}
		shockwaves.append(shockwave)

	# Update shader parameters immediately
	var positions: Array = []
	var progresses: Array = []
	for sw in shockwaves:
		positions.append(sw.position)
		progresses.append(sw.progress)
	material.set_shader_parameter("shockwave_positions", positions)
	material.set_shader_parameter("shockwave_progresses", progresses)
	material.set_shader_parameter("shockwave_count", shockwaves.size())
