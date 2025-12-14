extends Node2D

@export var asteroid_scene: PackedScene
@export var meteoroid_scene: PackedScene

@onready var player: Player = $Player
@onready var sun: Light2D = $Sun


# Definizione delle regioni in AU con contatori separati
# REALISMO: Ho abbassato drasticamente gli asteroidi (grandi) e alzato i meteoroidi (piccoli)
#const REGIONS := [
	## Hungaria / Transizione
	#{ "name": "InnerTransition", "min_au": 1.87, "max_au": 2.21, "asteroid_count": 5, "meteoroid_count": 150 },
#
	## Fascia Interna (Densa)
	#{ "name": "InnerBelt",       "min_au": 2.21, "max_au": 2.54, "asteroid_count": 25, "meteoroid_count": 450 },
	#{ "name": "FloraFamily",     "min_au": 2.07, "max_au": 2.27, "asteroid_count": 15, "meteoroid_count": 300 },
#
	## Kirkwood Gap 3:1 (Quasi vuoto)
	#{ "name": "KirkwoodGap_3to1", "min_au": 2.44, "max_au": 2.57, "asteroid_count": 2, "meteoroid_count": 15 },
#
	## Fascia Centrale (Il cuore della fascia)
	#{ "name": "MiddleBelt",      "min_au": 2.51, "max_au": 2.81, "asteroid_count": 40, "meteoroid_count": 650 },
	#{ "name": "EunomiaFamily",   "min_au": 2.57, "max_au": 2.74, "asteroid_count": 15, "meteoroid_count": 250 },
#
	## Kirkwood Gap 5:2
	#{ "name": "Gap_5to2",        "min_au": 2.79, "max_au": 2.84, "asteroid_count": 1, "meteoroid_count": 20 },
#
	## Fascia Esterna
	#{ "name": "KoronisFamily",   "min_au": 2.81, "max_au": 2.97, "asteroid_count": 12, "meteoroid_count": 220 },
	#{ "name": "OuterBelt_Inner", "min_au": 2.91, "max_au": 3.11, "asteroid_count": 30, "meteoroid_count": 550 },
	#{ "name": "ThemisFamily",    "min_au": 3.01, "max_au": 3.18, "asteroid_count": 20, "meteoroid_count": 380 },
	#{ "name": "HygieaFamily",    "min_au": 3.14, "max_au": 3.31, "asteroid_count": 18, "meteoroid_count": 320 },
#
	## Bordo esterno
	#{ "name": "Gap_2to1",        "min_au": 3.28, "max_au": 3.29, "asteroid_count": 0, "meteoroid_count": 10 },
	#{ "name": "CybeleGroup",     "min_au": 3.31, "max_au": 3.51, "asteroid_count": 25, "meteoroid_count": 420 },
	#{ "name": "HildaGroup",      "min_au": 3.51, "max_au": 4.21, "asteroid_count": 15, "meteoroid_count": 300 },
#]

const REGIONS := [
	# Hungaria / Transizione
	{ "name": "InnerTransition", "min_au": 1.87, "max_au": 2.21, "asteroid_count": 5, "meteoroid_count": 150 },

	# Fascia Interna (Densa)
	{ "name": "InnerBelt",       "min_au": 2.21, "max_au": 2.54, "asteroid_count": 25, "meteoroid_count": 450 },
	{ "name": "FloraFamily",     "min_au": 2.07, "max_au": 2.27, "asteroid_count": 15, "meteoroid_count": 300 },

	# Kirkwood Gap 3:1 (Quasi vuoto)
	{ "name": "KirkwoodGap_3to1", "min_au": 2.44, "max_au": 2.57, "asteroid_count": 2, "meteoroid_count": 15 },

	# Fascia Centrale (Il cuore della fascia)
	{ "name": "MiddleBelt",      "min_au": 2.51, "max_au": 2.81, "asteroid_count": 40, "meteoroid_count": 650 },
	{ "name": "EunomiaFamily",   "min_au": 2.57, "max_au": 2.74, "asteroid_count": 15, "meteoroid_count": 250 },

	# Kirkwood Gap 5:2
	{ "name": "Gap_5to2",        "min_au": 2.79, "max_au": 2.84, "asteroid_count": 1, "meteoroid_count": 20 },

	# Fascia Esterna
	{ "name": "KoronisFamily",   "min_au": 2.81, "max_au": 2.97, "asteroid_count": 12, "meteoroid_count": 220 },
	{ "name": "OuterBelt_Inner", "min_au": 2.91, "max_au": 3.11, "asteroid_count": 30, "meteoroid_count": 550 },
	{ "name": "ThemisFamily",    "min_au": 3.01, "max_au": 3.18, "asteroid_count": 20, "meteoroid_count": 380 },
	{ "name": "HygieaFamily",    "min_au": 3.14, "max_au": 3.31, "asteroid_count": 18, "meteoroid_count": 320 },

	# Bordo esterno
	{ "name": "Gap_2to1",        "min_au": 3.28, "max_au": 3.29, "asteroid_count": 0, "meteoroid_count": 100 },
	{ "name": "CybeleGroup",     "min_au": 3.31, "max_au": 3.51, "asteroid_count": 25, "meteoroid_count": 420 },
	{ "name": "HildaGroup",      "min_au": 3.51, "max_au": 4.21, "asteroid_count": 15, "meteoroid_count": 300 },
]

