class_name InterpolatedTrail
extends GPUParticles2D
## Scia di particelle in spazio globale, fluida con physics interpolation attiva e fisica a 60 Hz.
##
## Problema: il sistema di particelle emette ad OGNI frame di rendering (es. 165 fps), ma se
## l'emettitore è figlio di un corpo mosso dalla fisica a 60 Hz, la sua posizione si aggiorna solo
## 60 volte/s → ~3 particelle nascono nello stesso punto, poi "salta" → scia "a pallini"/tremolante.
##
## In 2D NON esiste get_global_transform_interpolated() (è solo 3D). Quindi ricostruiamo a mano la
## trasformata interpolata dell'emettitore: memorizziamo la transform del sorgente ai due ultimi
## tick di fisica e la interpoliamo ogni frame con Engine.get_physics_interpolation_fraction().
## Risultato: l'emettitore si muove fluido ad ogni frame → emissione liscia.
##
## Da assegnare al nodo GPUParticles2D figlio del corpo da inseguire (player, ecc.).

var _source: Node2D = null
var _prev: Transform2D
var _curr: Transform2D


func _ready() -> void:
	_source = get_parent() as Node2D
	# top_level: posizioniamo noi la scia in coordinate globali.
	top_level = true
	# L'interpolazione la facciamo a mano qui sotto: il motore non deve interpolare questo nodo.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if is_instance_valid(_source):
		_curr = _source.global_transform
		_prev = _curr
		global_transform = _curr


func _physics_process(_delta: float) -> void:
	if is_instance_valid(_source):
		_prev = _curr
		_curr = _source.global_transform


func _process(_delta: float) -> void:
	if is_instance_valid(_source):
		# Posizione/rotazione/scala interpolate tra gli ultimi due tick di fisica → emissione fluida.
		global_transform = _prev.interpolate_with(_curr, Engine.get_physics_interpolation_fraction())
