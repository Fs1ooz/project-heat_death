extends Node2D

@export var asteroid_scene: PackedScene
@export var meteoroid_scene: PackedScene
@export var safety_margin_multiplier: float = 10_000.0  # Moltiplicatore per lo spazio di sicurezza



@onready var player: Player = $Player
@onready var sun: Light2D = $Sun




const REGIONS := [
	# Hungaria / Transizione
	{ "name": "InnerTransition", "min_au": 1.87, "max_au": 2.21, "asteroid_count": 5, "meteoroid_count": 150 },

	# Fascia Interna (Densa)
	{ "name": "InnerBelt",       "min_au": 2.21, "max_au": 2.54, "asteroid_count": 25, "meteoroid_count": 450 },
	{ "name": "FloraFamily",     "min_au": 2.07, "max_au": 2.27, "asteroid_count": 15, "meteoroid_count": 300 },

	# Kirkwood Gap 3:1 (Quasi vuoto)
	{ "name": "KirkwoodGap_3to1", "min_au": 2.44, "max_au": 2.57, "asteroid_count": 2, "meteoroid_count": 35 },

	# Fascia Centrale (Il cuore della fascia)
	{ "name": "MiddleBelt",      "min_au": 2.51, "max_au": 2.81, "asteroid_count": 40, "meteoroid_count": 650 },
	{ "name": "EunomiaFamily",   "min_au": 2.57, "max_au": 2.74, "asteroid_count": 15, "meteoroid_count": 250 },

	# Kirkwood Gap 5:2
	{ "name": "Gap_5to2",        "min_au": 2.79, "max_au": 2.84, "asteroid_count": 1, "meteoroid_count": 50 },

	# Fascia Esterna
	{ "name": "KoronisFamily",   "min_au": 2.81, "max_au": 2.97, "asteroid_count": 12, "meteoroid_count": 220 },
	{ "name": "OuterBelt_Inner", "min_au": 2.91, "max_au": 3.11, "asteroid_count": 30, "meteoroid_count": 550 },
	{ "name": "ThemisFamily",    "min_au": 3.01, "max_au": 3.18, "asteroid_count": 20, "meteoroid_count": 380 },
	{ "name": "HygieaFamily",    "min_au": 3.14, "max_au": 3.31, "asteroid_count": 18, "meteoroid_count": 320 },


	{ "name": "Gap_2to1",        "min_au": 3.28, "max_au": 3.29, "asteroid_count": 0, "meteoroid_count": 20 },
	# Bordo esterno
	{ "name": "CybeleGroup",     "min_au": 3.31, "max_au": 3.51, "asteroid_count": 25, "meteoroid_count": 420 },
	{ "name": "HildaGroup",      "min_au": 3.51, "max_au": 4.21, "asteroid_count": 15, "meteoroid_count": 300 },
]

var current_region: String = ""
# Ora salviamo posizione E raggio di sicurezza di ogni oggetto
var occupied_spaces: Array[Dictionary] = []
var spawn_cluster_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	generate_belt()
	spawn_player_in_cluster()

@export var disable_all_shaders: bool = true

func _process(_delta: float) -> void:

	if disable_all_shaders:
		RenderingServer.set_default_clear_color(Color.BLACK)
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
		print("📍 Regione: %s | Distanza: %d Mio km (%.2f AU)" % [current_region, distance_km / 1_000_000, player_distance_au])

func spawn_player_in_cluster() -> void:
	if spawn_cluster_position == Vector2.ZERO:
		push_warning("Cluster non generato, spawn di default")
		player.global_position = Vector2(UnitConversion.au_to_pixels(2.5), 0)
	else:
		# Spawn al centro del cluster con un piccolo offset
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(50, 150)
		player.global_position = spawn_cluster_position + offset
		print("🎯 Player spawnato nel cluster a %.0f, %.0f" % [spawn_cluster_position.x, spawn_cluster_position.y])

func generate_belt() -> void:
	# Scegli una regione casuale per il cluster (preferibilmente nella fascia centrale)
	var cluster_regions := ["MiddleBelt", "InnerBelt", "EunomiaFamily"]
	var chosen_region: String = cluster_regions[randi() % cluster_regions.size()]

	for region_data in REGIONS:
		var region_node := $Regions.get_node_or_null(region_data["name"])

		if not region_node:
			region_node = Node2D.new()
			region_node.name = region_data["name"]
			$Regions.add_child(region_node)

		var min_pixels := UnitConversion.au_to_pixels(region_data["min_au"])
		var max_pixels := UnitConversion.au_to_pixels(region_data["max_au"])

		# Reset spazi occupati per ogni regione
		occupied_spaces.clear()

		# Se questa è la regione scelta, crea il cluster PRIMA di tutto il resto
		if region_data["name"] == chosen_region:
			create_spawn_cluster(region_node, min_pixels, max_pixels)

		# Spawn asteroidi (grandi)
		spawn_ring(region_node, region_data["asteroid_count"], min_pixels, max_pixels, asteroid_scene)

		# Spawn meteoroidi (piccoli)
		spawn_ring(region_node, region_data["meteoroid_count"] * 2, min_pixels, max_pixels, meteoroid_scene)

