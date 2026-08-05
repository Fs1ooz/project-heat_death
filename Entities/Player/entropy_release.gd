class_name EntropyRelease
extends Node
## Scarica l'entropia negativa accumulata in un'onda d'urto (tasto "entropy release").
##
## Visivo e gameplay sono LO STESSO evento. Il danno non è un'area che colpisce tutto insieme:
## è un fronte circolare che parte dal punto di rilascio e si espande con ESATTAMENTE la stessa
## velocità dell'anello disegnato dallo shader, colpendo ogni corpo nell'istante in cui il cerchio
## lo attraversa. La velocità non è un numero copiato a mano: viene LETTA dai parametri dell'anello
## (radius_mult × lato del quad × scala del player), quindi il visivo resta la fonte di verità e
## ritoccare lo shader nell'editor aggiusta il danno da solo.
##
## Sequenza: CARICA (slow-mo di anticipazione) → BOTTA (quasi fermo immagine, l'anello parte e resta
## congelato a schermo) → RIPRESA (anello e fronte scattano fuori insieme).

const CHARGE_SFX: AudioStream = preload("res://Assets/Sounds/sfx/outgassing.wav")
const BLAST_SFX: AudioStream = preload("res://Assets/Sounds/explosion.sfxr")

## Entropia (in valore assoluto) alla quale la scarica è "al massimo": oltre, il feedback non cresce più.
const FULL_POWER_ENTROPY: float = 100.0
## Numero di anelli: il visivo resta quello di sempre, non scala con l'entropia.
const WAVE_COUNT: int = 3

#region Tempi
## Sono SECONDI REALI: i timer della sequenza ignorano Engine.time_scale, altrimenti lo slow-mo
## che loro stessi impostano li allungherebbe di 50 volte.
const CHARGE_TIME_MIN: float = 0.10
const CHARGE_TIME_MAX: float = 0.20
const STOP_TIME_MIN: float = 0.06
const STOP_TIME_MAX: float = 0.16
const CHARGE_TIME_SCALE: float = 0.20  ## rallenta il mondo mentre il corpo si comprime
const STOP_TIME_SCALE: float = 0.02    ## quasi fermo immagine sulla detonazione
#endregion

#region Fronte di danno
## Danno al bordo esterno dell'onda, in frazione di quello all'epicentro.
const DAMAGE_FALLOFF: float = 0.45
## Velocità (px/s) impressa ai corpi investiti, dalla scarica più debole alla più potente.
const KNOCKBACK_MIN: float = 180.0
const KNOCKBACK_MAX: float = 700.0
## Progresso a cui l'anello è ormai svanito (nello shader life_fade si annulla a 1.0): oltre
## quel raggio non c'è più niente da vedere, quindi non c'è più niente da colpire.
const RING_MAX_PROGRESS: float = 1.0
## Usato solo se il materiale non espone radius_mult (default dello shader).
const DEFAULT_RADIUS_MULT: float = 0.5
#endregion

var _player: Player
var _charge_sfx: AudioStreamPlayer
var _blast_sfx: AudioStreamPlayer
var _sprite_tween: Tween

## Una scarica alla volta: senza questo, tenendo premuto il tasto i time_scale si accavallano.
var _is_releasing: bool = false

# Stato del fronte in corsa (attivo solo mentre _physics_process è acceso).
var _front_origin: Vector2 = Vector2.ZERO
var _front_radius: float = 0.0
var _front_speed: float = 0.0
var _front_max: float = 0.0
var _front_damage: float = 0.0
var _front_power: float = 0.0
var _front_hit: Dictionary = {}  ## instance_id dei corpi già investiti: un colpo a testa


func _ready() -> void:
	_player = get_parent() as Player
	set_physics_process(false)
	_charge_sfx = _make_sfx_player(CHARGE_SFX, -8.0)
	_blast_sfx = _make_sfx_player(BLAST_SFX, -2.0)
	# Se il player sparisce a metà scarica (morte), il tempo non deve restare rallentato.
	tree_exiting.connect(_restore_time_scale)


func _make_sfx_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var sfx: AudioStreamPlayer = AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.volume_db = volume_db
	sfx.bus = &"Sound"
	add_child(sfx)
	return sfx


## Tenta la scarica. Restituisce true se è partita davvero, così il player sa se consumare l'input.
func try_release() -> bool:
	if _is_releasing or EntropyManager.entropy_value >= 0.0:
		return false
	_release(absf(EntropyManager.entropy_value))
	return true


func _release(entropy: float) -> void:
	_is_releasing = true
	var power: float = clampf(entropy / FULL_POWER_ENTROPY, 0.0, 1.0)

	# Per tutta la scarica lo sprite è "mio": is_growing è il lock che _animate_player() già
	# rispetta (lo usa la crescita di livello), così lo squash da movimento non ruba l'animazione.
	_player.is_growing = true
	if _player.current_tween:
		_player.current_tween.kill()

	await _charge(power)
	if not is_instance_valid(_player):
		return

	_blast(entropy, power)
	await _real_timer(lerpf(STOP_TIME_MIN, STOP_TIME_MAX, power))
	if not is_instance_valid(_player):
		return

	_restore_time_scale()
	_player.is_growing = false