var current_region: String = ""

func _ready() -> void:
	pass
	generate_belt()
	spawn_player_near_smallest_ring()

func _process(_delta: float) -> void:
	update_player_region()

func update_player_region() -> void:
	if not player:
		return
	var player_distance_pixels := player.global_position.length()
	var player_distance_au := UnitConversion.pixels_to_au(player_distance_pixels)

	var new_region := ""
	for region_data in REGIONS:
		if player_distance_au >= region_data["min_au"] and player_distance_au <= region_data["max_au"]:
			new_region = region_data["name"]
			break

	if new_region != current_region and new_region != "":
		current_region = new_region
		var distance_km := UnitConversion.pixels_to_km(player_distance_pixels)
		# Nota: %.2f AU è più leggibile
		print("📍 Regione: %s | Distanza: %d Mio km (%.2f AU)" % [current_region, distance_km / 1_000_000, player_distance_au])

func spawn_player_near_smallest_ring() -> void:
	# Cerca tra tutti i corpi celesti
	var celestial_bodies = get_tree().get_nodes_in_group("celestialbodies")
	if celestial_bodies.is_empty():
		printerr("Nessun corpo celeste trovato!")
		return

	var smallest_body = null
	var min_mass = INF

	for body in celestial_bodies:
		# Assicuriamoci che lo script abbia la proprietà mass
		if "mass" in body and body.mass < min_mass:
			min_mass = body.mass
			smallest_body = body

	if smallest_body == null:
		# Fallback se nessun corpo ha massa definita, prendiamo il primo a caso
		smallest_body = celestial_bodies[0]

	var offset_distance = 150.0 # Un po' più distante per sicurezza
	var random_angle = randf() * TAU
	var spawn_offset = Vector2(cos(random_angle), sin(random_angle)) * offset_distance

	player.global_position = smallest_body.global_position + spawn_offset
	print("Spawn vicino a: ", smallest_body.name, " (massa: ", min_mass, ")")

func generate_belt() -> void:
	for region_data in REGIONS:
		var region_node := $Regions.get_node_or_null(region_data["name"])

		# Se il nodo non esiste, lo creiamo al volo (più comodo per non impazzire nell'editor)
		if not region_node:
			region_node = Node2D.new()
			region_node.name = region_data["name"]
			$Regions.add_child(region_node)

		var min_pixels := UnitConversion.au_to_pixels(region_data["min_au"])
		var max_pixels := UnitConversion.au_to_pixels(region_data["max_au"])

		# 1. Spawn ASTEROIDI (Grandi, pochi)
		# Puoi passare anche un range di scala specifico se vuoi (es. 1.0 - 3.0)
		spawn_ring(region_node, region_data["asteroid_count"], min_pixels, max_pixels, asteroid_scene)

		# 2. Spawn METEOROIDI (Piccoli, tanti)
		# Scala più piccola (es. 0.2 - 0.6)
		spawn_ring(region_node, region_data["meteoroid_count"] * 2, min_pixels, max_pixels, meteoroid_scene)

func spawn_ring(container: Node2D, count: int, min_r: float, max_r: float, scene: PackedScene) -> void:
	if count <= 0:
		return

	for i in count:
		var obj := scene.instantiate() as Node2D
		# ---------------------------------------------
		# 1) ECCENTRICITÀ REALISTICA: 0.0–0.1
		# ---------------------------------------------
		var eccentricity := randf_range(0.0, 0.1)
		# ---------------------------------------------
		# 2) DENSITÀ REALISTICA: più oggetti verso max_r
		# ---------------------------------------------
		var t := pow(randf(), 0.55)  # 0.55 → addensa verso l’esterno
		var base_r := lerp(min_r, max_r, t) as float
		# ---------------------------------------------
		# 3) SPAWN SOLO SUL BORDO (interno o esterno)
		# ---------------------------------------------
		var spawn_on_inner_edge := randf() < 0.5
		var r: float
		if spawn_on_inner_edge:
			r = base_r * (1.0 - eccentricity)  # ← Bordo interno ellittico
			r = clamp(r, min_r * 0.98, min_r * 1.02)  # Vicino al bordo interno
		else:
			r = base_r * (1.0 + eccentricity)  # ← Bordo esterno ellittico
			r = clamp(r, max_r * 0.98, max_r * 1.02)  # Vicino al bordo esterno

		# Angolo orbitale casuale
		var angle := randf() * TAU

		# ---------------------------------------------
		# 4) SPESSORE VERTICALE (±3% della distanza)
		# ---------------------------------------------
		var vertical_noise := randf_range(-0.03, 0.03) * r

		# ---------------------------------------------
		# 5) POSIZIONE FINALE
		# ---------------------------------------------
		var pos := Vector2(
			cos(angle) * r,
			sin(angle) * r + vertical_noise
		)

		obj.position = pos
		# Cerca il corpo centrale attorno al quale orbitare
		var central_body = sun

		# Imposta velocità tangenziale per orbita circolare
		var clockwise_orbit = randf() < 0.5

		container.add_child(obj)


		set_orbit(obj, central_body, clockwise_orbit)


func set_orbit(obj, central_body, clockwise_orbit):
	obj.set_circular_orbit(central_body, clockwise_orbit)

	obj.rotation = randf() * TAU
