class_name OrbitRings
extends Node2D

const ORBIT_RATIO: float = 0.45
const RING_COLOR: Color = Color(1.0, 1.0, 1.0, 0.1)
const RING_WIDTH_RATIO: float = 0.009  # frazione del raggio → la linea cresce col player
const RING_WIDTH_MIN: float = 1.7      # minimo in px-mondo per non sparire da piccolo

var _active: bool = false
var _base_radius: float = 0.0
var _max_slots: int = 1
var _tween: Tween
var _charge: float = 0.0  # 0→1: intensità della carica (hold-to-latch); >1 durante il flash

#@onready var _player: Player = get_parent() as Player


func show_rings(base_radius: float, max_slots: int) -> void:
	_base_radius = base_radius
	_max_slots = max_slots
	_active = true
	_charge = 0.0  # riparte scarico ad ogni nuova arma
	queue_redraw()
	if _tween:
		_tween.kill()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.15)


func set_charge(v: float) -> void:
	_charge = v
	queue_redraw()


## Aggancio avvenuto: picco d'intensità dell'anello e poi sparizione (conferma del latch).
func latch_flash() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(set_charge, 1.0, 1.8, 0.08)
	_tween.tween_method(set_charge, 1.8, 0.0, 0.35)
	_tween.tween_callback(hide_rings)


func hide_rings() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	_tween.tween_callback(_on_hide_finished)


func update_rings(base_radius: float, max_slots: int) -> void:
	_base_radius = base_radius
	_max_slots = max_slots
	queue_redraw()


func _on_hide_finished() -> void:
	_active = false
	queue_redraw()


func _process(_delta: float) -> void:
	if _active:
		queue_redraw()


func _draw() -> void:
	if not _active:
		return
	# Durante la carica gli anelli restano visibili (anche gli slot già occupati) e si intensificano;
	# l'alpha sale con _charge, così l'anello "si carica" fino al latch.
	var alpha: float = clampf(lerpf(RING_COLOR.a, 0.9, _charge), 0.0, 1.0)
	var col: Color = Color(RING_COLOR.r, RING_COLOR.g, RING_COLOR.b, alpha)
	for i: int in range(_max_slots):
		var radius: float = _base_radius * ORBIT_RATIO * (1.0 + i * 0.3)
		# Spessore proporzionale al raggio: cresce col player ma resta sottile in proporzione
		var draw_width: float = maxf(radius * RING_WIDTH_RATIO, RING_WIDTH_MIN)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 80, col, draw_width, true)
