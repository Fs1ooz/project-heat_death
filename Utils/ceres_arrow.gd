extends Polygon2D

@export var target_name: String = "Ceres"
@export var margin: float = 50.0
@export var arrow_scale: float = 1.5
@export var _label: Label

var _camera: Camera2D = null
var _viewport: Viewport = null
var _target_node: Node2D = null

func _ready() -> void:
	# Setup estetico della freccia
	polygon = PackedVector2Array([
		Vector2(9, 0),
		Vector2(-9, -7),
		Vector2(-9, 7)
	])
	scale = Vector2(arrow_scale, arrow_scale)

	_viewport = get_viewport()

	# Aspettiamo un frame per essere sicuri che tutti i nodi (inclusa Ceres) siano pronti
	await get_tree().process_frame
	_camera = _viewport.get_camera_2d()
	_find_target()

func _find_target() -> void:
	# Cerchiamo Cerere nella lista globale (assumendo che usi la classe CelestialBody)
	for body: CelestialBody in CelestialBody.celestial_bodies:
		if body.name == target_name:
			_target_node = body
			break

func _process(_delta: float) -> void:
	# Se la camera non è assegnata o il target è sparito, riprova a cercarli
	if not _camera or not is_instance_valid(_camera):
		_camera = _viewport.get_camera_2d()
		return

	if not _target_node or not is_instance_valid(_target_node):
		_find_target()
		visible = false
		return

	_update_arrow_position()

func _update_arrow_position() -> void:
	var screen_rect: Rect2 = _viewport.get_visible_rect()
	var canvas_transform: Transform2D = _camera.get_canvas_transform()

	# Trasforma la posizione globale di Cerere in coordinate "schermo"
	var target_screen_pos: Vector2 = canvas_transform * _target_node.global_position

	# Se Cerere è visibile a schermo (dentro il margine), nascondiamo la freccia
	var expanded_rect: Rect2 = screen_rect.grow(-margin)
	if expanded_rect.has_point(target_screen_pos):
		visible = false
		return

	visible = true

	# Calcolo della posizione della freccia sui bordi
	var center: Vector2 = screen_rect.size * 0.5
	var direction: Vector2 = (target_screen_pos - center).normalized()

	# Calcolo l'intersezione con i bordi dello schermo (clamping)
	var half_size: Vector2 = (screen_rect.size * 0.5) - Vector2(margin, margin)

	var edge_factor: float = min(
		half_size.x / abs(direction.x) if direction.x != 0 else INF,
		half_size.y / abs(direction.y) if direction.y != 0 else INF
	)

	global_position = center + direction * edge_factor
	rotation = direction.angle()

	# Aggiornamento Distanza
	if _label:
		var dist_px: float = _camera.get_screen_center_position().distance_to(_target_node.global_position)
		var dist_km: float = UnitConverter.pixels_to_km(dist_px)
		var dist_au: float = UnitConverter.pixels_to_au(dist_px)

		_label.text = "CERES\n" + _format_distance(dist_km, dist_au)
		_label.rotation = -rotation # Mantieni il testo dritto
		_label.scale = Vector2(1.0/arrow_scale, 1.0/arrow_scale)

func _format_distance(km: float, au: float) -> String:
	if au >= 0.01:
		return "%.2f AU" % au
	return "%.0f km" % km
