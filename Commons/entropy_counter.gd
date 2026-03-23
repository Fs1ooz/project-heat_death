extends Label

const COLOR_MIN: Color = Color(0.471, 0.008, 1.0, 1.0)
const COLOR_ZERO: Color = Color(1.0, 1.0, 1.0)
const COLOR_MAX: Color = Color(0.969, 0.459, 0.0, 1.0)
const ENTROPY_MIN: float = -100.0
const ENTROPY_MAX: float = 100.0

var previous_value: float = 0.0

func _ready() -> void:
	EntropyManager.entropy_changed.connect(_entropy_change)

func _entropy_change(value: float) -> void:
	var diff: float = value - previous_value
	var prefix: String = "+" if diff > 0 else ""

	if abs(diff) > 0.5:
		$Delta.text = prefix + str(snapped(diff, 0.01))
		$Delta.add_theme_color_override("font_color", COLOR_MAX if diff > 0 else COLOR_MIN)
		$Delta.modulate.a = 1.0 # Torna visibile subito
		$Delta.position.y = 40.0
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_interval(1.0) # Resta visibile per 1 secondo
		tween.tween_property($Delta, "position:y", $Delta.position.y + 30, 0.5)
		tween.tween_property($Delta, "modulate:a", 0.0, 0.5)

	text = str(snapped(value, 0.01))

	var color: Color
	if value < 0.0:
		var t: float = remap(value, ENTROPY_MIN, 0.0, 0.0, 1.0)
		color = COLOR_MIN.lerp(COLOR_ZERO, t)
	else:
		var t: float = remap(value, 0.0, ENTROPY_MAX, 0.0, 1.0)
		color = COLOR_ZERO.lerp(COLOR_MAX, t)

	add_theme_color_override("font_color", color)
	previous_value = value
