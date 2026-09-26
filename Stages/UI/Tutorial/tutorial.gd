extends Node2D
## Tutorial interattivo passo-passo.
## Guida il giocatore attraverso le meccaniche principali, una alla volta:
## Movimento -> Orbite -> Energia & Upgrade -> Entropia & Shockwave.
## Mette gli autoload (entropia, upgrade, stat) in modalità controllata e li
## ripristina all'uscita, così la run vera parte sempre da uno stato pulito.

const METEOROID: PackedScene = preload("res://Entities/Enemies/SmallBodies/Meteoroids/meteoroid.tscn")
const ENERGY_DROP: PackedScene = preload("res://Entities/EnergyDrop/energy_drop.tscn")

const SOLAR_SYSTEM: String = "res://Stages/World/SolarSystem/solar_system.tscn"
const MAIN_MENU: String = "res://Stages/UI/MainMenu/main_menu.tscn"

enum Step { MOVEMENT, ORBIT, ENERGY_UPGRADE, ENTROPY, DONE }

## Quanto lontano può finire il corpo dello step orbita prima di considerarlo perso
## (in multipli del raggio d'attrazione del player).
const ORBIT_BODY_MAX_DISTANCE_MULT: float = 6.0

## OS.get_keycode_string() risponde in inglese: questi sono i tasti che finirebbero
## in mezzo a un prompt italiano. Quelli non elencati (lettere, numeri) vanno già bene.
const KEY_NAMES_IT: Dictionary = {
	"SPACE": "SPAZIO",
	"ESCAPE": "ESC",
	"ENTER": "INVIO",
	"KP ENTER": "INVIO",
	"SHIFT": "MAIUSC",
	"TAB": "TAB",
}

@onready var prompt_label: Label = %PromptLabel
@onready var end_buttons: Control = %EndButtons
@onready var skip_button: Button = %SkipButton
@onready var upgrade_ui: Control = $UILayer/UpgradeUI

var player: Player
var step: int = Step.MOVEMENT
var _step_ready: bool = false  # true quando lo step ha finito il suo setup

# --- Movimento ---
const MOVE_GOAL: float = 1800.0
var _last_pos: Vector2 = Vector2.ZERO
var _moved_distance: float = 0.0

# --- Orbite ---
var _orbit_bodies: Array = []
var _orbit_respawn_pending: bool = false  # true tra lo spawn e il setup differito del corpo

# --- Energia & Upgrade ---
var _menu_opened: bool = false


func _ready() -> void:
	# Modalità controllata: neutralizza gli autoload finché siamo nel tutorial.
	EntropyManager.reset_entropy()
	(EntropyManager.get_node("Timer") as Timer).stop()  # ferma il drift naturale dell'entropia
	UpgradeManager.reset_upgrades()
	StatTracker._tracking = false  # non registrare le statistiche della pratica

	end_buttons.hide()
	player = get_tree().get_first_node_in_group("player") as Player
	_start_movement()


func _physics_process(_delta: float) -> void:
	if not _step_ready or not is_instance_valid(player):
		return

	match step:
		Step.MOVEMENT:
			_moved_distance += player.global_position.distance_to(_last_pos)
			_last_pos = player.global_position
			if _moved_distance >= MOVE_GOAL:
				_advance_from_movement()
		Step.ORBIT:
			if player.get_current_orbiting_count() > 0:
				_advance_from_orbit()
			else:
				_ensure_orbit_body()
		Step.ENERGY_UPGRADE:
			# Il menu compare da solo al raggiungimento della soglia (tier_changed).
			# Lo rilevo quando appare, poi avanzo quando viene richiuso (scelta fatta).
			var menu_visible: bool = _menu_container_visible()
			if menu_visible and not _menu_opened:
				_menu_opened = true
				_set_prompt("Scegli un potenziamento!")
			elif _menu_opened and not menu_visible:
				_advance_from_energy()
		Step.ENTROPY:
			# Avanza quando il giocatore ha scaricato l'entropia con lo shockwave.
			if EntropyManager.entropy_value >= 0.0:
				_advance_from_entropy()


# ---------------------------------------------------------------------------
# STEP 1 — Movimento
# ---------------------------------------------------------------------------
func _start_movement() -> void:
	step = Step.MOVEMENT
	_set_prompt("Muoviti!\nUsa WASD, le frecce o tieni premuto il tasto sinistro del mouse.")
	_last_pos = player.global_position
	_moved_distance = 0.0
	_step_ready = true


