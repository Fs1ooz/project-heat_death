class_name AsteroidChunk
extends SmallBody
## Pezzo reale di asteroide, generato da AsteroidSlicer tagliando il poligono del
## genitore. Nemico completo: HP, danno da contatto, drop energia, orbitabile.
## Niente RotationComponent nella scena: SmallBody._ready() salta così tutta la
## macchineria elenco_texture/AnimatedSprite2D ma mantiene la state machine di orbita.

static var active_count: int = 0

const SPAWN_GRACE_MSEC: int = 250          # niente danno da contatto appena spawnato
const DESPAWN_DISTANCE: float = 120_000.0  # i chunk non sono tracciati dallo spawner

var source_polygon: PackedVector2Array     # centroid-local, già in scala mondo
var source_uvs: PackedVector2Array         # coordinate pixel nell'atlas PNG
var local_to_atlas: Transform2D            # punto locale → pixel atlas (per la ricorsione)
var atlas_texture: Texture2D
var _equivalent_radius: float = 1.0
var _has_died: bool = false
var _grace_until: int = 0


func _enter_tree() -> void:
	active_count += 1
	super()


func _exit_tree() -> void:
	active_count -= 1
	super()


## Chiamato da AsteroidSlicer PRIMA di add_child: memorizza solo i dati del pezzo
func setup(poly: PackedVector2Array, uvs: PackedVector2Array,
		l2a: Transform2D, atlas: Texture2D, energy: int) -> void:
	source_polygon = poly
	source_uvs = uvs
	local_to_atlas = l2a
	atlas_texture = atlas
	game_energy = energy


func _ready() -> void:
	# Ordine critico: i dati vanno applicati PRIMA che super() esegua _setup_mass/_setup_health
	collision.polygon = source_polygon
	var poly_sprite: Polygon2D = sprite as Polygon2D
	poly_sprite.polygon = source_polygon
	poly_sprite.uv = source_uvs
	poly_sprite.texture = atlas_texture
	_equivalent_radius = sqrt(AsteroidSlicer.polygon_area(source_polygon) / PI)
	# Shape gravità fresca: mai mutare la risorsa condivisa della scena
	var gravity_shape: CircleShape2D = CircleShape2D.new()
	gravity_shape.radius = _equivalent_radius * AsteroidSlicer.GRAVITY_RADIUS_FACTOR
	gravity_area_collision.shape = gravity_shape
	# Poligono centroid-local: COM all'origine per uno spin senza wobble
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector2.ZERO
	_grace_until = Time.get_ticks_msec() + SPAWN_GRACE_MSEC
	super()


## Override: la dimensione è già codificata nel poligono, nessuna scala casuale
func _setup_random_scale() -> void:
	pass


## Scala visiva equivalente per VFX/drop (il Polygon2D resta a scale 1):
## il poligono di un frame 128x128 ha raggio equivalente ~50 a scala 1
func _get_visual_scale() -> float:
	return _equivalent_radius / 50.0


func _on_body_entered(body: Node) -> void:
	# Grace allo spawn: i pezzi nascono a contatto esatto tra loro
	if Time.get_ticks_msec() < _grace_until:
		return
	super(body)


func die() -> void:
	if _has_died:
		return
	_has_died = true
	# Split ricorsivo: il chunk ha già poligono + texture + trasform UV pronti
	if AsteroidSlicer.should_split(collision.polygon) \
			and AsteroidSlicer.spawn_chunks(self, collision.polygon, local_to_atlas, atlas_texture, game_energy):
		drop_energy_on_death = false
		collision.set_deferred("disabled", true)
		sprite.visible = false  # il padre resta vivo 0.05s nell'await di super.die()
	super.die()


func _on_despawn_timer_timeout() -> void:
	# Mai despawnare un corpo catturato/in orbita al player
	if orbit_state != OrbitState.FREE:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player and global_position.distance_to(player.global_position) > DESPAWN_DISTANCE:
		queue_free()
