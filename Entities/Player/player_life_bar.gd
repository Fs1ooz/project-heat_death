extends ProgressBar


func _ready() -> void:
	start_fade()

func start_fade():
	if modulate.a == 0.0:
		modulate.a = 1.0
	await get_tree().create_timer(2).timeout
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUINT)
