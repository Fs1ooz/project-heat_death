class_name Meteoroid
extends SmallBody


@onready var kick_component: KickComponent = %KickComponent

func _ready() -> void:
	super()
	kick_component.kick_rotation()
