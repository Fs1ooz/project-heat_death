extends Area2D

static var starting_threshold: float = 500.0

@onready var energy: int = 1
@onready var sfx: AudioStreamPlayer = $EnergyAudioStreamPlayer
@onready var sprite: Sprite2D = $CollisionShape2D/Sprite2D

var colors := [
	Color("ffdd00ff"), Color("ffa500"), Color("ff0000"),
	Color("da0076ff"), Color("b5019cff"), Color("1f5bffff"),
	Color("5dd2ffff"), Color("00e2d5ff"), Color("00b69aff"),
	Color("00a952ff"), Color("00ff00"),
]

var _spawn_time: float = 0.0
var player: Player = null
var is_attracted := false  # ← FLAG per evitare check inutili

func _ready() -> void:
	_spawn_time = Time.get_unix_time_from_system()
	energy = weighted_random_energy(100, 3.0)
	update_color()

	# ← Prendi player UNA VOLTA SOLA
	player = get_tree().get_first_node_in_group("player")

	# ← DISATTIVA physics_process di default
	set_physics_process(false)

	# ← Usa timer invece di _physics_process per animazione
	var anim_timer = Timer.new()
	anim_timer.wait_time = 0.05  # 20 FPS per animazione
	anim_timer.timeout.connect(_animate_sprite)
	add_child(anim_timer)
	anim_timer.start()

@export var energy_per_cycle := 100.0

func update_color() -> void:
	if energy <= 0:
		return

	var cycle_pos := (energy / energy_per_cycle) * colors.size()
	var i := int(cycle_pos) % colors.size()
	var next_i := (i + 1) % colors.size()
	var f := cycle_pos - int(cycle_pos)
	var scale_factor := 1.0 + (energy / energy_per_cycle)

	sprite.modulate = colors[i].lerp(colors[next_i], f) * Color(1, 1, 1, 0.7)
	sprite.scale *= scale_factor

func weighted_random_energy(max_energy: int, weight_power: float) -> int:
	var r := randf()
	var weighted := pow(r, weight_power)
	return int(1 + weighted * (max_energy - 1))

# ← Animazione con timer invece di _physics_process
func _animate_sprite() -> void:
	sprite.frame = (sprite.frame + 1) % (sprite.hframes * sprite.vframes)

# ← ATTIVA physics_process SOLO quando vicino al player
func _physics_process(delta: float) -> void:
	if not player:
		return

	var distance := global_position.distance_to(player.global_position)
	var active_threshold: float = max(starting_threshold, player.energy_threshold)

	# Se troppo lontano, disattiva physics_process
	if distance >= active_threshold * 1.2:
		set_physics_process(false)
		is_attracted = false
		return

	var speed: float = active_threshold / 1.5 * (1.0 - distance / active_threshold) * delta
	global_position = global_position.move_toward(player.global_position, speed)

# ← Usa Area2D per detection invece di controllo manuale
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		# Attiva attrazione
		if not is_attracted:
			is_attracted = true
			set_physics_process(true)

		# Pickup
		sfx.reparent(body)
		sfx.play()
		sfx.connect("finished", queue_free)

		var amount = 1.0 + (0.1 / (body.mass + 1))
		body.change_size(amount)

		UpgradeManager.gain_energy(energy)
		queue_free()
