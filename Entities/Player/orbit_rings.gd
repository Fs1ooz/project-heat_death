class_name OrbitRings
extends Node2D

const ORBIT_RATIO: float = 0.45
const RING_COLOR: Color = Color(1.0, 1.0, 1.0, 0.35)
const RING_WIDTH_RATIO: float = 0.004  # frazione del raggio → la linea cresce col player
const RING_WIDTH_MIN: float = 1.5      # minimo in px-mondo per non sparire da piccolo

var _active: bool = false
var _base_radius: float = 0.0
var _max_slots: int = 1
var _tween: Tween


func show_rings(base_radius: float, max_slots: int) -> void:
	_base_radius = base_radius
	_max_slots = max_slots
	_active = true
	queue_redraw()
	if _tween:
		_tween.kill()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.15)


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
	for i: int in range(_max_slots):
		var radius: float = _base_radius * ORBIT_RATIO * (1.0 + i * 0.3)
		# Spessore proporzionale al raggio: cresce col player ma resta sottile in proporzione
		var draw_width: float = maxf(radius * RING_WIDTH_RATIO, RING_WIDTH_MIN)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 80, RING_COLOR, draw_width, true)
