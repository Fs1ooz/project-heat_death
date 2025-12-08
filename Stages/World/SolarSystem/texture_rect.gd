extends TextureRect
@export var margin := 24.0
@export var hide_onscreen := true

func _ready():
	pivot_offset = size / 2

func _process(_delta):
	var target = _nearest()
	if not target:
		visible = false
		return

	var vp = get_viewport()
	var camera = vp.get_camera_2d()

	# Converti la posizione del target in coordinate schermo
	var target_screen = target.global_position - camera.global_position + vp.get_visible_rect().size / 2

	var rect = vp.get_visible_rect()
	var center = rect.size / 2

	# Nascondi se il target è visibile sullo schermo
	if hide_onscreen and rect.has_point(target_screen):
		visible = false
		return

	visible = true

	# Calcola la direzione dal centro verso il target
	var dir = (target_screen - center).normalized()
	rotation = dir.angle()

	# Calcola la posizione sul bordo dello schermo
	var half = rect.size / 2 - Vector2(margin, margin)
	var k = min(half.x / max(abs(dir.x), 0.001), half.y / max(abs(dir.y), 0.001))
	position = center + dir * k - size / 2

func _nearest():
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return null

	var cam_pos = camera.global_position
	var nearest = null
	var best = INF

	for body in get_tree().get_nodes_in_group("celestialbodies"):
		var d = cam_pos.distance_squared_to(body.global_position)
		if d < best:
			best = d
			nearest = body

	return nearest
