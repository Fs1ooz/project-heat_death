class_name SmallBody
extends CelestialBody

@export var min_size: float = 1.0
@export var max_size: float = 3.0

@onready var rotation_component: RotationComponent = get_node_or_null("%RotationComponent")

@export var elenco_texture: Array[TextureWithPolygon]
var polygon_data: FramePolygonData


enum OrbitState { FREE, ATTRACTED, ORBITING }
var orbit_state: int = OrbitState.FREE
var orbit_target: Node2D = null
var orbit_angle: float = 0.0
var orbit_radius: float= 200.0
var orbit_speed: float = 1.5


func _ready() -> void:
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	_setup_random_scale()
	GlobalSignals.use_3d.connect(toggle_3d)

	super()
	if not rotation_component:
		return

	rotation_component.setup(sprite)

	if elenco_texture.size() > 0:
		var chosen: TextureWithPolygon = elenco_texture.pick_random()
		sprite.sprite_frames = chosen.sprite_frames
		if chosen.polygon_data:
			polygon_data = chosen.polygon_data
			_setup_mass()
			_setup_health()
	else:

		push_warning("Ehi, ti sei dimenticato di caricare le texture nell'Inspector!")

	sprite.play("rotation")
	var rotation_speed: float = randf_range(0.75, 1.0)
	rotation_component.base_speed = rotation_speed
	rotation_component.speed = rotation_speed


func toggle_3d(toggled: bool) -> void:
	if not has_node("SubViewport"):
		return

	if toggled:
		sprite.texture = load("res://Entities/Enemies/SmallBodies/Ceres/Ceres.png")
		sprite.scale *= 3
	else:
		sprite.scale = Vector2.ONE
		sprite.texture = $SubViewport.get_texture()


func _setup_random_scale() -> void:
	var scale_rand: float = randf_range(min_size, max_size)
	_setup_scale(scale_rand)


func _physics_process(delta: float) -> void:
	print(mass)
	match orbit_state:
		OrbitState.ATTRACTED:
			_attract_to_player(delta)
		OrbitState.ORBITING:
			_orbit(delta)
	super(delta)


var orbit_ratio: float = 0.45


func start_attraction(target: Node2D) -> void:

	if self is Ceres:
		return

	if orbit_state != OrbitState.FREE:
		return

	orbit_state = OrbitState.ATTRACTED
	orbit_target = target
	# Non calcoliamo più la distanza iniziale qui, lo facciamo dinamicamente!


func _attract_to_player(_delta: float) -> void:
	if not is_instance_valid(orbit_target):
		leave_orbit()
		return

	orbit_radius = orbit_target.attraction_radius * orbit_ratio

	if global_position.distance_to(orbit_target.global_position) <= orbit_radius + 20.0:
		_enter_orbit()


func _orbit(delta: float) -> void:
	if not is_instance_valid(orbit_target):
		leave_orbit()
		return

	orbit_radius = orbit_target.attraction_radius * orbit_ratio

	orbit_angle += orbit_speed * delta
	global_position = orbit_target.global_position \
		+ Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius


func _enter_orbit() -> void:
	orbit_state = OrbitState.ORBITING

	freeze = true
	var offset: Vector2 = global_position - orbit_target.global_position
	orbit_angle = atan2(offset.y, offset.x)


func leave_orbit() -> void:
	print("uscito")
	orbit_state = OrbitState.FREE
	freeze = false
	orbit_target = null
	var tangent: Vector2 = Vector2(-sin(orbit_angle), cos(orbit_angle))
	linear_velocity = tangent * 250.0
