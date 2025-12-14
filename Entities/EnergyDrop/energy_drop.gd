extends Area2D

static var starting_threshold: float = 500.0

@onready var energy: int = 1
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var sfx: AudioStreamPlayer = $EnergyAudioStreamPlayer
#@onready var polygon_2d: Polygon2D = $CollisionShape2D/Polygon2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $CollisionShape2D/Sprite2D

var colors := [
	Color("ffdd00ff"), Color("ffa500"), Color("ff0000"),
	Color("da0076ff"), Color("b5019cff"), Color("1f5bffff"),
	Color("5dd2ffff"), Color("00e2d5ff"), Color("00b69aff"),
	Color("00a952ff"), Color("00ff00"),
]

var playback: AudioStreamPlayback = null

func _ready() -> void:
	energy = weighted_random_energy(50, 3.0)
	update_color()


@export var energy_per_cycle := 50.0

func update_color() -> void:
	if energy <= 0:
		#polygon_2d.color = colors[0]
		return

	var cycle_pos := (energy / energy_per_cycle) * colors.size()
	var i := int(cycle_pos) % colors.size()
	var next_i := (i + 1) % colors.size()
	var f := cycle_pos - int(cycle_pos)

	var scale_factor := 1.0 + (energy / energy_per_cycle)

	sprite.modulate = colors[i].lerp(colors[next_i], f) * Color(1,1,1,0.7)
	sprite.scale *= scale_factor

	#polygon_2d.color = colors[i].lerp(colors[next_i], f)
#
	#polygon_2d.scale = Vector2.ONE * scale_factor

func weighted_random_energy(max_energy: int, weight_power: float) -> int:
	var r := randf()
	var weighted := pow(r, weight_power)
	return int(1 + weighted * (max_energy - 1))

var frame_speed := 20.0
var frame_timer := 0.0


func _physics_process(delta: float) -> void:
	frame_timer += delta * frame_speed
	sprite.frame = int(frame_timer) % (sprite.hframes * sprite.vframes)

	if not player:
		return

	var distance := global_position.distance_to(player.global_position)
	var active_threshold: float = max(starting_threshold, player.energy_threshold)

	if distance >= active_threshold:
		return

	var speed: float = active_threshold / 1.5 * (1.0 - distance / active_threshold) * delta
	global_position = global_position.move_toward(player.global_position, speed)



func _on_body_entered(body: Node2D) -> void:
	if body is Player:

		sfx.reparent(body)
		sfx.play()
		sfx.connect("finished", queue_free)

		#var amount = max(1.2 / body.mass,  )
		var amount = 1.0 + (0.05 / (body.mass + 1))
		body.change_size(amount)

		UpgradeManager.gain_energy(energy)
		queue_free()
