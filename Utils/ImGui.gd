extends Node2D



func _process(_delta: float) -> void:
	# Inizia la finestra ImGui
	ImGui.Begin("Pannello Controllo")

	# 2. Controlla se il bottone è premuto
	if ImGui.Button("Fai Level UP"):
		# 3. Emetti il segnale come faresti normalmente
		UpgradeManager.level_up()
	if ImGui.Button("Vai su di tier"):
		UpgradeManager.tier_changed.emit()


	ImGui.End()
