extends TextureRect

@export var margin := 24.0
@export var update_interval := 0.1
@export var cache_refresh_interval := 0.3

var _timer := 0.0
var _cache_timer := 0.0
var _cached_bodies := []  # Cache dei corpi celesti

func _ready():
	pivot_offset = size / 2
	_update_cache()  # Setup iniziale

	# Connetti segnali specifici (performance O(1))
	if GlobalSignals.has_signal("death"):
		GlobalSignals.connect("death", _on_celestial_body_death)

	if GlobalSignals.has_signal("celestial_body_spawned"):
		GlobalSignals.connect("celestial_body_spawned", _on_body_added)

func _on_celestial_body_death(body):
	# Rimuove il body specifico - O(n) ma raro
	var idx = _cached_bodies.find(body)
	if idx != -1:
		_cached_bodies.remove_at(idx)

func _on_body_added(body):
	# Aggiunge solo il nuovo body - O(1)
	if body.is_in_group("celestialbodies") and not body in _cached_bodies:
		_cached_bodies.append(body)

func _update_cache():
	# Operazione "costosa" ma eseguita raramente
	_cached_bodies = get_tree().get_nodes_in_group("celestialbodies")

func _process(delta):
	_timer += delta
	if _timer < update_interval:
		return
	_timer = 0.0

	# Fail-safe: aggiornamento periodico (non blocca il gioco)
	_cache_timer += delta
	if _cache_timer >= cache_refresh_interval:
		_cache_timer = 0.0
		_update_cache()  # Refresh completo se qualcosa è andato storto

	var target = _nearest()
	if not target:
		visible = false
		return

	var vp = get_viewport()
	var camera = vp.get_camera_2d()
	if not camera:
		return

	var screen_size = vp.get_visible_rect().size
	var canvas_transform = camera.get_canvas_transform()
	var target_screen = canvas_transform * target.global_position

	# Controlla se il target è visibile
	if Rect2(Vector2.ZERO, screen_size).has_point(target_screen):
		visible = false
		return

	visible = true
	var center = screen_size / 2
	var dir = (target_screen - center).normalized()
	rotation = dir.angle()

	# Posizionamento ottimizzato
	var half = screen_size / 2 - Vector2(margin, margin)
	var k = min(half.x / abs(dir.x), half.y / abs(dir.y))
	position = center + dir * k - size / 2

func _nearest():
	if _cached_bodies.is_empty():
		return null

	var camera = get_viewport().get_camera_2d()
	if not camera:
		return null

	var cam_pos = camera.global_position
	var nearest = null
	var best = INF

	# Loop sulla cache - O(n) ma senza query al tree
	for body in _cached_bodies:
		if not is_instance_valid(body):
			continue
		var d = cam_pos.distance_squared_to(body.global_position)
		if d < best:
			best = d
			nearest = body

	return nearest
