extends Control

# I path relativi valgono solo in world.tscn; in altre scene (es. Tutorial) la
# GameOverScreen sta sotto UILayer e questi nodi non esistono: risolvi in modo sicuro.
@onready var death_camera: Camera2D = get_node_or_null("../../DeathCamera") as Camera2D
@onready var player_camera: Camera2D = _find_player_camera()
@onready var level_label: Label = %LevelLabel
@onready var time_label: Label = %TimeLabel
@onready var kills_label: Label = %KillsLabel
@onready var energy_label: Label = %EnergyLabel
@onready var record_label: Label = %RecordLabel
@onready var new_record_label: Label = %NewRecordLabel

func _ready() -> void:
	get_tree().paused = false
	hide()
	GlobalSignals.connect("game_over", _on_game_over)


func _on_retry_button_pressed() -> void:
	StatTracker.reset()
	get_tree().reload_current_scene()


func _on_main_menu_button_pressed() -> void:
	StatTracker.reset()
	get_tree().change_scene_to_file("res://Stages/UI/MainMenu/main_menu.tscn")


func _find_player_camera() -> Camera2D:
	var cam: Camera2D = get_node_or_null("../../Player/PlayerCamera") as Camera2D
	if cam != null:
		return cam
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null:
		return player.find_child("PlayerCamera", true, false) as Camera2D
	return null


func _on_game_over() -> void:
	# La camera di morte è solo rifinitura: salta se la scena non la prevede.
	if death_camera != null and player_camera != null:
		death_camera.global_position = player_camera.global_position
		death_camera.make_current()
		death_camera.zoom = player_camera.zoom * 0.75

	level_label.text = "Livello: %d" % StatTracker.level_reached
	time_label.text = "Tempo: %s" % StatTracker.format_time(StatTracker.time_survived)
	kills_label.text = "Nemici: %d" % StatTracker.enemies_killed
	energy_label.text = "Energia: %.0f" % StatTracker.energy_collected

	record_label.text = "Record: %s (lvl %d)" % [StatTracker.format_time(StatTracker.best_time), StatTracker.best_level]
	new_record_label.visible = StatTracker.last_run_new_record

	show()
