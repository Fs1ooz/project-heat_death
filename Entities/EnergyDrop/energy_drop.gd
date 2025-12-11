extends Area2D

static var starting_threshold: float = 500.0
static var threshold: float = starting_threshold


@onready var energy: int = 1
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var sfx: AudioStreamPlayer = $EnergyAudioStreamPlayer
@onready var polygon_2d: Polygon2D = $CollisionShape2D/Polygon2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var colors := [
		Color("ffdd00ff"), # giallo
		Color("ffa500"), # arancio
		Color("ff0000"), # rosso
		Color("da0076ff"), # rosa
		Color("b5019cff"), # viola
		Color("1f5bffff"), # blu
		Color("5dd2ffff"), # azzurro
		Color("00e2d5ff"), # turchese
		Color("00b69aff"), # verde acqua
		Color("00a952ff"),  # verde smeraldo
		Color("00ff00"), # verde
]

var playback: AudioStreamPlayback = null # Actual playback stream, assigned in _ready().


func _ready() -> void:
	energy = weighted_random_energy(25, 3.0)

	update_color()

@export var energy_per_cycle := 50.0
# quanta energia serve per attraversare TUTTI i colori

func update_color() -> void:
	if energy <= 0:
		polygon_2d.color = colors[0]
		return

	# Ciclo continuo nella palette
	var cycle_pos := (energy / energy_per_cycle) * colors.size()

	var i := int(cycle_pos) % colors.size()
	var next_i := (i + 1) % colors.size()

	var f := cycle_pos - int(cycle_pos)  # interpolazione fra i due colori

	# Colore interpolato fluidamente
	polygon_2d.color = colors[i].lerp(colors[next_i], f)

	# Scala legata all'energia (coerente col ciclo colore)
	var scale_factor := 1.0 + (energy / energy_per_cycle)
	polygon_2d.scale = Vector2.ONE * scale_factor


func weighted_random_energy(max_energy: int, weight_power: float) -> int:
	# Numero casuale fra 0 e 1
	var r := randf()

	# Applica il peso (r^weight_power schiaccia verso lo 0)
	var weighted := pow(r, weight_power)

	# Scala fino a max_energy
	return int(1 + weighted * (max_energy - 1))



func _physics_process(delta: float) -> void:
	if not player:
		return
	var distance = global_position.distance_to(player.global_position)
	if distance < threshold:
		var speed = threshold / 1.5 * (1.0 - distance / threshold) * delta
		global_position = global_position.move_toward(player.global_position, speed)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		threshold = starting_threshold + (starting_threshold * body.mass) / 15

		# Genera e riproduci il suono proceduralmente
		sfx.reparent(player)
		sfx.play()
		sfx.connect("finished", queue_free)

		body.change_size(1.01)
		UpgradeManager.gain_energy(energy)
		queue_free()
