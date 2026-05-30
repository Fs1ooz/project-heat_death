class_name ChromaticAberration
extends ColorRect

const MAX_ENTROPY_STRENGTH: float = 0.018

@onready var mat: ShaderMaterial = material

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	mat.set_shader_parameter("strength", 0.0)
	EntropyManager.entropy_changed.connect(_on_entropy_changed)
	GlobalSignals.death.connect(_on_enemy_died)
	UpgradeManager.tier_changed.connect(_on_tier_changed)

func _on_entropy_changed(entropy: float) -> void:
	if entropy >= 0.0:
		mat.set_shader_parameter("strength", 0.0)
		return
	var t: float = clamp(abs(entropy) / 50.0, 0.0, 1.0)
	mat.set_shader_parameter("strength", t * MAX_ENTROPY_STRENGTH)

func _on_enemy_died(body: CelestialBody) -> void:
	var peak: float
	var dur: float
	if body is Ceres:
		peak = 0.025
		dur = 0.9
	elif body is Asteroid or body is Comet or body is Vesta:
		peak = 0.012
		dur = 0.4
	else:
		return
	var tween: Tween = create_tween()
	tween.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("strength", v),
		peak, 0.0, dur
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func _on_tier_changed() -> void:
	var tween: Tween = create_tween()
	tween.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("strength", v),
		0.01, 0.0, 0.6
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
