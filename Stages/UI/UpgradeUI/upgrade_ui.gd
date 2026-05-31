extends Control

const VISIBLE_UPGRADES: int = 3

@onready var upgrades_h_box_container: HBoxContainer = %UpgradesHBoxContainer
@onready var cj_label: Label = $ExpHboxContainer/CJLabel
@onready var energy_label: Label = $ExpHboxContainer/EnergyLabel

var upgrades: Array = UpgradeManager.get_all_upgrades().keys()
var visible_upgrades: Array = []


func _ready() -> void:
	UpgradeManager.connect("tier_changed", _on_tier_changed)
	upgrades_h_box_container.hide()

	# Popola con upgrade casuali unici
	while visible_upgrades.size() < VISIBLE_UPGRADES:
		var random_upgrade: int = upgrades[randi_range(0, upgrades.size() - 1)]
		if not visible_upgrades.has(random_upgrade):
			visible_upgrades.append(random_upgrade)

	_refresh_buttons()


#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("space") and EntropyManager.entropy_value >= 0:
		#upgrades_h_box_container.visible = !upgrades_h_box_container.visible


func _create_button(upgrade_type: int) -> Button:
	var upgrade_data: Dictionary = UpgradeManager.get_upgrade_data(upgrade_type)
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(150.0, 150.0)
	btn.text = "%s\n lvl: %d" % [upgrade_data["name"], upgrade_data["level"]]
	btn.set_meta("upgrade_type", upgrade_type)  # ← Salvo il tipo nel button
	btn.pressed.connect(_on_upgrade_pressed.bind(btn))
	return btn


func _refresh_buttons() -> void:
	# Pulisci vecchi pulsanti
	for child: Button in upgrades_h_box_container.get_children():
		child.queue_free()
	# Crea nuovi pulsanti
	for upgrade_type: int in visible_upgrades:
		var btn: Button = _create_button(upgrade_type)
		upgrades_h_box_container.add_child.call_deferred(btn)


func _on_upgrade_pressed(button: Button) -> void:
	var upgrade_type: int = button.get_meta("upgrade_type")
	UpgradeManager.apply_upgrade(upgrade_type)  # o la tua logica di applicazione

	# Rigenera tutti e tre i bottoni con upgrade casuali unici
	visible_upgrades.clear()
	while visible_upgrades.size() < VISIBLE_UPGRADES:
		var random_upgrade: int = upgrades[randi_range(0, upgrades.size() - 1)]
		if not visible_upgrades.has(random_upgrade):
			visible_upgrades.append(random_upgrade)

	upgrades_h_box_container.hide()
	_refresh_buttons()


func _on_tier_changed() -> void:
	show_upgrade_menu()


func show_upgrade_menu() -> void:
	# Nasconde i bottoni prima dell'animazione così lo stagger è netto
	for btn: Button in upgrades_h_box_container.get_children():
		btn.modulate.a = 0.0
	upgrades_h_box_container.show()
	await get_tree().process_frame  # aspetta un frame per avere size valido
	upgrades_h_box_container.pivot_offset = upgrades_h_box_container.size * 0.5
	upgrades_h_box_container.modulate.a = 0.0
	upgrades_h_box_container.scale = Vector2(0.8, 0.8)

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(upgrades_h_box_container, "modulate:a", 1.0, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(upgrades_h_box_container, "scale", Vector2.ONE, 0.45)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween.finished

	var i: int = 0
	for btn: Button in upgrades_h_box_container.get_children():
		var btn_tw: Tween = btn.create_tween()
		btn_tw.tween_interval(i * 0.07)
		btn_tw.tween_property(btn, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		i += 1
