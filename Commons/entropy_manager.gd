extends Node

signal entropy_changed
var value: float = 0.0

func change_entropy(amount: int):
	value += amount

func _on_timer_timeout() -> void:
	value += 0.1
	entropy_changed.emit(value)
