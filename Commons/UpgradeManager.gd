extends Node
## L'UpgradeManager, gestisce tutti i potenziamenti, modulare e carino
## Per aggiungere un nuovo Upgrade bisogna prima definirlo in upgrade type e poi inserirlo nel dizionario con i determinati valori

#signal upgrade_applied(upgrade_type: UpgradeType, value: float)

const e: float = 2.71828182845904523536028747135266249775724709369995


@onready var player: Player = get_tree().get_first_node_in_group("player")
var energy: float = 0
var max_energy: float = 100
var level: int = 1

var growth_factor: float = 1.2

signal tier_changed()
signal energy_changed(current: float, max: float, level: int)

var tiers: Array = [3, 5, 10, 20, 30, 40, 50]

func gain_energy(value: float) -> void:
	energy += value
	while energy >= max_energy:
		printerr("LEVELUP!!!!")
		energy -= max_energy
		level += 1
		level_up()
		max_energy *= growth_factor
	energy_changed.emit(energy, max_energy, level)


func level_up() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
	player.change_size(1.25)
	player.max_hp = int(player.max_hp * 1.15)
	player.speed *= 1.25
	player.acceleration *= 1.25
	if level in tiers:
		printerr("tier cangiato")
		tier_changed.emit()


func _ready() -> void:
	GlobalSignals.game_over.connect(reset_upgrades)


func reset_upgrades() -> void:
	level = 1
	max_energy = 100
	energy = 0
	for key: int in upgrades_data.keys():
		var upgrade: Dictionary = upgrades_data[key]
		upgrade["level"] = 0
		if "base_power" in upgrade:
			upgrade["current_power"] = upgrade["base_power"]
		#if "current_cost" in upgrade:
			#upgrade["current_cost"] = upgrade["base_cost"]


enum UpgradeType {
	MAX_HEALTH,
	REGENERATION,
	SPEED,
	ACCELERATION,
	MASS,
	#DENSITY,
}


var upgrades_data: Dictionary = {
	UpgradeType.MAX_HEALTH: {
		"name": "Max Health",
		"description": "Increases health.",
		"level": 1,
		"base_power": 100,
		"current_power": 100,
	},
	UpgradeType.REGENERATION: {
		"name": "Regeneration",
		"description": "Start regenerating health.",
		"level": 1,
		"base_power": 2.0,
		"current_power": 2.0,
	},
	UpgradeType.SPEED: {
		"name": "Speed",
		"description": "Increases speed.",
		"level": 1,
		"base_power": 1000.0,
		"current_power": 1000.0,
	},
	UpgradeType.ACCELERATION: {
		"name": "Accelaration",
		"description": "Increases Acceleration.",
		"level": 1,
		"base_power": 800.0,
		"current_power": 800.0,
	},
	UpgradeType.MASS: {
		"name": "Mass",
		"description": "Increases mass.",
		"level": 1,
		"base_power": 1.0,
		"current_power": 1.0,
	},
#
	#UpgradeType.DENSITY: {
		#"name": "Density",
		#"description": "Increases density.",
		#"level": 0,
		#"base_power": 1.0,
		#"current_power": 1.0,
		#"base_cost": 100,
		#"current_cost": 100,
	#}
}


func get_upgrade_data(upgrade_type: UpgradeType) -> Dictionary:
	return upgrades_data[upgrade_type]

func get_all_upgrades() -> Dictionary:
	return upgrades_data

func get_ball_stats() -> Dictionary:
	var stats: Dictionary = {}
	for upgrade_type: String in upgrades_data.keys():
		stats[upgrade_type] = upgrades_data[upgrade_type]["current_power"]
	return stats


func get_current_power(type: UpgradeType) -> float:
	return upgrades_data[type]["current_power"]


func apply_upgrade(upgrade_type: UpgradeType) -> bool:
	var upgrade_data: Dictionary = upgrades_data[upgrade_type]



	printerr("sto facendo 1")
	#if energy < upgrade_data["current_cost"]:
		#print("Non abbastanza energia!")
		#return false

	#lose_energy(upgrade_data["current_cost"])

	upgrade_data["level"] += 1
	var power: float
	match upgrade_type:
		UpgradeType.MAX_HEALTH:
			power = upgrade_data["base_power"] + (upgrade_data["level"] * 50)
		UpgradeType.REGENERATION:
			power = max(0.2, upgrade_data["base_power"] - (upgrade_data["level"] * 0.15))
		UpgradeType.SPEED:
			power = upgrade_data["current_power"] + upgrade_data["level"] * 200
		UpgradeType.ACCELERATION:
			power = upgrade_data["current_power"] + upgrade_data["level"] * 200
		UpgradeType.MASS:
			power = 1.35


		#UpgradeType.DENSITY:
			#power = upgrade_data["current_power"] + upgrade_data["level"] * 1.1

	upgrade_data["current_power"] = power
	upgrade_data["current_cost"] = calculate_next_cost(upgrade_data)

	printerr("sto facendo 2")
	match upgrade_type:

		UpgradeType.MAX_HEALTH:
			player.life_bar.max_value = power
			player._update_life_bar()
			player.max_hp += int(power)
		UpgradeType.REGENERATION:
			player.regen_timer = power
		UpgradeType.SPEED:
			player.speed += power
		UpgradeType.ACCELERATION:
			player.acceleration += power
		UpgradeType.MASS:
			player.change_size(power)
		#UpgradeType.DENSITY:
			#player.change_size(-1.05)

	printerr("sto facendo 3")
	#upgrade_applied.emit(upgrade_type, power)
	return true

func calculate_next_cost(upgrade_data: Dictionary) -> int:
	var base_cost: int = upgrade_data.get("base_cost", 10)
	var upgrade_level: int = upgrade_data["level"]

	return int(base_cost * pow(growth_factor, upgrade_level))
