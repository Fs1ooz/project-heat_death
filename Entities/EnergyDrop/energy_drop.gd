class_name Energy
extends Area2D

@export var starting_threshold: float = 750.0
@export var scale_mult: float = 7.5


var energy: int = 1:
	set(value):
		energy = value
		if is_node_ready():
			update_color()

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var sfx: AudioStreamPlayer = $EnergyAudioStreamPlayer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $CollisionShape2D/Sprite2D

# Presumo tu abbia un nodo area per il range, ad esempio:
# @onready var range_area: Area2D = $RangeArea

var colors: Array = [
	Color("ffdd00ff"), Color("ffa500"), Color("ff0000"),
	Color("da0076ff"), Color("b5019cff"), Color("1f5bffff"),
	Color("5dd2ffff"), Color("00e2d5ff"), Color("00b69aff"),
	Color("00a952ff"), Color("00ff00"),
]

@export var energy_per_cycle: float = 100.0

func _ready() -> void:
	update_color()
	# Spawnata di colpo a una posizione: azzera l'interpolazione per non farla "volare".
	reset_physics_interpolation()

func update_color() -> void:
	if energy <= 0:
		return
	var cycle_pos: float = (energy / energy_per_cycle) * colors.size()
	var i: int = int(cycle_pos) % colors.size()
	var next_i: int = (i + 1) % colors.size()
	var f: float = cycle_pos - int(cycle_pos)

	var scale_factor: float = 1.0 + (energy / energy_per_cycle) * scale_mult
	sprite.modulate = colors[i].lerp(colors[next_i], f) * Color(1, 1, 1, 0.7)

	# FIX: Usa l'assegnazione diretta, non la moltiplicazione!
	sprite.scale = Vector2(scale_factor, scale_factor)



func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		sfx.reparent(body)
		sfx.play()
		# FIX: Collega il segnale per eliminare l'SFX stesso, non il nodo EXP (che stiamo già distruggendo)
		sfx.finished.connect(sfx.queue_free)
		UpgradeManager.gain_energy(energy)
		queue_free()
