class_name DamageFlash
extends ColorRect

func _ready() -> void:
	color = Color(1.0, 0.1, 0.05, 0.0)
	mouse_filter = MOUSE_FILTER_IGNORE
	GlobalSignals.player_damaged.connect(_on_player_damaged)

func _on_player_damaged() -> void:
	color.a = 0.38
	var tween: Tween = create_tween()
	tween.tween_property(self, "color:a", 0.0, 0.35)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
