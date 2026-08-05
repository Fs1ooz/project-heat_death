class_name ShockwaveRenderer
extends MeshInstance2D

## Durata di vita di un'onda: oltre questo progresso viene scartata.
const LIFETIME: float = 1.5
## Sfasamento temporale tra un'onda e la successiva dello stesso trigger.
const WAVE_DELAY: float = 0.125

var shockwaves: Array = []

@onready var player: Player = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	# Initialize shader parameters with empty arrays
	material.set_shader_parameter("shockwave_positions", [])
	material.set_shader_parameter("shockwave_progresses", [])
	material.set_shader_parameter("shockwave_count", 0)


func _process(delta: float) -> void:
	if shockwaves.is_empty():
		return

	# Il quad è centrato sull'origine del nodo: spazia da -size/2 a +size/2.
	var quad_size: Vector2 = (mesh as QuadMesh).size
	var positions: Array = []
	var progresses: Array = []
	var i: int = 0

	# Update each shockwave
	while i < shockwaves.size():
		var shockwave: Dictionary = shockwaves[i]

		# Finché è in attesa, aggiorna la posizione a quella del player
		if shockwave.progress <= 0.0:
			shockwave.world_position = get_parent().global_position

		shockwave.progress += delta
		if shockwave.progress > LIFETIME:
			shockwaves.remove_at(i)  # remove_at scala gli indici: non incrementare i
			continue

		# to_local() è già lo spazio del quad (scala inclusa): centro = (0,0) → UV (0.5, 0.5)
		positions.append(to_local(shockwave.world_position) / quad_size + Vector2(0.5, 0.5))
		progresses.append(shockwave.progress)
		i += 1

	# Update shader parameters (con 0 onde superstiti azzera anche il count)
	material.set_shader_parameter("shockwave_positions", positions)
	material.set_shader_parameter("shockwave_progresses", progresses)
	material.set_shader_parameter("shockwave_count", shockwaves.size())


func trigger_shockwave(target_global_position: Vector2, shockwave_amount: int) -> void:
	# Nodo top_level e quad centrato: basta piazzarlo sul punto d'origine dell'onda.
	global_position = target_global_position
	scale = player.base_scale

	for i: int in shockwave_amount:
		var shockwave: Dictionary = {
			"world_position": target_global_position,  # posizione globale, non normalizzata
			"progress": -i * WAVE_DELAY,
		}
		shockwaves.append(shockwave)
