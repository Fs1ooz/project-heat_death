extends Node

signal upgrade_applied(upgrade_type: UpgradeType, value: float)

const e: float = 2.71828182845904523536028747135266249775724709369995



func _ready() -> void:
	#GlobalSignals.connect("reset_upgrades", reset_upgrades)
	pass

func reset_upgrades() -> void:
	for key in upgrades_data.keys():
		var upgrade = upgrades_data[key]
		upgrade["level"] = 0
		if "base_power" in upgrade:
			upgrade["current_power"] = upgrade["base_power"]

enum UpgradeType {
	DAMAGE_UPGRADE,
	SPEED_UPGRADE,
	MASS_UPGRADE,
	DENSITY_UPGRADE,
}

var upgrades_data: Dictionary = {
	UpgradeType.DAMAGE_UPGRADE: {
		"name": "Damage",
		"description": "Increases the ball's power.",
		"icon": "",
		"level": 0,
		"base_power": 1,
		"current_power": 1,
	},
	UpgradeType.SPEED_UPGRADE: {
		"name": "Speed",
		"description": "Increases the ball's speed.",
		"icon": "",
		"level": 0,
		"base_power": 900,
		"current_power": 900,
	},
		UpgradeType.MASS_UPGRADE: {
		"name": "Mass",
		"description": "Increases mass.",
		"icon": "",
		"level": 0,
		"base_power": 900,
		"current_power": 900,

	},
		UpgradeType.DENSITY_UPGRADE: {
		"name": "Density",
		"description": "Increases density.",
		"icon": "",
		"level": 0,
		"base_power": 900,
		"current_power": 900,

	}
}

func get_upgrade_data(upgrade_type: UpgradeType) -> Dictionary:
	return upgrades_data[upgrade_type]

func get_all_upgrades() -> Dictionary:
	return upgrades_data

func get_ball_stats() -> Dictionary:
	var stats := {}
	for upgrade_type in upgrades_data.keys():
		stats[upgrade_type] = upgrades_data[upgrade_type]["current_power"]
	return stats


func apply_upgrade(upgrade_type: UpgradeType):
	var upgrade_data = upgrades_data[upgrade_type]
	upgrade_data["level"] += 1

	var power: float
	match upgrade_type:
		UpgradeType.DAMAGE_UPGRADE:
			power = upgrade_data["level"] + pow(upgrade_data["level"], 1.5)
		UpgradeType.SPEED_UPGRADE:
			power = upgrade_data["current_power"] + upgrade_data["level"] * 100
		UpgradeType.DENSITY_UPGRADE:
			power = upgrade_data["current_power"] + upgrade_data["level"] * 100
		UpgradeType.MASS_UPGRADE:
			power = upgrade_data["current_power"] + upgrade_data["level"] * 100
			print("Potenziato")


	upgrade_data["current_power"] = power
	#upgrade_data["current_cost"]  = calculate_next_cost(upgrade_data)
	upgrade_applied.emit(upgrade_type, power)

	for player in get_tree().get_nodes_in_group("player"):
		match upgrade_type:
			UpgradeType.DAMAGE_UPGRADE:
				player.damage = power
			UpgradeType.SPEED_UPGRADE:
				player.speed = power


func get_stat(upgrade_type: UpgradeType):
	var value = upgrades_data[upgrade_type]["current_power"]
	return value

func reset_timer(_upgrade_data: Dictionary):
	pass
	#print("Timer reset. Level: ", upgrade_data["level"])
	#GlobalSignals.emit_signal("reset_max_timer", 30)

func activate_special(upgrade_data: Dictionary):
	print("Special ability activated. Level: ", upgrade_data["level"])
