extends Camera2D

@export var zoom_speed: float = 2.0
@export var max_zoom: float = 2.0

var scale_factor: float = 1.0

func _ready() -> void:
	make_current()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scale_factor += zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scale_factor = max(1.0, scale_factor - zoom_speed)

		# Convertiamo il fattore in zoom (sempre calcolato, mai sommato direttamente)
		var z = 1.0 / scale_factor
		z = clamp(z, 1.0 / 1_000_000.0, max_zoom)  # limite piccolo enorme senza float issues
		zoom = Vector2(z, z)
