extends Node
## L'UpgradeManager, gestisce tutti i potenziamenti, modulare e carino
## Per aggiungere un nuovo Upgrade bisogna prima definirlo in upgrade type e poi inserirlo nel dizionario con i determinati valori

#signal upgrade_applied(upgrade_type: UpgradeType, value: float)

const e: float = 2.71828182845904523536028747135266249775724709369995

var energy: int = 0

signal energy_changed(new_energy: int)

func gain_energy(amount: int) -> void:
	energy += amount
	print("Energia attuale: ", energy)
	emit_signal("energy_changed", energy)


func lose_energy(amount: int) -> void:
	energy -= amount
	print("Energia attuale: ", energy)
	emit_signal("energy_changed", energy)

#func reset_upgrades() -> void:
	#for key in upgrades_data.keys():
		#var upgrade = upgrades_data[key]
		#upgrade["level"] = 0
		#if "base_power" in upgrade:
			#upgrade["current_power"] = upgrade["base_power"]
#

enum UpgradeType {
	SPEED,
	MASS,
	DENSITY,
}

var upgrades_data: Dictionary = {
	UpgradeType.SPEED: {
		"name": "Speed",
		"description": "Increases speed.",
		"level": 0,
		"base_power": 700.0,
		"current_power": 700.0,
		"base_cost": 10,
		"current_cost": 10,
	},
	UpgradeType.MASS: {
		"name": "Mass",
		"description": "Increases mass.",
		"level": 0,
		"base_power": 1.0,
		"current_power": 1.0,
		"base_cost": 50,
		"current_cost": 50,
	},
	UpgradeType.DENSITY: {
		"name": "Density",
		"description": "Increases density.",
		"level": 0,
		"base_power": 1.0,
		"current_power": 1.0,
		"base_cost": 100,
		"current_cost": 100,
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


	if energy < upgrade_data["current_cost"]:
		print("Non abbastanza energia!")
		return

	lose_energy(upgrade_data["current_cost"])

	upgrade_data["level"] += 1
	var power: float
	match upgrade_type:
		UpgradeType.SPEED:
			power = upgrade_data["current_power"] + upgrade_data["level"] * 100
		UpgradeType.DENSITY:
			power = upgrade_data["current_power"] + upgrade_data["level"] * 100
		UpgradeType.MASS:
			power = upgrade_data["current_power"] + upgrade_data["level"] * 1.1


	upgrade_data["current_power"] = power
	upgrade_data["current_cost"]  = calculate_next_cost(upgrade_data)


	for player in get_tree().get_nodes_in_group("player"):
		match upgrade_type:
			UpgradeType.SPEED:
				player.speed = power
			UpgradeType.MASS:
				player.change_size(1.05)
				player.mass = power

	#upgrade_applied.emit(upgrade_type, power)

func calculate_next_cost(upgrade_data: Dictionary) -> int:
	var base_cost = upgrade_data.get("base_cost", 10)
	var level = upgrade_data["level"]
	var growth_factor = 1.5
	return int(base_cost * pow(growth_factor, level))
