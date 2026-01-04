extends Camera2D

@export var zoom_speed: float = 1.05
@export_group("Zoom Limits (Base Values)")
@export var min_zoom_base: float = 0.01  # Limite minimo quando player.scale = 1
@export var max_zoom_base: float = 2.0  # Limite massimo quando player.scale = 1
@export_group("Zoom Settings")
@export var base_zoom: Vector2 = Vector2.ONE * 0.25
@export var zoom_lerp_speed: float = 5.0
@export var manual_zoom_timeout: float = 2.0

var manual_zoom: bool = false
var last_zoom_input_time: float = 0.0

# Limiti dinamici calcolati
var min_zoom: float
var max_zoom: float

@onready var player: Player = get_parent()

func _ready() -> void:
	make_current()

func _process(delta: float) -> void:
	# Calcola i limiti di zoom dinamicamente in base alla scala del player
	var player_scale: float = max(player.sprite.scale.x, 0.01)
	min_zoom = min_zoom_base / player_scale
	max_zoom = max_zoom_base / player_scale

	# Controlla timeout
	if manual_zoom and Time.get_ticks_msec() / 1000.0 - last_zoom_input_time > manual_zoom_timeout:
		manual_zoom = false

	if not manual_zoom:
		# Calcola target zoom e CLAMPALO
		var target_zoom: Vector2 = base_zoom / player_scale
		target_zoom.x = clamp(target_zoom.x, min_zoom, max_zoom)
		target_zoom.y = clamp(target_zoom.y, min_zoom, max_zoom)
		zoom = zoom.lerp(target_zoom, zoom_lerp_speed * delta)

	# Clamp finale con i limiti dinamici
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			manual_zoom = true
			last_zoom_input_time = Time.get_ticks_msec() / 1000.0
			zoom /= zoom_speed

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			manual_zoom = true
			last_zoom_input_time = Time.get_ticks_msec() / 1000.0
			zoom *= zoom_speed

		# Clamp immediato con limiti dinamici
		zoom.x = clamp(zoom.x, min_zoom, max_zoom)
		zoom.y = clamp(zoom.y, min_zoom, max_zoom)
