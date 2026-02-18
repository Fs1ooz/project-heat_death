extends Control

@onready var exp_bar: ExpBar = $ExpBar
@onready var lvl_label: Label = $LvlLabel

var lvl: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpgradeManager.connect("energy_changed", _on_energy_changed)
	exp_bar.set_bar_value(UpgradeManager.energy)

func _on_energy_changed(energy: float, max_energy: float, level: int) -> void:
	exp_bar.set_max_value(max_energy)
	exp_bar.set_bar_value(energy)
	lvl_label.text = "lvl " + str(level)
