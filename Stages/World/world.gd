extends Node2D

@onready var camera_2d: Camera2D = $Player/Camera2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera_2d.make_current()
