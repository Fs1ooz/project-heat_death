class_name Ceres
extends SmallBody

@onready var outgassing_component: OutgassingComponent = %OutgassingComponent

enum State { WAIT, WINDUP, GAS, SPAWN_FIELD, GRAVITY_SURGE, ENTROPY_BLAST }

const ATTACKS: Array = [State.GAS, State.SPAWN_FIELD, State.GRAVITY_SURGE, State.ENTROPY_BLAST]

@export var wait_duration: float = 2.0
@export var windup_duration: float = 1.0
@export var max_gas: int = 8
@export var attack_duration: float = 6.0
@export var field_count: int = 9
@export var movement_damp: float = 6.0
@export var gravity_surge_force: float = 100.0
## Il surge scala con le capacità correnti del player (che crescono ×1.25 a ogni livello):
## altrimenti, dopo qualche level-up, lo strattone fisso viene sovrastato dal motore del player
## e i surge successivi al primo non si sentono più. gravity_surge_force resta come pavimento.
@export var gravity_surge_accel_ratio: float = 0.6   ## pull continuo come frazione dell'acceleration del player
@export var gravity_surge_impulse_ratio: float = 0.8 ## strattone iniziale come frazione della speed del player
@export var entropy_blast_amount: float = -25.0

const ASTEROID_SCENE: PackedScene = preload("res://Entities/Enemies/SmallBodies/Asteroids/asteroid.tscn")

var current_state: State = State.WAIT
var state_timer: float = 0.0
var next_attack: State
var _spawned_enemies: Array[Node2D] = []
var _gravity_surge_active: bool = false
var _own_tweens: Array[Tween] = []


func _ct() -> Tween:
	var t: Tween = create_tween()
	_own_tweens.append(t)
	return t


func _kill_own_tweens() -> void:
	for t: Tween in _own_tweens:
		if t.is_valid():
			t.kill()
	_own_tweens.clear()


func _ready() -> void:
	super()
	if not outgassing_component:
		push_error("OutgassingComponent non trovato!")
		return
	linear_damp = movement_damp
	angular_damp = movement_damp
	sprite.play("rotation")
	outgassing_component.setup(self, sprite)
	_change_state(State.WAIT)
	GlobalSignals.ceres_spawned.emit(self)


func _physics_process(delta: float) -> void:
	super(delta)
	if _gravity_surge_active:
		for body: RigidBody2D in bodies_in_gravity:
			if body is Player and is_instance_valid(body):
				var player: Player = body as Player
				# Falloff con la distanza: forte vicino, debole lontano → sembra gravità vera
				# ed è contrastabile dal player accelerando in direzione opposta.
				var to_ceres: Vector2 = global_position - player.global_position
				var dist: float = max(to_ceres.length(), 50.0)
				var falloff: float = clampf(get_gravity_radius() / dist, 0.3, 3.0)
				# Scala con l'acceleration del player (pavimento: gravity_surge_force) così il
				# pull resta comparabile alla spinta propria e si sente a ogni livello.
				var pull_accel: float = maxf(gravity_surge_force, player.acceleration * gravity_surge_accel_ratio)
				player.apply_central_force(to_ceres.normalized() * player.mass * pull_accel * falloff)


func _process(delta: float) -> void:
	state_timer -= delta
	match current_state:
		State.WAIT:
			if state_timer <= 0:
				_change_state(State.WINDUP)
		State.WINDUP:
			if state_timer <= 0:
				_change_state(next_attack)
		State.GAS:
			if state_timer <= 0:
				_on_attack_finished()
		State.SPAWN_FIELD:
			if state_timer <= 0:
				_on_attack_finished()
		State.GRAVITY_SURGE:
			if state_timer <= 0:
				_on_attack_finished()
		State.ENTROPY_BLAST:
			if state_timer <= 0:
				_on_attack_finished()


