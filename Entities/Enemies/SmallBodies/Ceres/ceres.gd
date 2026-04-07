class_name Ceres
extends SmallBody

@onready var outgassing_component: OutgassingComponent = %OutgassingComponent

enum State { WAIT, WINDUP, SPAWN_ENEMIES, GAS}

const ATTACKS: Array = [State.SPAWN_ENEMIES, State.GAS]

@export var wait_duration: float = 1.5
@export var windup_duration: float = 1.0
@export var max_gas: int = 10

@export var attack_duration: float = 10.0

@export var spawn_count: int = 6
@export var spawn_radius: float = 150_000.0

const ASTEROID_SCENE: PackedScene = preload("res://Entities/Enemies/SmallBodies/Asteroid.tscn")

var current_state: State = State.WAIT
var state_timer: float = 0.0
var next_attack: State


func _ready() -> void:
	super()
	_change_state(State.WAIT)
	set_process(false)
	outgassing_component.setup(self, sprite)
	outgassing_component.prespawn.call_deferred(max_gas)


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
			var tween: Tween = create_tween()
			tween.tween_property($SubViewport, "rotation_speed", 0.3, 0.5).set_trans(Tween.TRANS_SPRING)
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
			state_timer = attack_duration       # <-- countdown parte qui
			outgassing_component.activate_all()
			$SubViewport.rotation_speed = 0.01
			mat.set_shader_parameter("flash_value", 0.0)
		State.SPAWN_ENEMIES:
			state_timer = attack_duration       # <-- idem
			_spawn_enemies()


func _windup() -> void:
	# Tween principale: rampa sulla rotation speed + snap finale
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property($SubViewport, "rotation_speed", 100.0, windup_duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property($SubViewport, "rotation_speed", 0.3, 0.25) \
		.set_delay(windup_duration)
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
	var parent: Node = get_tree().current_scene
	var angle_step: float = TAU / spawn_count

	for i: int in spawn_count:
		var angle: float = angle_step * i + randf_range(-angle_step * 0.5, angle_step * 0.5)
		var offset: Vector2 = sprite.scale + (Vector2(cos(angle), sin(angle)) * randf_range(spawn_radius * 0.6, spawn_radius * 1.4))

		var asteroid: Node2D = ASTEROID_SCENE.instantiate()
		parent.add_child(asteroid)
		asteroid.global_position = global_position + offset
