extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EntropyManager.entropy_changed.connect(_entropy_change)



func _entropy_change(value):
	text = str(value)
