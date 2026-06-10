class_name AsteroidSlicer
extends Object
## Slicing geometrico degli asteroidi: taglia il poligono del frame corrente in pezzi
## reali (chunk) che insieme compongono esattamente il corpo originale.
## Tutto statico: usato sia da Asteroid.die() che da AsteroidChunk.die() (ricorsione).

const CHUNK_SCENE_PATH: String = "res://Entities/Enemies/SmallBodies/Asteroids/asteroid_chunk.tscn"

const MIN_SPLIT_AREA: float = 6.0e6         # px²; sotto questa area il corpo muore e basta
const MIN_PIECES: int = 2
const MAX_PIECES: int = 4
const SLIVER_AREA_RATIO: float = 0.05       # pezzi < 5% dell'area totale vengono scartati
const SEPARATION_SPEED_FACTOR: float = 0.8 # vel. separazione = fattore * raggio equiv. del padre
const MAX_SEPARATION_SPEED: float = 800.0   # px/s; cap per non rendere i chunk più pericolosi del padre
const SEPARATION_ANGLE_JITTER: float = 0.6  # rad; deviazione casuale dalla direzione radiale
const SPIN_RANDOM_MAX: float = 4.5          # rad/s aggiunti allo spin ereditato
const CUT_JAGGEDNESS: float = 0.5          # ampiezza zigzag del taglio (frazione del raggio)
const CUT_SEGMENT_RATIO: float = 0.7        # lunghezza segmenti zigzag (frazione del raggio)
const EROSION_RATIO: float = 0.2           # materiale "polverizzato" ai bordi (fraz. raggio pezzo)
const GRAVITY_RADIUS_FACTOR: float = 11.0   # rapporto area gravità / raggio corpo (551/50 da asteroid.tscn)
const MAX_ACTIVE_CHUNKS: int = 60           # valvola performance: oltre, niente split

# load() pigro invece di preload: evita il ciclo slicer → scena → script chunk → slicer
static var _chunk_scene: PackedScene = null


static func _get_chunk_scene() -> PackedScene:
	if _chunk_scene == null:
		_chunk_scene = load(CHUNK_SCENE_PATH)
	return _chunk_scene


static func polygon_area(poly: PackedVector2Array) -> float:
	# Formula dell'area col metodo dello "Shoelace"
	var area: float = 0.0
	var n: int = poly.size()
	for i: int in range(n):
		var j: int = (i + 1) % n
		area += poly[i].x * poly[j].y
		area -= poly[j].x * poly[i].y
	return absf(area) / 2.0


static func polygon_centroid(poly: PackedVector2Array) -> Vector2:
	# Centroide pesato sull'area (non la media dei vertici)
	var cross_acc: float = 0.0
	var centroid: Vector2 = Vector2.ZERO
	var n: int = poly.size()
	for i: int in range(n):
		var j: int = (i + 1) % n
		var cross: float = poly[i].x * poly[j].y - poly[j].x * poly[i].y
		cross_acc += cross
		centroid += (poly[i] + poly[j]) * cross
	if absf(cross_acc) < 0.0001:
		# Poligono degenerato: ripiega sulla media semplice
		var avg: Vector2 = Vector2.ZERO
		for v: Vector2 in poly:
			avg += v
		return avg / maxf(1.0, float(n))
	return centroid / (3.0 * cross_acc)


static func should_split(poly: PackedVector2Array) -> bool:
	return polygon_area(poly) >= MIN_SPLIT_AREA \
		and AsteroidChunk.active_count < MAX_ACTIVE_CHUNKS


## Spezza il poligono in pezzi irregolari: tagli frastagliati + erosione dei bordi
## (materiale "polverizzato": i pezzi NON ricompongono perfettamente il padre).
## Coordinate body-local già scalate. Ritorna [] nei casi degeneri.
static func slice_polygon(poly: PackedVector2Array, pieces: int) -> Array[PackedVector2Array]:
	# Geometry2D normalizza i risultati a CCW: input CW va normalizzato, altrimenti
	# il check buchi scarterebbe tutti i pezzi
	if Geometry2D.is_polygon_clockwise(poly):
		poly = poly.duplicate()
		poly.reverse()
	var total_area: float = polygon_area(poly)
	var centroid: Vector2 = polygon_centroid(poly)
	var radius: float = 0.0
	for v: Vector2 in poly:
		radius = maxf(radius, (v - centroid).length())

	# Primo taglio attraverso il centroide (con jitter); i successivi ritagliano
	# il pezzo più grande con angoli casuali, finché non raggiungiamo il target
	var theta: float = randf() * TAU
	var origin: Vector2 = centroid \
		+ Vector2.from_angle(theta).orthogonal() * radius * randf_range(-0.1, 0.1)

	var working: Array[PackedVector2Array] = []
	working.append_array(_jagged_cut(poly, origin, theta, radius))

	var safety: int = 0
	while working.size() < pieces and safety < 6:
		safety += 1
		var largest_i: int = 0
		var largest_area: float = 0.0
		for i: int in range(working.size()):
			var a: float = polygon_area(working[i])
			if a > largest_area:
				largest_area = a
				largest_i = i
		var largest: PackedVector2Array = working[largest_i]
		working.remove_at(largest_i)
		working.append_array(_jagged_cut(largest, polygon_centroid(largest), randf() * TAU, radius))

	# Pulizia: niente degeneri, niente buchi (poligoni clockwise), niente schegge
	var kept: Array[PackedVector2Array] = []
	for piece: PackedVector2Array in working:
		if piece.size() < 3:
			continue
		if Geometry2D.is_polygon_clockwise(piece):
			continue
		if polygon_area(piece) < SLIVER_AREA_RATIO * total_area:
			continue
		kept.append(piece)

	# Erosione: ogni pezzo perde un bordo di materiale → vuoti tra i chunk,
	# come roccia polverizzata dall'esplosione (la VFX di morte copre i buchi)
	var eroded: Array[PackedVector2Array] = []
	for piece: PackedVector2Array in kept:
		var piece_radius: float = sqrt(polygon_area(piece) / PI)
		var results: Array[PackedVector2Array] = Geometry2D.offset_polygon(
			piece, -piece_radius * EROSION_RATIO, Geometry2D.JOIN_SQUARE)
		for r: PackedVector2Array in results:
			if r.size() < 3:
				continue
			if Geometry2D.is_polygon_clockwise(r):
				continue
			if polygon_area(r) < SLIVER_AREA_RATIO * total_area:
				continue
			eroded.append(r)

	if eroded.size() < 2:
		return []
	return eroded


