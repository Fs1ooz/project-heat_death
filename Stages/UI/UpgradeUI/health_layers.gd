class_name HealthLayers
extends Control
## UI "a strati" della vita del player: una barra salute (rossa) al centro, circondata da cornici
## arancio annidate (onion), una per ogni strato di "Mantle". Il Player possiede i DATI della vita
## e chiama questi metodi; tutto l'ASPETTO (colori, dimensioni, lampeggii) si regola da qui.
##
## Per personalizzare colori/dimensioni puoi modificare i valori qui sotto OPPURE, dato che sono
## @export, cambiarli direttamente nell'Inspector di Godot selezionando il nodo HealthLayers.

#region Aspetto — modifica qui (o dall'Inspector)
@export var health_fill: Color = Color(0.6154072, 0, 0.0703321, 1)      ## rosso: riempimento barra salute
@export var health_bg: Color = Color(1, 0.8289137, 0.8289137, 0.245)    ## sfondo barra salute
@export var shield_color: Color = Color(0.976, 0.259, 0.06, 1.0)           ## arancio: cornici del mantello
@export var bar_size: Vector2 = Vector2(180, 12)  ## larghezza × altezza della barra salute centrale
@export var frame_step: float = 1.7   ## quanto ogni cornice è più grande della precedente (px per lato)
@export var border_width: int = 2     ## spessore del bordo delle cornici
@export var corner_radius: int = 4    ## arrotondamento degli angoli delle cornici
#endregion

var _health_bar: ProgressBar = null
var _shield_frames: Array[Panel] = []  ## _shield_frames[i] ↔ strato i del player (i alto = più esterna)


## (Ri)crea la barra salute + 'shield_count' cornici annidate. Idempotente (pulisce le precedenti).
## La barra salute è disegnata sopra; le cornici, via via più grandi, le stanno attorno.
func build(shield_count: int) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_shield_frames.clear()
	for i: int in shield_count:
		var frame: Panel = _make_frame(i)
		_set_centered(frame, bar_size + Vector2.ONE * (frame_step * 2.0 * float(i + 1)))
		_shield_frames.append(frame)
	# Aggiunge prima le cornici più esterne (dietro), poi la salute (davanti).
	for i: int in range(shield_count - 1, -1, -1):
		add_child(_shield_frames[i])
	_health_bar = _make_health_bar()
	_set_centered(_health_bar, bar_size)
	add_child(_health_bar)


## Aggiorna i valori: la salute e l'alpha di ogni cornice (0 = rotta/invisibile, 1 = armata).
func refresh(health: float, health_max: float, layers: Array, layer_max: float) -> void:
	if _health_bar:
		_health_bar.max_value = health_max
		_health_bar.value = health
	for i: int in _shield_frames.size():
		if i < layers.size():
			_shield_frames[i].modulate.a = clampf(layers[i] / layer_max, 0.0, 1.0)


## Lampo sulla barra salute (colpo incassato dalla salute).
func flash_health() -> void:
	_flash(_health_bar, Color.WHITE)


## Lampo su una cornice appena armata (Mantle preso): brilla e resta visibile.
func flash_arm(index: int) -> void:
	if index >= 0 and index < _shield_frames.size():
		_flash(_shield_frames[index], Color.WHITE)


## Lampo + dissolvenza di una cornice che si rompe: brilla e poi sparisce.
func flash_break(index: int) -> void:
	if index >= 0 and index < _shield_frames.size():
		_flash(_shield_frames[index], Color(1.0, 1.0, 1.0, 0.0))


func _flash(node: Control, end: Color) -> void:
	if not node:
		return
	node.modulate = Color(3.0, 3.0, 3.0, 1.0)
	var tw: Tween = create_tween()
	tw.tween_property(node, "modulate", end, 0.28)


func _make_health_bar() -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.rounded = true
	bar.allow_lesser = true
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = health_bg
	bg.set_corner_radius_all(3)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = health_fill
	fill.border_color = Color(0, 0, 0, 1)
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


## Cornice (uno strato di mantello): solo bordo, interno quasi trasparente → si annida attorno.
func _make_frame(depth: int = 0) -> Panel:
	var p: Panel = Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var color: Color = shield_color.lightened(depth * 0.3)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(color.r, color.g, color.b, 0.08)
	sb.border_color = color
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(corner_radius)
	p.add_theme_stylebox_override("panel", sb)
	return p

## Centra un Control sul centro del container, con dimensione 'sz'.
func _set_centered(node: Control, sz: Vector2) -> void:
	node.anchor_left = 0.5
	node.anchor_right = 0.5
	node.anchor_top = 0.5
	node.anchor_bottom = 0.5
	node.offset_left = -sz.x * 0.5
	node.offset_right = sz.x * 0.5
	node.offset_top = -sz.y * 0.5
	node.offset_bottom = sz.y * 0.5
