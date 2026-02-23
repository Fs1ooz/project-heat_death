extends ColorRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalSignals.game_over.connect(_reset)
	GlobalSignals.low_health.connect(play)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func play(animation: bool) -> void:
	if animation:
		$AnimationPlayer.play("low_health")
	else:
		$AnimationPlayer.play("RESET")

func _reset() -> void:
	$AnimationPlayer.play("RESET")
