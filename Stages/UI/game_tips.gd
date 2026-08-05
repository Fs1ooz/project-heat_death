extends Label

func _ready() -> void:
	GlobalSignals.show_tip.connect(_on_show_tip)
	hide() # nascosto finché non arriva un tip

func _on_show_tip(tip: String) -> void:
	text = tip
	show()
