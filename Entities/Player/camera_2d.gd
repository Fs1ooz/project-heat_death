class_name PlayerCamera
extends Camera2D

@export var zoom_speed: float = 1.05
@export_group("Zoom Limits (Base Values)")
@export var min_zoom_base: float = 0.05
@export var max_zoom_base: float = 2.5
@export_group("Zoom Settings")
@export var base_zoom: Vector2 = Vector2.ONE * 0.25
@export var zoom_lerp_speed: float = 2.15
@export var manual_zoom_timeout: float = 2.0
@export var zoom_value_multiplier: float = 0.6

@export_group("Boss Cam")
@export var boss_zoom_value: float = 0.12        # Zoom minimo durante boss (massimo zoom out)
@export var cam_lerp_speed: float = 3.0

var manual_zoom: bool = false
var last_zoom_input_time: float = 0.0

var min_zoom: float
var max_zoom: float
var forward_offset: float = 450.0

@onready var player: Player = get_parent()
var player_scale: float = 1.0
var tier_base_zoom: Vector2

# Stato camera
var target: Node2D
var is_boss_cam: bool = false
var ceres: Node2D = null  # Verrà assegnato quando Ceres spawna

# Shake
var shake_intensity: float = 0.0
var active_shake_time: float = 0.0
var shake_decay: float = 3.0
var shake_time: float = 0.0
var shake_time_speed: float = 30.0
@export var noise: FastNoiseLite
var base_offset: Vector2 = Vector2.ZERO
var shake_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	GlobalSignals.windup_shake.connect(apply_shake)
	GlobalSignals.ceres_spawned.connect(_on_ceres_spawned)
	UpgradeManager.tier_changed.connect(_on_tier_changed)
	randomize()
	noise.seed = randi()
	top_level = true
	target = player
	global_position = player.global_position
	make_current()
	_on_tier_changed()
	# Cerca Ceres già presente in scena dopo che tutti i _ready() sono completati
	call_deferred("_find_ceres")


func _find_ceres() -> void:
	for body: Node in get_tree().get_nodes_in_group("celestialbodies"):
		if body is Ceres:
			ceres = body
			return


func _on_ceres_spawned(ceres_node: Node2D) -> void:
	ceres = ceres_node


func _on_tier_changed() -> void:
	player_scale = max(player.sprite.scale.x, 0.01)
	tier_base_zoom = base_zoom / player_scale
	min_zoom = min_zoom_base / player_scale
	max_zoom = max_zoom_base / player_scale
	var tween: Tween = create_tween()
	tween.tween_property(self, "zoom", zoom * 1.3, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "zoom", zoom * 0.5, 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	# --- Controlla la prossimità a Ceres ---
	_update_target()

	# --- Calcola posizione e offset ---
	if not is_boss_cam:
		_process_player_cam(delta)
	else:
		_process_boss_cam(delta)

	# --- Lerp posizione globale verso il target ---
	var desired_pos: Vector2 = target.global_position + base_offset
	global_position = global_position.lerp(desired_pos, cam_lerp_speed * delta)

	# --- Timeout zoom manuale ---
	if manual_zoom and Time.get_ticks_msec() / 1000.0 - last_zoom_input_time > manual_zoom_timeout:
		manual_zoom = false

	# --- Clamp zoom ---
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)

	# --- Shake ---
	if active_shake_time > 0:
		shake_time += delta * shake_time_speed
		active_shake_time -= delta
		shake_offset.x = noise.get_noise_1d(shake_time) * shake_intensity
		shake_offset.y = noise.get_noise_1d(shake_time + 100) * shake_intensity
		shake_intensity = max(shake_intensity - (shake_decay * delta), 0)
	else:
		shake_offset = Vector2.ZERO

	global_position += shake_offset


func _update_target() -> void:
	var ceres_alive: bool = ceres != null and is_instance_valid(ceres)

	if not ceres_alive:
		if is_boss_cam:
			is_boss_cam = false
			target = player
			base_offset = Vector2.ZERO
		return

	if not is_boss_cam and _is_ceres_on_screen(1.0):
		is_boss_cam = true
		manual_zoom = false
		target = ceres
	elif is_boss_cam and not _is_ceres_on_screen(1.4):
		is_boss_cam = false
		target = player
		base_offset = Vector2.ZERO


func _is_ceres_on_screen(margin: float) -> bool:
	var screen: Vector2 = get_viewport_rect().size
	var half_w: float = screen.x * 0.5 / zoom.x * margin
	var half_h: float = screen.y * 0.5 / zoom.y * margin
	var vis: Rect2 = Rect2(
		global_position.x - half_w,
		global_position.y - half_h,
		half_w * 2.0,
		half_h * 2.0
	)
	return vis.has_point(ceres.global_position)


func _process_player_cam(delta: float) -> void:
	var mouse_dir: Vector2 = player._handle_mouse_input()
	var dir: Vector2 = mouse_dir if mouse_dir.length() > 0.2 else player.get_input()
	var forward: Vector2 = Vector2.RIGHT.rotated(player.rotation)

	if dir.length() > 0.1:
		base_offset = base_offset.lerp(forward * forward_offset, 0.02)
	else:
		base_offset = base_offset.lerp(Vector2.ZERO, 0.02)

	if not manual_zoom:
		var current_frame_target: Vector2 = tier_base_zoom
		if dir.length() > 0.1:
			current_frame_target *= zoom_value_multiplier
		zoom = zoom.lerp(current_frame_target, zoom_lerp_speed * delta)


func _process_boss_cam(delta: float) -> void:
	if ceres == null or not is_instance_valid(ceres):
		return
	# Midpoint camera: mostra sia player che Ceres nel frame
	var mid: Vector2 = (player.global_position + ceres.global_position) * 0.5
	base_offset = base_offset.lerp(mid - ceres.global_position, cam_lerp_speed * delta)

	if not manual_zoom:
		var dist: float = player.global_position.distance_to(ceres.global_position)
		var vp: Vector2 = get_viewport_rect().size
		# Zoom per tenere entrambi nel frame con ~35% di padding
		var needed: float = min(vp.x, vp.y) / max(dist * 1.7, 1.0)
		needed = clamp(needed, boss_zoom_value / player_scale, tier_base_zoom.x)
		zoom = zoom.lerp(Vector2.ONE * needed, zoom_lerp_speed * delta)


func apply_shake(intensity: float, time: float) -> void:
	shake_intensity = intensity + 1.75
	active_shake_time = max(active_shake_time, time)


func _unhandled_input(event: InputEvent) -> void:
	if is_boss_cam:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			manual_zoom = true
			last_zoom_input_time = Time.get_ticks_msec() / 1000.0
			zoom /= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			manual_zoom = true
			last_zoom_input_time = Time.get_ticks_msec() / 1000.0
			zoom *= zoom_speed
		zoom.x = clamp(zoom.x, min_zoom, max_zoom)
		zoom.y = clamp(zoom.y, min_zoom, max_zoom)
