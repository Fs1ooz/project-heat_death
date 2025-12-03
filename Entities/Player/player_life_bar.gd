extends ProgressBar

#var _fade_tween: Tween
#
#
#func _ready() -> void:
	#start_fade()
#
#func start_fade():
	#if _fade_tween:
		#_fade_tween.kill()  # interrompe fade precedente
#
	#if modulate.a == 0.0:
		#modulate.a = 1.0
#
	## Solo se hp è pieno (o se vuoi che sparisca dopo 3 sec senza danno)
	#await get_tree().create_timer(2).timeout
#
	#_fade_tween = create_tween()
	#_fade_tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUINT)
