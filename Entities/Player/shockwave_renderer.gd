class_name ShockwaveRenderer
extends ColorRect

var shockwaves: Array = []
var original_pos: Vector2 = global_position
@onready var player: Player = get_tree().get_first_node_in_group("player")

@onready var player_camera: Camera2D = $"../../../PlayerCamera"

func _ready() -> void:
	# Initialize shader parameters with empty arrays
	material.set_shader_parameter("shockwave_positions", [])
	material.set_shader_parameter("shockwave_progresses", [])
	material.set_shader_parameter("shockwave_count", 0)

func _process(delta: float) -> void:
	var rect_transform: Transform2D = get_global_transform()
	if shockwaves.size() > 0:
		var positions: Array = []
		var progresses: Array = []
		var i: int = 0

		# Update each shockwave
		while i < shockwaves.size():
			var shockwave: Dictionary = shockwaves[i]

			# NOVITÀ: Finché è in attesa, aggiorna la posizione a quella del player
			if shockwave.progress <= 0.0:
				shockwave.world_position = get_parent().global_position

			shockwave.progress += delta
			if shockwave.progress > 1.5:
				shockwaves.remove_at(i)
			else:
				# NOVITÀ: Calcola le UV usando il ColorRect, zero ritardi
				var local_pos: Vector2 = rect_transform.affine_inverse() * shockwave.world_position
				var uv_pos: Vector2 = local_pos / size

				positions.append(uv_pos)
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
	scale = player.base_scale

	for i: int in shockwave_amount:
		var shockwave: Dictionary = {
			"world_position": target_global_position, # Salva la posizione globale, non normalizzata
			"progress": -i * 0.125
		}
		shockwaves.append(shockwave)

	# (Puoi rimuovere anche i material.set_shader_parameter da qui, li gestirà _process)

#

	#print("target_global: ", target_global_position)
	#print("viewport_pos: ", viewport_pos)
	#print("normalized: ", normalized_pos)
	#print("canvas_transform: ", viewport.get_canvas_transform())
	#print("screen_transform: ", viewport.get_screen_transform())
#
	## Add new shockwave to the array
	#for i: int in shockwave_amount:
		#var shockwave: Dictionary = {
		#"position": normalized_pos,
		#"progress": -i * 0.12  # offset temporale
		#}
		#shockwaves.append(shockwave)
#
	## Update shader parameters immediately
	#var positions: Array = []
	#var progresses: Array = []
	#for sw: Dictionary in shockwaves:
		#positions.append(sw.position)
		#progresses.append(sw.progress)
	#material.set_shader_parameter("shockwave_positions", positions)
	#material.set_shader_parameter("shockwave_progresses", progresses)
	#material.set_shader_parameter("shockwave_count", shockwaves.size())