func _advance_from_movement() -> void:
	_step_ready = false
	_set_prompt("Perfetto, ti muovi bene!")
	await get_tree().create_timer(1.3).timeout
	_start_orbit()


# ---------------------------------------------------------------------------
# STEP 2 — Orbite
# ---------------------------------------------------------------------------
func _start_orbit() -> void:
	step = Step.ORBIT
	_set_prompt(
		"Cattura un corpo in orbita!\nTieni premuto %s (o il tasto destro del mouse) per attrarlo."
		% _key_hint(&"orbit")
	)
	player.max_orbiting_bodies = maxi(player.max_orbiting_bodies, 2)
	_spawn_orbit_bodies()
	_step_ready = true


func _spawn_orbit_bodies() -> void:
	# Un solo corpo, a destra del player e appena fuori dal raggio d'attrazione.
	# Resta "pending" finché il setup differito non l'ha reso orbitabile, così il
	# watchdog non ne accoda altri nel frattempo.
	_orbit_respawn_pending = true
	var body: SmallBody = METEOROID.instantiate()
	body.position = player.global_position + Vector2.RIGHT * player.attraction_radius * 2.0
	add_child.call_deferred(body)
	_orbit_bodies.append(body)
	_make_orbitable.call_deferred(body)


## Anti-soft-lock: il corpo dello step orbita può sparire (il player ci sbatte contro e lo
## distrugge) o allontanarsi troppo per essere raggiunto. In quel caso lo step non potrebbe
## più completarsi, quindi ne rimetto uno. Il pending evita di spawnarne una fila mentre
## l'add_child differito è ancora in coda.
func _ensure_orbit_body() -> void:
	if _orbit_respawn_pending:
		return

	var max_distance: float = player.attraction_radius * ORBIT_BODY_MAX_DISTANCE_MULT
	for body: Variant in _orbit_bodies:
		if not is_instance_valid(body) or (body as Node).is_queued_for_deletion():
			continue
		var small: SmallBody = body as SmallBody
		# Solo un corpo FREE può essere "perso": se è già in attrazione sta rientrando da solo.
		if small.orbit_state != SmallBody.OrbitState.FREE:
			return
		if small.global_position.distance_to(player.global_position) <= max_distance:
			return
		# Alla deriva e irraggiungibile: lo tolgo e lo rimpiazzo. Lo sfilo anche da
		# nearby_bodies, altrimenti il player si porta dietro un riferimento morto.
		player.nearby_bodies.erase(small)
		small.queue_free()

	_orbit_bodies.clear()
	_spawn_orbit_bodies()


## Porta la massa del corpo a 1:1 col player così rientra nella finestra
## orbitabile (orbit_mass_ratio_min..max). NON tocco i ratio del player: la
## finestra di massa è una scelta di design voluta.
func _make_orbitable(body: SmallBody) -> void:
	_orbit_respawn_pending = false
	if not is_instance_valid(body) or not is_instance_valid(player):
		return
	body.mass = player.mass
	# Niente energia alla morte: col respawn anti-soft-lock il player potrebbe farmarla
	# speronandolo, arrivare al livello 3 prima dello step energia e bloccare il tutorial.
	body.drop_energy_on_death = false
	# Registro il corpo tra quelli vicini al player così Q lo cattura subito,
	# senza dipendere dal timing del rilevamento dell'area di attrazione.
	if not player.nearby_bodies.has(body):
		player.nearby_bodies.append(body)


func _advance_from_orbit() -> void:
	_step_ready = false
	_set_prompt("Ottimo! Ora hai un corpo in orbita.")
	await get_tree().create_timer(1.3).timeout
	_start_energy()


# ---------------------------------------------------------------------------
# STEP 3 — Energia & Upgrade
# ---------------------------------------------------------------------------
func _start_energy() -> void:
	step = Step.ENERGY_UPGRADE
	_menu_opened = false
	_set_prompt(
		"Raccogli l'energia qui intorno per crescere e salire di livello.\n"
		+ "Nella partita vera l'energia esce dai corpi celesti che distruggi."
	)
	_spawn_energy_drops()
	_step_ready = true


