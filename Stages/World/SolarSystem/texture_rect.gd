extends Polygon2D
#
#@export var margin := 50.0
#@export var update_interval := 0.1 * randf()
#@export var arrow_scale := 2.0 # Per regolare la dimensione della freccia
#
#var _timer := 0.0
#var _cached_bodies := []
#
#func _ready():
	## Definiamo la forma della freccia (triangolo stiloso)
	## Punta a (0,0), base a sinistra.
	#polygon = PackedVector2Array([
		#Vector2(10, 0),   # Punta
		#Vector2(-10, -8),  # Ala superiore
		#Vector2(-6, 0),    # Rientranza centrale (effetto curvo/moderno)
		#Vector2(-10, 8)    # Ala inferiore
	#])
	#scale = Vector2(arrow_scale, arrow_scale)
#
	## Aspettiamo un frame per assicurarci che i gruppi siano pronti
	#await get_tree().process_frame
	#_cached_bodies = get_tree().get_nodes_in_group("celestialbodies")
#
	#if GlobalSignals.has_signal("death"):
		#GlobalSignals.connect("death", _on_celestial_body_death)
	#if GlobalSignals.has_signal("celestial_body_spawned"):
		#GlobalSignals.connect("celestial_body_spawned", _on_body_added)
#
#func _on_celestial_body_death(body):
	#_cached_bodies.erase(body)
#
#func _on_body_added(body):
	#if not body in _cached_bodies:
		#_cached_bodies.append(body)
#
#func _process(delta):
	#_timer += delta
	#if _timer < update_interval:
		#return
	#_timer = 0.0
#
	#var vp = get_viewport()
	#var camera = vp.get_camera_2d()
	#if not camera: return
#
	#var target = _get_nearest_and_clean_cache(camera.get_screen_center_position())
#
	#if not target:
		#visible = false
		#return
#
	#var screen_rect = vp.get_visible_rect()
	#var canvas_transform = camera.get_canvas_transform()
	#var target_screen = canvas_transform * target.global_position
#
	## Se il corpo è visibile a schermo, nascondi la freccia
	#if screen_rect.has_point(target_screen):
		#visible = false
		#return
#
	#visible = true
#
	#var center = screen_rect.size / 2
	#var dir = (target_screen - center).normalized()
#
	## Calcolo del punto di bordo perfetto
	#var half = (screen_rect.size / 2) - Vector2(margin, margin)
	#var k_x = half.x / abs(dir.x) if dir.x != 0 else INF
	#var k_y = half.y / abs(dir.y) if dir.y != 0 else INF
	#var k = min(k_x, k_y)
#
	## Polygon2D usa global_position come centro del suo disegno
	## Non serve sottrarre size/2 perché la punta è relativa allo zero
	#global_position = center + dir * k
	#rotation = dir.angle()
#
#func _get_nearest_and_clean_cache(cam_pos: Vector2):
	#var nearest = null
	#var best_dist = INF
#
	#for i in range(_cached_bodies.size() - 1, -1, -1):
		#var body = _cached_bodies[i]
		#if not is_instance_valid(body):
			#_cached_bodies.remove_at(i)
			#continue
#
		#var d = cam_pos.distance_squared_to(body.global_position)
		#if d < best_dist:
			#best_dist = d
			#nearest = body
#
	#return nearest
