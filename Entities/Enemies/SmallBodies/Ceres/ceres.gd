class_name Ceres
extends SmallBody

@onready var outgassing_component: OutgassingComponent = %OutgassingComponent


enum State { WAIT, WINDUP, SPAWN_ENEMIES, GAS}

const ATTACKS: Array = [State.SPAWN_ENEMIES, State.GAS]

@export var wait_duration: float = 2.5
@export var windup_duration: float = 1.0
@export var max_gas: int = 8

@export var attack_duration: float = 10.0

@export var spawn_count: int = 3
@export var spawn_radius: float = 15_000.0


const ASTEROID_SCENE: PackedScene = preload("res://Entities/Enemies/SmallBodies/Asteroids/asteroid.tscn")

var current_state: State = State.WAIT
var state_timer: float = 0.0
var next_attack: State
var _spawned_enemies: Array[Node2D] = []


func _ready() -> void:
	super()
	if not outgassing_component:
		push_error("OutgassingComponent non trovato!")
		return
	sprite.play("rotation")
	outgassing_component.setup(self, sprite)
	_change_state(State.WAIT)


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
		State.SPAWN_ENEMIES:
			if state_timer <= 0:
				_on_attack_finished()


func _change_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.WAIT:
			for e: Node2D in _spawned_enemies:
				if is_instance_valid(e):
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
			var active_tweens: Array = get_tree().get_processed_tweens()
			for t: Tween in active_tweens:
				if t.is_valid():
					t.kill()
			state_timer = attack_duration

			outgassing_component.activate_all()
			rotation_component.freeze(0.2)
			mat.set_shader_parameter("flash_value", 0.0)

		State.SPAWN_ENEMIES:
			state_timer = attack_duration
			_spawn_enemies()


func _windup() -> void:
	rotation_component.windup(windup_duration)
	GlobalSignals.windup_shake.emit(25.0, windup_duration)
	# Tween pulsante: oscilla flash_value in loop durante il caricamento
	var pulse: Tween = create_tween()
	pulse.set_loops()
	pulse.tween_property(mat, "shader_parameter/flash_value", 0.35, 0.18) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(mat, "shader_parameter/flash_value", 0.04, 0.18) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Alla fine del windup: interrompi il pulse e porta flash a 0
	await get_tree().create_timer(windup_duration).timeout
	pulse.kill()
	var snap: Tween = create_tween()
	snap.tween_property(mat, "shader_parameter/flash_value", 0.0, 0.25)


func _on_attack_finished() -> void:
	_change_state(State.WAIT)


func _spawn_enemies() -> void:
	var parent: Node = get_parent()
	var angle_step: float = TAU / spawn_count

	for i: int in spawn_count:
		var angle: float = angle_step * i + randf_range(-angle_step * 0.5, angle_step * 0.5)
		var offset: Vector2 = sprite.scale + (Vector2(cos(angle), sin(angle)) * randf_range(max_size * spawn_radius * 0.6, max_size * spawn_radius * 1.4))

		var asteroid: Node2D = ASTEROID_SCENE.instantiate()
		parent.add_child(asteroid)
		_spawned_enemies.append(asteroid)
		asteroid.global_position = global_position + offset
