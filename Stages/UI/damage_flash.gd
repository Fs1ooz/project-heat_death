class_name DamageFlash
extends ColorRect

func _ready() -> void:
	color = Color(1.0, 0.88, 0.2, 0.0)
	mouse_filter = MOUSE_FILTER_IGNORE
	UpgradeManager.tier_changed.connect(_on_tier_changed)

func _on_tier_changed() -> void:
	color = Color(1.0, 0.88, 0.2, 0.45)
	var tween: Tween = create_tween()
	tween.tween_property(self, "color:a", 0.0, 0.7)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
