class_name SmallBody
extends CelestialBody

@export var min_size: float = 1.5
@export var max_size: float = 2.5
#@export var spin_range: float = 2.0
#

#@export var visible_on_screen_notifier: VisibleOnScreenEnabler2D
#
func _ready() -> void:
	_setup_random_scale()
	super()




func _on_visible_screen_enabler_component_screen_entered() -> void:
	set_sleeping(false)
	#print("ENTRATO: ", sleeping)



func _on_visible_screen_enabler_component_screen_exited() -> void:
	set_sleeping(true)
	#print("USCITO: ", sleeping)


func _setup_random_scale() -> void:
	var scale_rand: float = randf_range(min_size, max_size)
	_setup_scale(scale_rand)