## Taglio con bordo frastagliato (zigzag rumorosa invece di una retta):
## ritorna i pezzi di entrambi i lati, già appiattiti
static func _jagged_cut(poly: PackedVector2Array, origin: Vector2, angle: float,
		radius: float) -> Array[PackedVector2Array]:
	var d: Vector2 = Vector2.from_angle(angle)
	var n: Vector2 = d.orthogonal()
	var extent: float = radius * 4.0
	var seg_len: float = maxf(radius * CUT_SEGMENT_RATIO, 1.0)
	var jag_amp: float = radius * CUT_JAGGEDNESS

	# Polilinea zigzag lungo d, da -extent a +extent, con rumore perpendicolare
	var cutter: PackedVector2Array = PackedVector2Array()
	var t: float = -extent
	while t < extent:
		cutter.append(origin + d * t + n * randf_range(-jag_amp, jag_amp))
		t += seg_len
	cutter.append(origin + d * extent + n * randf_range(-jag_amp, jag_amp))
	# Chiusura del poligono sul lato di n (semipiano dal bordo frastagliato)
	cutter.append(origin + d * extent + n * extent)
	cutter.append(origin - d * extent + n * extent)

	var result: Array[PackedVector2Array] = []
	result.append_array(Geometry2D.intersect_polygons(poly, cutter))
	result.append_array(Geometry2D.clip_polygons(poly, cutter))
	return result


## Spezza `source` in chunk. Ritorna false nei casi degeneri (il chiamante muore normalmente).
## `poly`: poligono del corpo in coordinate locali scalate.
## `local_to_atlas`: trasform punto locale → pixel nell'atlas PNG (solo scala+traslazione).
static func spawn_chunks(source: CelestialBody, poly: PackedVector2Array,
		local_to_atlas: Transform2D, atlas: Texture2D, total_energy: int) -> bool:
	if atlas == null:
		return false
	var pieces: Array[PackedVector2Array] = slice_polygon(poly, randi_range(MIN_PIECES, MAX_PIECES))
	if pieces.is_empty():
		return false

	var parent_radius: float = sqrt(polygon_area(poly) / PI)
	var kept_area: float = 0.0
	for piece: PackedVector2Array in pieces:
		kept_area += polygon_area(piece)

	# RotationComponent ruota lo sprite indipendentemente dal body: per comporre
	# visivamente il padre, i chunk ereditano la rotazione VISIVA dello sprite
	var visual_rot: float = source.sprite.global_rotation

	for piece: PackedVector2Array in pieces:
		var piece_centroid: Vector2 = polygon_centroid(piece)
		var local_poly: PackedVector2Array = PackedVector2Array()
		for v: Vector2 in piece:
			local_poly.append(v - piece_centroid)
		# La ricorsione compone per pura traslazione (la rotazione non entra mai in l2a)
		var child_l2a: Transform2D = local_to_atlas * Transform2D(0.0, piece_centroid)
		var uvs: PackedVector2Array = PackedVector2Array()
		for v: Vector2 in local_poly:
			uvs.append(child_l2a * v)
		# Energia in proporzione all'area, normalizzata sui pezzi tenuti
		var energy_share: int = int(total_energy * polygon_area(piece) / kept_area)

		var chunk: AsteroidChunk = _get_chunk_scene().instantiate()
		chunk.setup(local_poly, uvs, child_l2a, atlas, energy_share)
		# Property semplici PRIMA di add_child: sopravvivono all'inserimento (gli impulsi no)
		chunk.global_rotation = visual_rot
		chunk.global_position = source.global_position + piece_centroid.rotated(visual_rot)
		var outward: Vector2 = chunk.global_position - source.global_position
		if outward.length_squared() > 1.0:
			outward = outward.normalized()
		else:
			outward = Vector2.from_angle(randf() * TAU)
		# Dispersione esplosiva: direzione radiale con jitter angolare, velocità molto variabile
		outward = outward.rotated(randf_range(-SEPARATION_ANGLE_JITTER, SEPARATION_ANGLE_JITTER))
		# La velocità di separazione è cappata: asteroidi grandi producono chunk veloci
		# ma non così veloci da fare più danno del padre intero (rel_vel × mass_ratio)
		var sep_speed: float = minf(SEPARATION_SPEED_FACTOR * parent_radius, MAX_SEPARATION_SPEED)
		chunk.linear_velocity = source.linear_velocity \
			+ outward * sep_speed * randf_range(0.5, 1.5)
		chunk.angular_velocity = source.angular_velocity \
			+ randf_range(-SPIN_RANDOM_MAX, SPIN_RANDOM_MAX)
		source.get_parent().add_child.call_deferred(chunk)

	return true
