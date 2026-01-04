extends Label

# Colori del gradiente
const COLOR_MIN: Color = Color(0.471, 0.008, 1.0, 1.0)  # Blu per valori negativi (-100)
const COLOR_ZERO: Color = Color(1.0, 1.0, 1.0)  # Bianco per zero
const COLOR_MAX: Color = Color(0.969, 0.459, 0.0, 1.0)  # Rosso per valori positivi (+100)

const ENTROPY_MIN: float = -100.0
const ENTROPY_MAX: float = 100.0

func _ready() -> void:
	EntropyManager.entropy_changed.connect(_entropy_change)

func _entropy_change(value: float) -> void:
	text = str(snapped(value, 0.01))  # Arrotonda a 2 decimali

	# Calcola il colore in base al valore
	var color: Color

	if value < 0.0:
		# Interpola tra blu e bianco per valori negativi
		var t: float = remap(value, ENTROPY_MIN, 0.0, 0.0, 1.0)
		color = COLOR_MIN.lerp(COLOR_ZERO, t)
	else:
		# Interpola tra bianco e rosso per valori positivi
		var t: float = remap(value, 0.0, ENTROPY_MAX, 0.0, 1.0)
		color = COLOR_ZERO.lerp(COLOR_MAX, t)

	# Applica il colore
	add_theme_color_override("font_color", color)