func _change_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.WAIT:
			_gravity_surge_active = false
			for e: Node2D in _spawned_enemies:
				if not is_instance_valid(e):
					continue
				if e is CelestialBody:
					var cb: CelestialBody = e as CelestialBody
					var tw: Tween = _ct().set_parallel(true)
					tw.tween_property(cb.mat, "shader_parameter/flash_value", 1.0, 0.35) \
						.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					tw.tween_property(cb.sprite, "scale", Vector2.ZERO, 0.35) \
						.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
					tw.chain().tween_callback(func() -> void:
						if is_instance_valid(e):
							e.queue_free()
					)
				else:
					e.queue_free()
			_spawned_enemies.clear()
			rotation_component.reset(0.5)
			state_timer = wait_duration
			outgassing_component.stop()
			outgassing_component.erase_spawn_points()
			outgassing_component.prespawn(max_gas)

		State.WINDUP:
			next_attack = ATTACKS.pick_random()
			state_timer = windup_duration
			_windup()

		State.GAS:
			printerr("Ceres → GAS")
			_kill_own_tweens()
			state_timer = attack_duration
			outgassing_component.activate_all()
			rotation_component.freeze(0.2)
			mat.set_shader_parameter("flash_value", 0.0)

		State.SPAWN_FIELD:
			printerr("Ceres → SPAWN_FIELD")
			state_timer = attack_duration
			_spawn_field()

		State.GRAVITY_SURGE:
			state_timer = 5.0
			_gravity_surge_active = true
			# Impulso iniziale: strattona verso Ceres i corpi già nella gravity area (contenuto,
			# il grosso del trascinamento è la forza continua in _physics_process).
			for body: RigidBody2D in bodies_in_gravity:
				if body is Player and is_instance_valid(body):
					var player: Player = body as Player
					var dir: Vector2 = (global_position - player.global_position).normalized()
					# Strattone proporzionale alla speed corrente (pavimento: gravity_surge_force):
					# +10000 px/s fisso è enorme a inizio partita ma irrilevante quando speed è a decine di migliaia.
					var kick: float = maxf(gravity_surge_force, player.speed * gravity_surge_impulse_ratio)
					player.apply_central_impulse(dir * player.mass * kick)
			rotation_component.windup(0.4)
			GlobalSignals.windup_shake.emit(60.0, 1.0)
			# Glow lento e profondo — non epilettico
			var tween: Tween = _ct()
			tween.set_loops()
			tween.tween_property(mat, "shader_parameter/flash_value", 0.45, 0.8) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(mat, "shader_parameter/flash_value", 0.05, 0.8) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		State.ENTROPY_BLAST:
			printerr("Ceres → ENTROPY_BLAST")
			state_timer = 7.0
			EntropyManager.change_entropy(entropy_blast_amount)
			GlobalSignals.windup_shake.emit(50.0, 0.8)
			rotation_component.windup(0.5)
			var flash_tween: Tween = _ct()
			flash_tween.tween_property(mat, "shader_parameter/flash_value", 0.9, 0.1)
			flash_tween.tween_property(mat, "shader_parameter/flash_value", 0.0, 0.4)


func _on_attack_finished() -> void:
	_gravity_surge_active = false
	_kill_own_tweens()
	mat.set_shader_parameter("flash_value", 0.0)
	_change_state(State.WAIT)


func _windup() -> void:
	rotation_component.windup(windup_duration)
	GlobalSignals.windup_shake.emit(25.0, windup_duration)
	var pulse: Tween = _ct()
	pulse.set_loops()
	pulse.tween_property(mat, "shader_parameter/flash_value", 0.35, 0.18) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(mat, "shader_parameter/flash_value", 0.04, 0.18) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(windup_duration).timeout
	pulse.kill()
	var snap: Tween = _ct()
	snap.tween_property(mat, "shader_parameter/flash_value", 0.0, 0.25)


func take_damage(damage: float) -> void:
	super.take_damage(damage)
	_update_crack_visual()


func _update_crack_visual() -> void:
	if max_health <= 0.0:
		return
	var progress: float = 1.0 - clampf(health / max_health, 0.0, 1.0)
	mat.set_shader_parameter("crack_progress", progress)


func _spawn_field() -> void:
	var parent: Node = get_parent()
	var grav_radius: float = get_gravity_radius()
	var angle_step: float = TAU / field_count
	for i: int in field_count:
		var angle: float = angle_step * i + randf_range(-angle_step * 0.4, angle_step * 0.4)
		var dist: float = randf_range(grav_radius * 0.1, grav_radius * 0.28)
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		var asteroid: Node2D = ASTEROID_SCENE.instantiate()
		parent.add_child(asteroid)
		_spawned_enemies.append(asteroid)
		asteroid.global_position = global_position + dir * dist
		# Posizione impostata DOPO l'add_child (il reset in _ready è già passato): riazzera qui.
		asteroid.reset_physics_interpolation()
		var orbital_speed: float = randf_range(300.0, 700.0) * (1.0 if randf() > 0.5 else -1.0)
		asteroid.linear_velocity = Vector2(-dir.y, dir.x) * orbital_speed
