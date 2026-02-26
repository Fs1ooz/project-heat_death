extends Polygon2D

@export var margin: float = 50.0
@export var arrow_scale: float = 1.5
@export var update_interval: float = 0.01

var _camera: Camera2D = null
var _viewport: Viewport = null
var _timer_accumulator: float = 0.0
@export var _label: Label

func _ready() -> void:
	polygon = PackedVector2Array([
		Vector2(8, 0),
		Vector2(-8, -5),
		Vector2(-8, 5)
	])
	scale = Vector2(arrow_scale, arrow_scale)


	_viewport = get_viewport()
	await get_tree().process_frame
	_camera = _viewport.get_camera_2d()

func _process(delta: float) -> void:
	_timer_accumulator += delta
	if _timer_accumulator < update_interval:
		return
	_timer_accumulator = 0.0
	_update_arrow()

func _update_arrow() -> void:
	if not _camera or not is_instance_valid(_camera):
		_camera = _viewport.get_camera_2d()
		if not _camera:
			visible = false
			return

	var cam_pos: Vector2 = _camera.get_screen_center_position()
	var target: Node = _get_nearest_body(cam_pos)
	if not target:
		visible = false
		return

	var screen_rect: Rect2 = _viewport.get_visible_rect()
	var canvas_transform: Transform2D = _camera.get_canvas_transform()
	var target_screen: Vector2 = canvas_transform * target.global_position

	var expanded_rect: Rect2 = screen_rect.grow(-margin)
	if expanded_rect.has_point(target_screen):
		visible = false
		return

	visible = true

	var center: Vector2 = screen_rect.size * 0.5
	var dir: Vector2 = (target_screen - center).normalized()
	var half: Vector2 = (screen_rect.size * 0.5) - Vector2(margin, margin)

	var k: float = min(
		half.x / abs(dir.x) if dir.x != 0.0 else INF,
		half.y / abs(dir.y) if dir.y != 0.0 else INF
	)

	global_position = center + dir * k
	rotation = dir.angle()

	# --- Aggiorna la distanza nel label ---
	# PRIMA (con singleton)

	# DOPO (con classe statica)
	var dist_pixels: float = cam_pos.distance_to(target.global_position)
	var dist_km: float = UnitConverter.pixels_to_km(dist_pixels)
	var dist_au: float = UnitConverter.pixels_to_au(dist_pixels)

	_label.text = _format_distance(dist_km, dist_au)

	# Controrota il label per tenerlo sempre leggibile
	_label.rotation = -rotation
	# Annulla anche la scala della freccia sul label
	_label.scale = Vector2(1.0 / arrow_scale, 1.0 / arrow_scale)

func _format_distance(km: float, au: float) -> String:
	if au >= 0.00001:
		return "%.4f AU" % au
	else:
		return "%.0f km" % km

func _get_nearest_body(cam_pos: Vector2) -> Node:
	var nearest: Node = null
	var best_dist_sq: float = INF
	for body: CelestialBody in CelestialBody.celestial_bodies:
		var dist_sq: float = cam_pos.distance_squared_to(body.global_position)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			nearest = body
	return nearest
