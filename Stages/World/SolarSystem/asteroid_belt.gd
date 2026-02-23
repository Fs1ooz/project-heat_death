extends Node2D
#
#@export var asteroid_scene: PackedScene
#@export var meteoroid_scene: PackedScene
#
#@export var region_width: float = UnitConversion.au_to_pixels(75)
#
#@onready var player: Player = %Player
#
#const REGIONS: Array = [
	#{ "name": "Hungaria",      "min_au": 1.78, "max_au": 2.00, "asteroid_count": 3,   "meteoroid_count": 50  },
#
	#{ "name": "Inner Main Belt",    "min_au": 2.2, "max_au": 2.5, "asteroid_count": 10,  "meteoroid_count": 400 },
	#{ "name": "Middle Main Belt",  "min_au": 2.6, "max_au": 2.8, "asteroid_count": 25,  "meteoroid_count": 650 },
	#{ "name": "Outer Belt",    "min_au": 2.9, "max_au": 3.3, "asteroid_count": 20,  "meteoroid_count": 750 },
#
	#{ "name": "Cybele",        "min_au": 3.4, "max_au": 3.7, "asteroid_count": 15,  "meteoroid_count": 300 },
	#{ "name": "Hilda",         "min_au": 3.9, "max_au": 4.2, "asteroid_count": 10,  "meteoroid_count": 200 }
#]
#
#var current_region: String = ""
#
#func _ready() -> void:
	#generate_regions()
	#update_player_region()
#
#func _process(_delta: float) -> void:
	#update_player_region()
#
#func update_player_region() -> void:
	#if not player:
		#return
	#var player_distance_pixels: float = player.global_position.length()
	#var player_distance_au: float = UnitConversion.pixels_to_au(player_distance_pixels)
#
	#var new_region: String = ""
	#for region_data: Dictionary in REGIONS:
		#if player_distance_au >= region_data["min_au"] and player_distance_au <= region_data["max_au"]:
			#new_region = region_data["name"]
			#break
#
	#if new_region != current_region and new_region != "":
		#current_region = new_region
		#var distance_km: float = UnitConversion.pixels_to_km(player_distance_pixels)
		#print("📍 Regione: %s | Distanza: %d Mio km (%.2f AU)" % [current_region, distance_km / 1_000_000, player_distance_au])
#
#
#func get_object_radius(obj: Node2D) -> float:
	#if "mass" in obj:
		#return float(obj.mass)
	#return 50.0
#
## ----------------------------
##  SLICE RETTANGOLARE VERTICALE
## ----------------------------
#func spawn_region(container: Node2D, count: int, min_r: float, max_r: float, scene: PackedScene) -> void:
	#if count <= 0:
		#return
#
	#var start_x: float = -region_width * 0.5
	## Calcoliamo lo spazio tra un oggetto e l'altro
	## Usiamo count - 1 per far sì che l'ultimo oggetto sia esattamente alla fine della regione
	#var spacing: float = region_width / max(1, count - 1)
## Calcola un offset casuale che trasla l'intera riga di oggetti
	#var global_offset: float = randf_range(0, spacing / 2)
#
	#for i: int in range(count):
		## La X ora non parte più sempre dallo stesso punto
		#var jitter: float = randf_range(-spacing * 0.4, spacing * 0.4)
		#var x: float = start_x + (i * spacing) + global_offset + jitter
#
		## Casuale solo sulla profondità (Y)
		#var y: float = randf_range(min_r, max_r)
#
		#var obj: Node2D = scene.instantiate()
		#obj.position = Vector2(x, y)
		#container.add_child(obj)
#
#
#var total_bodies: int = 0
#
#func generate_regions() -> void:
	#for region_data: Dictionary in REGIONS:
		#var region_node: Node2D = get_node_or_null(region_data["name"])
		#if region_node == null:
			#region_node = Node2D.new()
			#region_node.name = region_data["name"]
			#add_child(region_node)
#
		#var min_pixels: float = UnitConversion.au_to_pixels(region_data["min_au"])
		#var max_pixels: float = UnitConversion.au_to_pixels(region_data["max_au"])
#
		#total_bodies += region_data["meteoroid_count"] + region_data["asteroid_count"]
		#spawn_region(region_node, region_data["asteroid_count"], min_pixels, max_pixels, asteroid_scene)
		#spawn_region(region_node, region_data["meteoroid_count"] / 10, min_pixels, max_pixels, asteroid_scene)
		#spawn_meteoroid_clusters(region_node, region_data["meteoroid_count"], min_pixels, max_pixels)
#
		##printerr(total_bodies)
#
#@export var cluster_radius: float = 35_000.0
#
## Nuova funzione specifica per i meteoroidi
#func spawn_meteoroid_clusters(container: Node2D, total_count: int, min_r: float, max_r: float) -> void:
	#if total_count <= 0:
		#return
#
	#var meteoroids_per_cluster: int = 5 + randi_range(3, 15)
	## Calcoliamo quanti "centri di ammasso" creare
	#@warning_ignore("integer_division")
	#var num_clusters: int = max(1, total_count / meteoroids_per_cluster)
	#var half_w: float = region_width * 0.5
#
	#for c: int in range(num_clusters):
		## Scegliamo il centro del cluster nella regione
		#var center_x: float = randf_range(-half_w, half_w)
		#var center_y: float = randf_range(min_r, max_r)
		#var cluster_center: Vector2 = Vector2(center_x, center_y)
		#if not player_spawn_at(cluster_center):
			#player_spawn_at(cluster_center)
		## Generiamo i meteoroidi attorno al centro
		#for i: int in range(meteoroids_per_cluster):
			## Distribuzione circolare casuale (Random Disk Sampling)
			#var angle: float = randf() * TAU
			#var distance: float = randf() * cluster_radius
			#var offset: Vector2 = Vector2(cos(angle), sin(angle)) * distance
#
			#var m: Node2D = meteoroid_scene.instantiate()
			#m.position = cluster_center + offset
			#m.rotation = randf() * TAU # Rotazione casuale per varietà visiva
			#container.add_child(m)
#
#
#func player_spawn_at(new_position: Vector2) -> bool:
	#player.global_position = new_position
	#return true
