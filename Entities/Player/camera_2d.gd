extends Camera2D

@export var zoom_speed: float = 1.05
@export_group("Zoom Limits (Base Values)")
@export var min_zoom_base: float = 0.001  # Limite minimo quando player.scale = 1
@export var max_zoom_base: float = 2.0  # Limite massimo quando player.scale = 1
@export_group("Zoom Settings")
@export var base_zoom: Vector2 = Vector2.ONE * 0.5
@export var zoom_lerp_speed: float = 2.15
@export var manual_zoom_timeout: float = 2.0

var manual_zoom: bool = false
var last_zoom_input_time: float = 0.0

# Limiti dinamici calcolati
var min_zoom: float
var max_zoom: float
var forward_offset: float = 200.0

var zoom_value_multiplier: float = 0.5


@onready var player: Player = get_parent()


func _ready() -> void:
	make_current()

func _process(delta: float) -> void:
	# 1. Calcoli preliminari (Offset e limiti basati sulla scala)
	var forward: Vector2 = Vector2.RIGHT.rotated(player.rotation)
	offset = offset.lerp(forward * forward_offset, 0.02)

	var player_scale: float = max(player.sprite.scale.x, 0.01)
	min_zoom = min_zoom_base / player_scale
	max_zoom = max_zoom_base / player_scale

	# 2. Logica di Zoom dinamico basato sull'input
	if not manual_zoom:
		# Partiamo dallo zoom base (quello che vuoi da fermo)
		var target_zoom_value: Vector2 = base_zoom / player_scale

		# Recuperiamo la direzione dell'input (camminata)
		var mouse_dir: Vector2 = player._handle_mouse_input()
		var dir: Vector2 = mouse_dir if mouse_dir.length() > 0.2 else player.get_input()

		# SE C'È INPUT DI MOVIMENTO: Dezooma (riduciamo il valore di zoom)
		if dir.length() > 0.1:
			# Se vuoi che dezoomi di più, usa un numero più piccolo (es. 0.5)
			target_zoom_value *= zoom_value_multiplier

		# Applichiamo lo zoom in modo fluido
		# zoom_lerp_speed controlla quanto è "morbida" la transizione (prova 2.0 o 3.0)
		zoom = zoom.lerp(target_zoom_value, zoom_lerp_speed * delta)

	# 3. Controllo timeout manuale (già presente nel tuo codice)
	if manual_zoom and Time.get_ticks_msec() / 1000.0 - last_zoom_input_time > manual_zoom_timeout:
		manual_zoom = false

	# 4. Clamp finale (per restare nei limiti di sicurezza)
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
