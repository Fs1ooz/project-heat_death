extends Camera2D

@export var zoom_speed: float = 1.1  # Moltiplicatore (1.1 = 10% per scroll)
@export var min_zoom: float = 0.000000000000000001  # Quanto piccolo può diventare
@export var max_zoom: float = 2.0       # Quanto grande può diventare

func _ready() -> void:
	make_current()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Zoom out (dividi per rendere più piccolo)
			zoom /= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# Zoom in (moltiplica per rendere più grande)
			zoom *= zoom_speed

		# Clamp per limitare i valori
		zoom.x = clamp(zoom.x, min_zoom, max_zoom)
		zoom.y = clamp(zoom.y, min_zoom, max_zoom)
