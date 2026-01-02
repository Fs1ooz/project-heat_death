extends Node

signal entropy_changed
var entropy_value: float = 0.0

func change_entropy(amount: float):
	entropy_value += amount
	entropy_value = round(entropy_value * 100) / 100.0  # arrotonda a 2 decimali
	entropy_changed.emit(entropy_value)


func _on_timer_timeout() -> void:
	var base_increase = 0.1
	# Modula l'incremento in base al valore attuale
	# Qui usiamo una funzione sigmoide-ish per limitare l'incremento
	var factor = 1 + entropy_value  # se value è negativo <1, se positivo >1
	factor = clamp(factor, 0.075, 2)  # limiti per non esagerare
	entropy_value += base_increase * factor
	entropy_value = round(entropy_value * 100) / 100.0
	entropy_changed.emit(entropy_value)
