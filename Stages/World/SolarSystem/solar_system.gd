extends Node2D

const PLACEHOLDER_PLANET = preload("res://Entities/Enemies/placeholder_planet.tscn")
@onready var sun := $Sun/Collision

# Scala separata per distanze e dimensioni
const DISTANCE_SCALE = 500000.0  # 1 pixel = 500,000 km (distanze più compatte)
const SIZE_SCALE = 2000.0  # 1 pixel = 2,000 km (corpi celesti più visibili)

# Dati reali del sistema solare
const SUN_RADIUS = 696000  # km
const PLANET_DATA = {
	"Mercurio": {"distance": 57900000, "radius": 2439.7},
	"Venere": {"distance": 108200000, "radius": 6051.8},
	"Terra": {"distance": 149600000, "radius": 6371.0},
	"Marte": {"distance": 227900000, "radius": 3389.5},
	"Giove": {"distance": 778500000, "radius": 69911},
	"Saturno": {"distance": 1434000000, "radius": 58232},
	"Urano": {"distance": 2871000000, "radius": 25362},
	"Nettuno": {"distance": 4495000000, "radius": 24622}
}

var planets = []

func _ready() -> void:
	setup_solar_system()

func setup_solar_system() -> void:
	# Imposta la dimensione del Sole
	var sun_diameter = (SUN_RADIUS * 2) / SIZE_SCALE
	sun.scale = Vector2(sun_diameter, sun_diameter)

	# Posiziona il Sole al centro dello schermo
	sun.position = get_viewport_rect().size / 2

	# Crea i pianeti
	for planet_name in PLANET_DATA.keys():
		var data = PLANET_DATA[planet_name]
		create_planet(planet_name, data.distance, data.radius)

	print("Sistema solare creato!")
	print("Sole: diametro %.1f pixels" % sun_diameter)

func create_planet(planet_name: String, distance_km: float, radius_km: float) -> void:
	var planet = PLACEHOLDER_PLANET.instantiate()
	add_child(planet)

	# Calcola distanza e dimensione con scale separate
	var distance_pixels = distance_km / DISTANCE_SCALE
	var planet_diameter = (radius_km * 2) / SIZE_SCALE

	# Posiziona il pianeta alla giusta distanza dal Sole (a destra per semplicità)
	planet.position = sun.position + Vector2(distance_pixels, 0)
	planet.scale = Vector2(planet_diameter, planet_diameter)
	planet.name = planet_name

	planets.append(planet)

	print("%s: distanza %.1f px, diametro %.2f px" % [planet_name, distance_pixels, planet_diameter])
