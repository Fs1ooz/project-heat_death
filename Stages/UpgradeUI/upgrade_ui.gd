extends Control


func _on_speed_upgrade_pressed() -> void:
	print("UPGRADED")
	UpgradeManager.apply_upgrade(UpgradeManager.UpgradeType.SPEED)

func _on_mass_upgrade_pressed() -> void:
	print("UPGRADED")
	UpgradeManager.apply_upgrade(UpgradeManager.UpgradeType.MASS)
