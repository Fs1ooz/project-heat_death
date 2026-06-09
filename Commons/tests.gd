extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpgradeManager.gain_energy(10000)