## CARICA: il mondo rallenta, il corpo si comprime, il suono sale. Pura anticipazione.
func _charge(power: float) -> void:
	var duration: float = lerpf(CHARGE_TIME_MIN, CHARGE_TIME_MAX, power)

	if not SettingsManager.reduce_effects:
		Engine.time_scale = CHARGE_TIME_SCALE
		_player.player_camera.apply_shake(1.5 + 5.0 * power, duration * 2.0)
		# I tween ignorano il time_scale: mondo al rallentatore, carica a velocità piena.
		_sprite_tween = _player.create_tween().set_ignore_time_scale(true)
		_sprite_tween.tween_property(
			_player.sprite, "scale", _player.base_scale * (1.0 - 0.22 * power), duration
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	_charge_sfx.pitch_scale = 0.6
	_charge_sfx.play()
	var tw_pitch: Tween = create_tween().set_ignore_time_scale(true)
	tw_pitch.tween_property(_charge_sfx, "pitch_scale", 2.2, duration)

	await _real_timer(duration)


## BOTTA: il tempo si inchioda, l'anello parte (e resta fermo a schermo finché il tempo non riparte),
## il fronte di danno viene armato con gli stessi numeri dell'anello.
func _blast(entropy: float, power: float) -> void:
	var origin: Vector2 = _player.global_position

	if not SettingsManager.reduce_effects:
		Engine.time_scale = STOP_TIME_SCALE

	_player.shockwave.trigger_shockwave(origin, WAVE_COUNT)
	_start_front(origin, entropy, power)

	_player.player_camera.apply_shake(7.0 + 16.0 * power, 0.5 + 0.5 * power)

	# Più entropia scarichi, più il colpo è cupo e profondo.
	_blast_sfx.pitch_scale = lerpf(1.35, 0.6, power)
	_blast_sfx.play()

	# L'energia è appena uscita dal corpo: la spinta accumulata si smorza.
	_player.linear_velocity *= lerpf(1.0, 0.45, power)
	_player.angular_velocity *= 0.35

	_flash_player(power)

	EntropyManager.change_entropy(entropy * 2.0)
	GlobalSignals.entropy_released.emit(power)


## Lampo bianco + stretch: il corpo "sputa fuori" l'onda.
func _flash_player(power: float) -> void:
	if _sprite_tween:
		_sprite_tween.kill()

	_sprite_tween = _player.create_tween().set_ignore_time_scale(true)
	_sprite_tween.tween_property(
		_player.sprite, "scale", _player.base_scale * (1.0 + 0.30 * power), 0.10
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_sprite_tween.tween_property(_player.sprite, "scale", _player.base_scale, 0.55)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Lo cedo al player: così _animate_player() sa di doverlo uccidere prima di riprendersi lo sprite.
	_player.current_tween = _sprite_tween

	var tw_flash: Tween = _player.create_tween().set_ignore_time_scale(true)
	tw_flash.tween_property(_player.sprite, "modulate", Color(3.5, 3.5, 3.5, 1.0), 0.04)
	tw_flash.tween_property(_player.sprite, "modulate", Color.WHITE, 0.35)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


## Arma il fronte di danno leggendo la geometria dell'anello: nel renderer il progresso avanza di
## 1.0 al secondo e il cerchio sta a (progresso × radius_mult) in UV, su un quad largo quad_size
## scalato come il player. Da qui escono velocità e raggio massimo, in pixel di mondo.
func _start_front(origin: Vector2, entropy: float, power: float) -> void:
	var ring: ShockwaveRenderer = _player.shockwave
	var quad_size: float = (ring.mesh as QuadMesh).size.x
	var radius_mult: Variant = ring.material.get_shader_parameter("radius_mult")
	var mult: float = float(radius_mult) if radius_mult != null else DEFAULT_RADIUS_MULT

	_front_origin = origin
	_front_radius = 0.0
	_front_speed = mult * quad_size * ring.scale.x
	_front_max = maxf(_front_speed * RING_MAX_PROGRESS, 1.0)
	_front_damage = entropy * _player.mass
	_front_power = power
	_front_hit.clear()

	set_physics_process(true)


func _physics_process(delta: float) -> void:
	# delta è già scalato da Engine.time_scale, esattamente come il _process del renderer:
	# durante il fermo immagine il fronte resta congelato insieme all'anello, senza codice apposta.
	_front_radius += _front_speed * delta

	var knockback: float = lerpf(KNOCKBACK_MIN, KNOCKBACK_MAX, _front_power)
	var hit_any: bool = false

	# duplicate(): take_damage() può uccidere un corpo, e la morte tocca l'array statico.
	for body: CelestialBody in CelestialBody.celestial_bodies.duplicate():
		if not is_instance_valid(body) or body.is_queued_for_deletion():
			continue
		var id: int = body.get_instance_id()
		if _front_hit.has(id):
			continue

		var offset: Vector2 = body.global_position - _front_origin
		var dist: float = offset.length()
		if dist > _front_radius:
			continue  # l'onda non l'ha ancora raggiunto: toccherà a lui più avanti

		_front_hit[id] = true
		hit_any = true

		# Spinta radiale: impulso ∝ massa, così sasso e boss subiscono la stessa variazione di
		# velocità. I corpi in orbita sono freeze = true: spingerli romperebbe la cattura.
		if not body.freeze:
			var dir: Vector2 = offset / dist if dist > 0.001 else Vector2.RIGHT.rotated(randf() * TAU)
			body.apply_central_impulse(dir * knockback * body.mass)

		if body.has_method("take_damage"):
			body.take_damage(_front_damage * lerpf(1.0, DAMAGE_FALLOFF, dist / _front_max))

	if hit_any:
		_player.player_camera.apply_shake(2.0, 0.2)

	if _front_radius >= _front_max:
		set_physics_process(false)
		_front_hit.clear()


func _restore_time_scale() -> void:
	if not _is_releasing:
		return
	_is_releasing = false
	Engine.time_scale = 1.0


## Timer in secondi REALI (process_always + ignore_time_scale): la sequenza non si allunga con lo
## slow-mo che imposta lei stessa, e non resta appesa se il gioco va in pausa a metà scarica.
func _real_timer(seconds: float) -> Signal:
	return get_tree().create_timer(seconds, true, false, true).timeout
