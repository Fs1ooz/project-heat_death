extends Node2D

const CERES_SCENE: PackedScene = preload("res://Entities/Enemies/SmallBodies/Ceres/ceres.tscn")
const CERES_SPAWN_DIST_MIN: float = 200_000.0
const CERES_SPAWN_DIST_MAX: float = 300_000.0


func _ready() -> void:
	$CelestialBodiesSpawner.ceres_should_spawn.connect(_spawn_ceres)


func _spawn_ceres() -> void:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if not is_instance_valid(player):
		return
	var angle: float = randf() * TAU
	var dist: float = randf_range(CERES_SPAWN_DIST_MIN, CERES_SPAWN_DIST_MAX)
	var ceres: Node2D = CERES_SCENE.instantiate()
	add_child(ceres)
	ceres.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	printerr("Ceres spawnata | stage=ASTEROIDS_3 distanza=", dist)


# Sistema Solare completo con dati NASA/JPL accurati
const SOLAR_SYSTEM: Dictionary = {
	"Sun": { "au": 0.0, "desc": "Il Sole" },

	"InnerSystem": {
		"au_min": 0.39, "au_max": 1.52,
		"desc": "Pianeti Rocciosi",
		"planets": {
			"Mercury": { "au": 0.39, "asteroids": 0, "meteoroids": 5 },
			"Venus": { "au": 0.72, "asteroids": 0, "meteoroids": 8 },
			"Earth": { "au": 1.0, "asteroids": 0, "meteoroids": 15 },
			"Mars": { "au": 1.52, "asteroids": 2, "meteoroids": 20 }
		}
	},

	"AsteroidBelt": {
		"au_min": 1.78, "au_max": 4.0,
		"desc": "Fascia Principale",
		"spawn_zone": true,
		"regions": {
			"InnerTransition": {
				"au_min": 1.78, "au_max": 2.06,
				"asteroids": 5, "meteoroids": 75
			},
			"InnerBelt": {
				"au_min": 2.06, "au_max": 2.5,
				"asteroids": 25, "meteoroids": 225,
				"families": {
					"Flora": { "au_min": 2.15, "au_max": 2.35, "asteroids": 15, "meteoroids": 300 }
				}
			},
			"Gap3to1": {
				"au_min": 2.48, "au_max": 2.52,
				"asteroids": 2, "meteoroids": 35
			},
			"MiddleBelt": {
				"au_min": 2.52, "au_max": 2.82,
				"asteroids": 40, "meteoroids": 325,
				"default_spawn": true,
				"families": {
					"Eunomia": { "au_min": 2.52, "au_max": 2.72, "asteroids": 15, "meteoroids": 250 }
				}
			},
			"Gap5to2": {
				"au_min": 2.79, "au_max": 2.85,
				"asteroids": 1, "meteoroids": 50
			},
			"OuterBelt": {
				"au_min": 2.85, "au_max": 3.28,
				"asteroids": 60, "meteoroids": 600,
				"families": {
					"Koronis": { "au_min": 2.82, "au_max": 2.95, "asteroids": 12, "meteoroids": 110 },
					"Themis": { "au_min": 3.08, "au_max": 3.24, "asteroids": 20, "meteoroids": 190 },
					"Hygiea": { "au_min": 3.06, "au_max": 3.24, "asteroids": 18, "meteoroids": 160 }
				}
			},
			"Gap2to1": {
				"au_min": 3.27, "au_max": 3.29,
				"asteroids": 0, "meteoroids": 20
			},
			"OuterEdge": {
				"au_min": 3.29, "au_max": 4.0,
				"asteroids": 35, "meteoroids": 300,
				"groups": {
					"Cybele": { "au_min": 3.3, "au_max": 3.5, "asteroids": 20, "meteoroids": 175 },
					"Hilda": { "au_min": 3.7, "au_max": 4.0, "asteroids": 15, "meteoroids": 125 }
				}
			}
		}
	},

	"OuterSystem": {
		"au_min": 5.2, "au_max": 30.1,
		"desc": "Giganti Gassosi",
		"planets": {
			"Jupiter": { "au": 5.2, "asteroids": 10, "meteoroids": 100 },
			"Saturn": { "au": 9.58, "asteroids": 8, "meteoroids": 80 },
			"Uranus": { "au": 19.22, "asteroids": 5, "meteoroids": 50 },
			"Neptune": { "au": 30.07, "asteroids": 5, "meteoroids": 50 }
		}
	},

	"KuiperBelt": {
		"au_min": 30.0, "au_max": 50.0,
		"desc": "Fascia di Kuiper",
		"regions": {
			"InnerKuiper": { "au_min": 30.0, "au_max": 40.0, "asteroids": 30, "meteoroids": 500 },
			"OuterKuiper": { "au_min": 40.0, "au_max": 50.0, "asteroids": 20, "meteoroids": 300 }
		}
	}
}


#func _ready() -> void:
	#_recenter_world()
#
#func _recenter_world() -> void:
	#await get_tree().create_timer(1).timeout
	#global_position = %Player.global_position
