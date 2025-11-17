extends Line2D

@export_category('Trail')
@export var length : = 10

@onready var parent : Node2D = get_parent()
var offset : = Vector2.ZERO

func _ready() -> void:

	top_level = true
	offset = position
	top_level = true

	if width_curve:
		width_curve = width_curve.duplicate()

	call_deferred("_resize_trail")


func _physics_process(_delta: float) -> void:
	global_position = Vector2.ZERO

	var point : = parent.global_position + offset
	add_point(point, 0)

	if get_point_count() > length:
		remove_point(get_point_count() - 1)

func _resize_trail():
	if parent is not Player:
		var col = parent.collision
		if width_curve.get_point_count() > 0:
			var p := width_curve.get_point_position(0)
			p.y = col.scale.x
			width_curve.set_point_value(0, p.y * 5)