func get_object_radius(obj: RigidBody2D) -> float:
	# Usa la massa per calcolare il raggio
	# Formula: raggio ∝ ∛massa (volume è proporzionale a massa per densità costante)
	if "mass" in obj:
		# Scala il raggio in base alla massa: massa più grande = raggio più grande
		var base_radius: float = obj.mass
		return base_radius

	# Fallback se non ha massa
	return 50.0

func create_spawn_cluster(container: Node2D, min_r: float, max_r: float) -> void:
	# Crea un cluster di 8-12 meteoroidi vicini
	var cluster_size := randi_range(8, 12)
	var cluster_radius := 15_000.0  # Raggio del cluster

	# Posizione centrale del cluster (nella fascia scelta)
	var mid_r := (min_r + max_r) / 2.0
	var angle := randf() * TAU
	spawn_cluster_position = Vector2(cos(angle) * mid_r, sin(angle) * mid_r)

	print("🎯 Creazione cluster spawn a %.0f AU (%.0f, %.0f)" % [
		UnitConversion.pixels_to_au(spawn_cluster_position.length()),
		spawn_cluster_position.x,
		spawn_cluster_position.y
	])

	# Spawna i meteoroidi attorno al punto centrale
	for i in range(cluster_size):
		var local_angle := (TAU / cluster_size) * i + randf_range(-0.3, 0.3)
		var local_distance := randf_range(cluster_radius * 0.3, cluster_radius)
		var local_offset := Vector2(cos(local_angle), sin(local_angle)) * local_distance

		var meteoroid_pos := spawn_cluster_position + local_offset

		var obj := meteoroid_scene.instantiate() as Node2D
		obj.position = meteoroid_pos
		container.add_child(obj)

		# Registra gli spazi occupati dal cluster
		var obj_radius := get_object_radius(obj)
		var safety_radius := obj_radius * safety_margin_multiplier
		occupied_spaces.append({
			"position": meteoroid_pos,
			"radius": safety_radius
		})

# --- cascata state ---
var ring_last_angle   : float   = 0.0   # angolo del punto precedente
var ring_mean_separation : float = 0.0  # distanza arco ideale tra due sassi
var ring_left_to_spawn   : int   = 0    # quanti ne mancano per chiudere l’anello

func spawn_ring(container: Node2D, count: int, min_r: float, max_r: float, scene: PackedScene) -> void:
	if count <= 0:
		return

	# --- prepara la “cascata” ---
	ring_last_angle        = randf() * TAU          # partenza casuale
	ring_mean_separation   = TAU / float(count)     # passo angolare medio
	ring_left_to_spawn     = count

	var base_radius: float
	var eccentricity: float = 0.01

	for i in count:
		# --- angolo con piccolo jitter (±25 % del passo) ---
		var jitter  = randf_range(-0.25, 0.25) * ring_mean_separation
		var angle   = ring_last_angle + ring_mean_separation + jitter
		ring_last_angle = angle

		# --- raggio con eccentricity (come avevi già) ---
		var t        = pow(randf(), 0.55)
		base_radius  = lerp(min_r, max_r, t)
		var r  = base_radius * (1.0 + eccentricity * -1.0 if randf()<0.5 else 1.0)
		r = clamp(r, min_r*0.98, max_r*1.02)

		# --- noise verticale ---
		var vertical_noise = randf_range(-0.03, 0.03) * r

		var pos := Vector2(cos(angle)*r, sin(angle)*r + vertical_noise)

		# --- istanzia direttamente (nessun check) ---
		var obj := scene.instantiate() as Node2D
		obj.position = pos
		container.add_child(obj)


func is_position_valid(pos: Vector2, new_object_radius: float) -> bool:
	# Controlla se c'è sovrapposizione con altri oggetti
	for space in occupied_spaces:
		var occupied_pos: Vector2 = space["position"]
		var occupied_radius: float = space["radius"]

		# Distanza minima = somma dei due raggi di sicurezza
		var min_distance := new_object_radius + occupied_radius

		if pos.distance_to(occupied_pos) < min_distance:
			return false

	return true
