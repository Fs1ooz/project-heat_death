extends Camera2D

@export var zoom_speed: float = 1.1
@export var min_zoom: float = 0.00000001
@export var max_zoom: float = 2.0
@export var base_zoom: Vector2 = Vector2.ONE * 0.3
@export var zoom_lerp_speed := 5.0
@export var manual_zoom_timeout := 1.5  # Secondi di inattività

var manual_zoom: bool = false
var last_zoom_input_time: float = 0.0

@onready var player = get_parent()

func _ready() -> void:
	make_current()

func _process(delta):
	# Controlla se è passato abbastanza tempo dall'ultimo input
	if manual_zoom and Time.get_ticks_msec() / 1000.0 - last_zoom_input_time > manual_zoom_timeout:
		manual_zoom = false

	var target_zoom = base_zoom / player.sprite.scale.x
	if not manual_zoom:
		zoom = zoom.lerp(target_zoom, zoom_lerp_speed * delta)

	print("playerscale: ",player.sprite.scale.x, " targetzoom: ", target_zoom)

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

		# Clamp per limitare i valori
		zoom.x = clamp(zoom.x, min_zoom, max_zoom)
		zoom.y = clamp(zoom.y, min_zoom, max_zoom)