func _spawn_energy_drops() -> void:
	# 6×60 = 360 energia totale. Il livello 3 (prima soglia → menu upgrade) costa
	# 220 cumulativi: bastano 4 drop su 6, quindi mancarne uno non blocca lo step.
	# 360 resta sotto i 364 del livello 4, così si apre esattamente un menu.
	#
	# Angoli distribuiti (un drop per settore, con jitter) e raggio corto: prima erano
	# angolo e distanza del tutto casuali fino a 1000px, e capitava che nascessero tutti
	# fuori schermo — dal prompt sembrava che l'energia non fosse proprio spawnata.
	const DROP_COUNT: int = 6
	for i: int in range(DROP_COUNT):
		var drop: Area2D = ENERGY_DROP.instantiate()
		drop.energy = 60
		var ang: float = (TAU / DROP_COUNT) * i + randf_range(-0.35, 0.35)
		var dist: float = randf_range(260.0, 520.0)
		drop.position = player.global_position + Vector2(cos(ang), sin(ang)) * dist
		add_child.call_deferred(drop)


func _menu_container_visible() -> bool:
	var c: Control = upgrade_ui.get_node_or_null("UpgradesHBoxContainer") as Control
	return c != null and c.visible


func _advance_from_energy() -> void:
	_step_ready = false
	_set_prompt("Potenziamento applicato!")
	await get_tree().create_timer(1.3).timeout
	_start_entropy()


# ---------------------------------------------------------------------------
# STEP 4 — Entropia & Shockwave
# ---------------------------------------------------------------------------
func _start_entropy() -> void:
	step = Step.ENTROPY
	_set_prompt(
		"Senti l'instabilità?\nL'entropia negativa ti destabilizza: premi %s per scaricarla con uno shockwave."
		% _key_hint(&"entropy release")
	)
	EntropyManager.change_entropy(-6.0)  # forza entropia negativa -> il player inizia a tremare
	_step_ready = true


func _advance_from_entropy() -> void:
	_step_ready = false
	_set_prompt("Shockwave! Entropia scaricata.")
	await get_tree().create_timer(1.3).timeout
	_start_done()


# ---------------------------------------------------------------------------
# STEP 5 — Fine
# ---------------------------------------------------------------------------
func _start_done() -> void:
	step = Step.DONE
	_step_ready = false
	_set_prompt("Tutorial completato! Sei pronto.")
	skip_button.hide()
	end_buttons.show()


# ---------------------------------------------------------------------------
# Uscita / pulizia
# ---------------------------------------------------------------------------
## Ripristina gli autoload qualunque sia la via d'uscita dal tutorial (pulsanti
## Gioca/Menu/Salta, ma ANCHE PauseMenu→Menu o morte del player): la pulizia è
## agganciata al ciclo di vita del nodo, non ai singoli pulsanti, così il drift
## dell'entropia, il tracking delle statistiche e la progressione non restano
## "sporchi" per la run vera.
func _exit_tree() -> void:
	_cleanup_globals()


func _cleanup_globals() -> void:
	EntropyManager.reset_entropy()
	EntropyManager.entropy_changed.emit(0.0)  # aggiorna l'HUD dell'entropia
	(EntropyManager.get_node("Timer") as Timer).start()  # riattiva il drift per la run vera
	UpgradeManager.reset_upgrades()
	StatTracker.reset()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(SOLAR_SYSTEM)


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)


func _on_skip_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)


func _set_prompt(text: String) -> void:
	prompt_label.text = text


## Nome del primo tasto mappato su un'azione, per i prompt.
## I tasti NON vanno scritti a mano nei testi: dopo un remap dell'input map il tutorial
## ha già insegnato comandi inesistenti (diceva Q e SPAZIO quando ormai erano SPAZIO ed E).
## Leggendoli da qui i prompt seguono l'input map da soli.
func _key_hint(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		var key: InputEventKey = event as InputEventKey
		if key == null:
			continue
		var code: Key = key.physical_keycode
		if code != KEY_NONE:
			# physical_keycode è la POSIZIONE del tasto: va tradotta nel layout dell'utente,
			# altrimenti su AZERTY mostreremmo la lettera sbagliata. Il display server headless
			# non sa farlo e stampa un ERROR: lì la posizione va bene così com'è.
			if DisplayServer.get_name() != "headless":
				code = DisplayServer.keyboard_get_keycode_from_physical(code)
		else:
			code = key.keycode
		if code == KEY_NONE:
			continue
		var name: String = OS.get_keycode_string(code).to_upper()
		return KEY_NAMES_IT.get(name, name)
	return "?"
