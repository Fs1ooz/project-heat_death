extends Node2D
@export var streaming_enabled := true
@export var max_bodies_before_streaming := 300
@export var vision_radius_multiplier := 1_000.0
@export var update_interval := 0.3
@export var unload_multiplier := 1.8
var update_timer := 0.0

func _process(delta):
	if not streaming_enabled:
		return
	var all_bodies = get_tree().get_nodes_in_group("celestialbodies")
	if all_bodies.size() <= max_bodies_before_streaming:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	update_timer += delta
	if update_timer < update_interval:
		return
	update_timer = 0.0
	var player_pos = player.global_position
	var player_size = player.sprite.scale.x
	var load_radius = player_size * vision_radius_multiplier
	var unload_radius = load_radius * unload_multiplier

	for body in all_bodies:
		if not is_instance_valid(body):
			continue

		var distance = player_pos.distance_to(body.global_position)

		if distance <= load_radius:
			# Vicino → attiva E riapplica orbita
			body.sleeping = false
			if "has_orbit" in body and body.has_orbit:
				body.reapply_orbit()
		elif distance > unload_radius:
			# Lontano → disattiva
			body.sleeping = true
