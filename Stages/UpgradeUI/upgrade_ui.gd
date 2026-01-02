extends Control

const VISIBLE_UPGRADES: int = 3

@onready var upgrades_v_box_container: VBoxContainer = %UpgradesVBoxContainer
@onready var upgrades_h_box_container: HBoxContainer = %UpgradesHBoxContainer
@onready var cj_label: Label = $ExpHboxContainer/CJLabel
@onready var energy_label: Label = $ExpHboxContainer/EnergyLabel

var upgrades: Array = UpgradeManager.get_all_upgrades().keys()
var visible_upgrades: Array = []


func _ready() -> void:
	UpgradeManager.connect("energy_changed", _on_energy_changed)
	upgrades_h_box_container.hide()

	# Popola con upgrade casuali unici
	while visible_upgrades.size() < VISIBLE_UPGRADES:
		var random_upgrade = upgrades[randi_range(0, upgrades.size() - 1)]
		if not visible_upgrades.has(random_upgrade):
			visible_upgrades.append(random_upgrade)

	_refresh_buttons()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("space") and EntropyManager.entropy_value >= 0:
		upgrades_h_box_container.visible = !upgrades_h_box_container.visible


func _create_button(upgrade_type: int) -> Button:
	var upgrade_data = UpgradeManager.get_upgrade_data(upgrade_type)
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(200.0, 200.0)
	btn.text = "%s\nEnergy: %d\nlvl: %d" % [upgrade_data["name"], upgrade_data["current_cost"], upgrade_data["level"]]
	btn.set_meta("upgrade_type", upgrade_type)  # ← Salvo il tipo nel button
	btn.pressed.connect(_on_upgrade_pressed.bind(btn))
	return btn


func _refresh_buttons() -> void:
	# Pulisci vecchi pulsanti
	for child in upgrades_h_box_container.get_children():
		child.queue_free()

	# Crea nuovi pulsanti
	for upgrade_type in visible_upgrades:

		var btn = _create_button(upgrade_type)
		upgrades_h_box_container.add_child.call_deferred(btn)



func _on_upgrade_pressed(button: Button) -> void:

	var upgrade_type = button.get_meta("upgrade_type")  # ← Recupero il tipo

	# ⚠️ CONTROLLO: se apply_upgrade fallisce (energia insufficiente) esci
	if not UpgradeManager.apply_upgrade(upgrade_type):
		_shake_button(button)
		return

	# Sostituisci l'upgrade usato con uno nuovo
	var upgrade_idx = visible_upgrades.find(upgrade_type)
	visible_upgrades.erase(upgrade_type)

	var new_upgrade = upgrades[randi_range(0, upgrades.size() - 1)]
	while visible_upgrades.has(new_upgrade):  # ← Evita duplicati
		new_upgrade = upgrades[randi_range(0, upgrades.size() - 1)]

	visible_upgrades.insert(upgrade_idx, new_upgrade)
	_refresh_buttons()


func _on_energy_changed(new_energy: int) -> void:
	if not energy_label.visible:
		energy_label.show()
	cj_label.text = str(new_energy)



func _fade_in_button(btn: Button, duration: float = 0.3) -> void:
	btn.modulate.a = 0.0  # invisibile inizialmente
	btn.visible = true
	btn.create_tween().tween_property(btn, "modulate:a", 1.0, duration)

func _shake_button(btn: Button, duration: float = 0.1) -> void:
	var original_pos = btn.global_position
	var tween = btn.create_tween()

	tween.tween_property(btn, "global_position", original_pos + Vector2(5, 0), duration / 4)
	tween.tween_property(btn, "global_position", original_pos + Vector2(-5, 0), duration / 4)
	tween.tween_property(btn, "global_position", original_pos + Vector2(5, 0), duration / 4)
	tween.tween_property(btn, "global_position", original_pos, duration / 4)
