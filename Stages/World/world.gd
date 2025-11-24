extends Node2D

@onready var camera_2d: Camera2D = $Player/Camera2D

func _ready() -> void:
	camera_2d.make_current()
