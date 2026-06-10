class_name Asteroid
extends SmallBody

var _collision_scale: float = 1.0  # memorizza la scala corrente

@onready var kick_component: KickComponent = %KickComponent
@onready var outgassing_component: OutgassingComponent = %OutgassingComponent

const ENTROPY_THRESHOLD: float = 5.0
var spawn_points: Array[float] = [10.0, 30.0, 50.0, 80.0, 100.0]
var last_spawn_index: int = 0

var _has_died: bool = false


func _ready() -> void:
	super()
	kick_component.kick_position()
	kick_component.kick_rotation()
	outgassing_component.setup(self, sprite)
	outgassing_component.prespawn(spawn_points.size())

	_on_frame_changed()
	_setup_mass()
	_setup_health()


func _on_frame_changed() -> void:
	# Durante cattura/orbita il corpo è freeze (kinematic) e la posizione è pilotata a mano:
	# riscrivere collision.polygon ad ogni frame interferisce col movimento → niente rotazione.
	if orbit_state != OrbitState.FREE:
		return
	var f: int = sprite.frame
	if polygon_data and f < polygon_data.polygons.size():
		var raw: PackedVector2Array = polygon_data.polygons[f]
		var scaled: PackedVector2Array = PackedVector2Array()
		for v: Vector2 in raw:
			scaled.append(v * _collision_scale)
		collision.polygon = scaled


func _setup_scale(scale_factor: float) -> void:
	_collision_scale = scale_factor
	super._setup_scale(scale_factor)


func _on_entropy_changed(entropy: float) -> void:
	if entropy < ENTROPY_THRESHOLD:
		last_spawn_index = 0
		outgassing_component.stop()
		return

	var current_index: int = 0
	for spawn_point: float in spawn_points:
		if entropy > spawn_point:
			current_index += 1

	if current_index > last_spawn_index:
		for i: int in range(current_index - last_spawn_index):
			outgassing_component.activate()

	last_spawn_index = current_index


func die() -> void:
	if _has_died:
		return
	_has_died = true
	var poly: PackedVector2Array = collision.polygon  # frame corrente, già in scala
	if AsteroidSlicer.should_split(poly) and _spawn_chunks(poly):
		drop_energy_on_death = false
		collision.set_deferred("disabled", true)
		sprite.visible = false  # il padre resta vivo 0.05s nell'await di super.die()
	super.die()


## Spezza l'asteroide in chunk reali tagliando il frame corrente.
## Ritorna false nei casi degeneri: si muore normalmente.
func _spawn_chunks(poly: PackedVector2Array) -> bool:
	var frame_tex: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if frame_tex == null:
		return false
	var atlas: Texture2D = frame_tex
	var inv_s: float = 1.0 / _collision_scale
	var l2a: Transform2D
	if frame_tex is AtlasTexture:
		# Polygon2D non onora le region delle AtlasTexture: si usa l'atlas PNG grezzo
		# e le UV in pixel. Punto locale → pixel atlas: p/scala + centro frame + origine regione
		atlas = (frame_tex as AtlasTexture).atlas
		var region: Rect2 = (frame_tex as AtlasTexture).region
		l2a = Transform2D(Vector2(inv_s, 0.0), Vector2(0.0, inv_s), region.position + region.size * 0.5)
	else:
		l2a = Transform2D(Vector2(inv_s, 0.0), Vector2(0.0, inv_s), frame_tex.get_size() * 0.5)
	return AsteroidSlicer.spawn_chunks(self, poly, l2a, atlas, game_energy)
