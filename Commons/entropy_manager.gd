extends Node

signal entropy_changed
var value: float = 0.0

func change_entropy(amount: float):
	value += amount
	value = round(value * 100) / 100.0  # arrotonda a 2 decimali
	entropy_changed.emit(value)


func _on_timer_timeout() -> void:
	value += 0.1
	value = round(value * 100) / 100.0
	entropy_changed.emit(value)
