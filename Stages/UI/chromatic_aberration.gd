class_name ChromaticAberration
extends CanvasLayer

const MAX_ENTROPY_STRENGTH: float = 0.018

@onready var mat: ShaderMaterial = $ChromaticRect.material

func _ready() -> void:
	$ChromaticRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat.set_shader_parameter("strength", 0.0)
	EntropyManager.entropy_changed.connect(_on_entropy_changed)
	GlobalSignals.death.connect(_on_enemy_died)
	GlobalSignals.game_over.connect(_on_game_over)

func _on_entropy_changed(entropy: float) -> void:
	if entropy >= 0.0:
		mat.set_shader_parameter("strength", 0.0)
		return
	var t: float = clamp(abs(entropy) / 100.0, 0.0, 1.0)
	mat.set_shader_parameter("strength", pow(t, 1.8) * MAX_ENTROPY_STRENGTH)

func _on_enemy_died(body: CelestialBody) -> void:
	var peak: float
	var dur: float
	if body is Ceres:
		peak = 0.025
		dur = 0.9
	else:
		return
	var tween: Tween = create_tween()
	tween.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("strength", v),
		peak, 0.0, dur
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func _on_game_over() -> void:
	var tween: Tween = create_tween()
	tween.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("strength", v),
		0.025, 0.0, 1.5
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
