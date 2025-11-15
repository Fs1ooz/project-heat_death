extends Control

@onready var upgrades_v_box_container: VBoxContainer = %UpgradesVBoxContainer

@onready var cj_label: Label = $ExpHboxContainer/CJLabel
@onready var energy_label: Label = $ExpHboxContainer/EnergyLabel

func _ready() -> void:
	UpgradeManager.connect("energy_changed",_on_energy_changed)
	upgrades_v_box_container.hide()
	_create_upgrade_buttons()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("space"):
		upgrades_v_box_container.visible = !upgrades_v_box_container.visible

func _create_upgrade_buttons() -> void:
	for upgrade_type in UpgradeManager.get_all_upgrades().keys():
		var upgrade_data = UpgradeManager.get_upgrade_data(upgrade_type)
		var upgrade_button = Button.new()
		upgrade_button.text = "%s \n Energy: %d" % [upgrade_data["name"], upgrade_data["current_cost"]]
		upgrade_button.pressed.connect(_on_upgrade_pressed.bind(upgrade_type, upgrade_button, upgrade_data))
		upgrades_v_box_container.add_child(upgrade_button)

func _on_upgrade_pressed(upgrade_type: int, upgrade_button: Button, upgrade_data) -> void:
	UpgradeManager.apply_upgrade(upgrade_type)
	upgrade_button.text = "%s \n Energy: %d" % [upgrade_data["name"], UpgradeManager.get_upgrade_data(upgrade_type)["current_cost"]]

func _on_energy_changed(new_energy: int) -> void:
	if not energy_label.visible:
		energy_label.show()
	cj_label.text = str(new_energy)
