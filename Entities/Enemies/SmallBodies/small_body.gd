class_name SmallBody
extends CelestialBody

@export var min_size: float = 1.0
@export var max_size: float = 2.7

# Orbita
enum OrbitState { FREE, ATTRACTED, ORBITING }
var orbit_state: int = OrbitState.FREE
var orbit_target: Node2D = null
var orbit_angle: float = 0.0
var orbit_radius: float= 200.0
var orbit_speed: float = 1.5

func _ready() -> void:
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	_setup_random_scale()
	super()

func _setup_random_scale() -> void:
	var scale_rand: float = randf_range(min_size, max_size)
	_setup_scale(scale_rand)

func _physics_process(delta: float) -> void:
	match orbit_state:
		OrbitState.ATTRACTED:
			_attract_to_player(delta)
		OrbitState.ORBITING:
			_orbit(delta)
	super(delta)  # lascia girare tutta la logica di CelestialBody

func start_attraction(target: Node2D) -> void:
	if orbit_state != OrbitState.FREE:
		return
	orbit_state = OrbitState.ATTRACTED
	orbit_target = target
	orbit_radius = get_gravity_radius() * 0.55

func _attract_to_player(_delta: float) -> void:
	if not is_instance_valid(orbit_target):
		leave_orbit()
		return
	if global_position.distance_to(orbit_target.global_position) <= orbit_radius + 5.0:
		_enter_orbit()

func _enter_orbit() -> void:
	orbit_state = OrbitState.ORBITING
	freeze = true
	var offset: Vector2 = global_position - orbit_target.global_position
	orbit_angle = atan2(offset.y, offset.x)

func _orbit(delta: float) -> void:
	if not is_instance_valid(orbit_target):
		leave_orbit()
		return
	orbit_angle += orbit_speed * delta
	global_position = orbit_target.global_position \
		+ Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius

func leave_orbit() -> void:
	orbit_state = OrbitState.FREE
	freeze = false
	orbit_target = null
	var tangent: Vector2 = Vector2(-sin(orbit_angle), cos(orbit_angle))
	linear_velocity = tangent * 250.0
