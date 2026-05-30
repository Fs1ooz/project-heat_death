class_name ChromaticAberration
extends ColorRect

const MAX_ENTROPY_STRENGTH: float = 0.018
const DAMAGE_FLASH_STRENGTH: float = 0.022
const DAMAGE_FLASH_DURATION: float = 0.25

@onready var mat: ShaderMaterial = material

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	mat.set_shader_parameter("strength", 0.0)
	EntropyManager.entropy_changed.connect(_on_entropy_changed)
	GlobalSignals.player_damaged.connect(_on_player_damaged)

func _on_entropy_changed(entropy: float) -> void:
	if entropy >= 0.0:
		mat.set_shader_parameter("strength", 0.0)
		return
	var t: float = clamp(abs(entropy) / 50.0, 0.0, 1.0)
	mat.set_shader_parameter("strength", t * MAX_ENTROPY_STRENGTH)

func _on_player_damaged() -> void:
	var tween: Tween = create_tween()
	tween.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("strength", v),
		DAMAGE_FLASH_STRENGTH, 0.0, DAMAGE_FLASH_DURATION
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
