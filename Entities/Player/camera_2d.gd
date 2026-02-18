class_name PlayerCamera
extends Camera2D

@export var zoom_speed: float = 1.05
@export_group("Zoom Limits (Base Values)")
@export var min_zoom_base: float = 0.001
@export var max_zoom_base: float = 2.0

@export_group("Zoom Settings")
@export var base_zoom: Vector2 = Vector2.ONE * 0.5
@export var zoom_lerp_speed: float = 2.15
@export var manual_zoom_timeout: float = 2.0
@export var zoom_value_multiplier: float = 0.5 # Moltiplicatore quando ti muovi

var manual_zoom: bool = false
var last_zoom_input_time: float = 0.0

# Limiti dinamici
var min_zoom: float
var max_zoom: float
var forward_offset: float = 250.0

# Variabili di stato
@onready var player: Player = get_parent()
var player_scale: float = 1.0
var tier_base_zoom: Vector2 # Questo è il "Target Zoom Value" di base per il Tier attuale

# Shake
var shake_intensity: float = 0.0
var active_shake_time: float = 0.0
var shake_decay: float = 5.0
var shake_time: float = 0.0
var shake_time_speed: float = 30.0
@export var noise: FastNoiseLite


var base_offset: Vector2 = Vector2.ZERO
var shake_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	UpgradeManager.tier_changed.connect(_on_tier_changed)
	randomize()
	noise.seed = randi()
	make_current()

	# Inizializziamo subito i valori corretti
	_on_tier_changed()

func _on_tier_changed() -> void:
	# 1. Aggiorniamo la scala
	player_scale = max(player.sprite.scale.x, 0.01)

	# 2. Calcoliamo il NUOVO zoom di riposo basato sul Tier.
	# Questo valore rimarrà fisso finché non cambi di nuovo Tier.
	tier_base_zoom = base_zoom / player_scale

	# Aggiorniamo anche i limiti
	min_zoom = min_zoom_base / player_scale
	max_zoom = max_zoom_base / player_scale

func _process(delta: float) -> void:

	var mouse_dir: Vector2 = player._handle_mouse_input()
	var dir: Vector2 = mouse_dir if mouse_dir.length() > 0.2 else player.get_input()
	var forward: Vector2 = Vector2.RIGHT.rotated(player.rotation)
	# --- Offset ---
	if dir.length() > 0.1:
		base_offset = base_offset.lerp(forward * forward_offset, 0.02)
	else:
		base_offset = base_offset.lerp(Vector2.ZERO, 0.02)

	# --- Logica Zoom ---
	if not manual_zoom:
		# Partiamo SEMPRE dal valore base del Tier attuale
		var current_frame_target: Vector2 = tier_base_zoom

		# Controlliamo il movimento
		if dir.length() > 0.1:
			# Se ci muoviamo, applichiamo il moltiplicatore TEMPORANEO a una copia locale
			current_frame_target *= zoom_value_multiplier

		# Interpoliamo verso il target calcolato per questo frame
		zoom = zoom.lerp(current_frame_target, zoom_lerp_speed * delta)

	# --- Timeout Manuale ---
	if manual_zoom and Time.get_ticks_msec() / 1000.0 - last_zoom_input_time > manual_zoom_timeout:
		manual_zoom = false

	# --- Clamp Finale ---
	# Ci assicuriamo che lo zoom non esca dai limiti calcolati per il Tier
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)

	# --- Shake ---
	if active_shake_time > 0:
		shake_time += delta * shake_time_speed
		active_shake_time -= delta
		shake_offset.x = noise.get_noise_1d(shake_time) * shake_intensity
		shake_offset.y = noise.get_noise_1d(shake_time + 100) * shake_intensity
		shake_intensity = max(shake_intensity - (shake_decay * delta), 0)

	offset = base_offset + shake_offset

func apply_shake(intensity: float, time: float) -> void:
	shake_intensity = intensity
	active_shake_time = max(active_shake_time, time)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			manual_zoom = true
			last_zoom_input_time = Time.get_ticks_msec() / 1000.0
			zoom /= zoom_speed # Zoom Out
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			manual_zoom = true
			last_zoom_input_time = Time.get_ticks_msec() / 1000.0
			zoom *= zoom_speed # Zoom In

		zoom.x = clamp(zoom.x, min_zoom, max_zoom)
		zoom.y = clamp(zoom.y, min_zoom, max_zoom)
