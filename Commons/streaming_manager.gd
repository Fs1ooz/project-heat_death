extends Node2D
#
#@export var streaming_enabled := true
#@export var max_bodies_before_streaming := 100
#@export var vision_radius_multiplier := 100_000.0
#@export var update_interval := 0.3
#@export var unload_multiplier := 1.2
#@export var scale_growth_factor := 0.5
#
#var update_timer := 0.0
#var cached_player: Node = null
#var cached_bodies: Array = []
#var cache_refresh_timer := 0.0
#const CACHE_REFRESH_INTERVAL := 1.0
#
#func _ready():
	#update_interval = 0.3 + randf() * 0.1  # Randomizza una volta sola
#
	## INIZIALIZZA LA CACHE SUBITO invece di aspettare 1 secondo
	#await get_tree().process_frame  # Aspetta 1 frame che tutto sia pronto
	#_refresh_cache()
#
#
#
#
#func _process(delta):
	#if not streaming_enabled:
		#return
#
	#cache_refresh_timer += delta
	#if cache_refresh_timer >= CACHE_REFRESH_INTERVAL:
		#cache_refresh_timer = 0.0
		#_refresh_cache()
#
	#if cached_bodies.size() <= max_bodies_before_streaming:
		#return
#
	#if not is_instance_valid(cached_player):
		#cached_player = get_tree().get_first_node_in_group("player")
		#if not cached_player:
			#return
#
	#update_timer += delta
	#if update_timer < update_interval:
		#return
	#update_timer = 0.0
#
	#var player_pos = cached_player.global_position
	#var player_size = cached_player.sprite.scale.x
#
	#var size_factor = pow(player_size, scale_growth_factor)
	#var load_radius = size_factor * vision_radius_multiplier
	#var unload_radius = load_radius * unload_multiplier
#
	#var load_radius_sq = load_radius * load_radius
	#var unload_radius_sq = unload_radius * unload_radius
#
	#var relative_size_threshold := 0.1
	#var size_threshold = player_size * relative_size_threshold
#
	#for body in cached_bodies:
		#if not is_instance_valid(body):
			#continue
#
		#var distance_sq = player_pos.distance_squared_to(body.global_position)
		#var body_scale = body.sprite.scale.x
#
		#if body_scale < size_threshold:
			#_deactivate_body(body)
			#continue
#
		#if distance_sq <= load_radius_sq:
			#_activate_body(body)
		#elif distance_sq > unload_radius_sq:
			#_deactivate_body(body)
#
## Funzione separata per il refresh della cache
#func _refresh_cache():
	#cached_bodies = get_tree().get_nodes_in_group("celestialbodies")
	#if not cached_player:
		#cached_player = get_tree().get_first_node_in_group("player")
#
#func _activate_body(body):
	#if body.process_mode == Node.PROCESS_MODE_DISABLED:
		#body.set_sleeping(false)
		#body.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
#
#func _deactivate_body(body):
	#if body.process_mode != Node.PROCESS_MODE_DISABLED:
		#body.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
		#body.set_sleeping(true)
