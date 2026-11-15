extends Node
## Shared game data (autoload "GameData"): the five astronauts, their planets,
## the story progress and the player's settings (language, music, volume).
## Texts: the base key is Spanish and "<key>_en" is English; use txt() / t(). Placeholder content lives here until
## it is loaded from Supabase. Sprite sheets come from the team folders
## (personaje_1_hackeo/, personaje_2_gravedad/, ...).

## Index i of CHARACTERS lands on index i of PLANETS.
var characters: Array[Dictionary] = [
	{
		"name": "Andrew",
		"power": "Hackeo de robots",
		"power_en": "Robot Hack",
		"discipline": "Energía",
		"discipline_en": "Energy",
		"color": Color(1.0, 0.82, 0.1),
		"script": "res://scripts/characters/hacker.gd",
		## Team sprite sheet (LPC). If the PNG is missing, a placeholder rectangle is drawn.
		"sprite": "res://personaje_1_hackeo/diseño edwin.png",
		"hint": "E: apaga a los perros robot cercanos",
		"hint_en": "E: cut the power of nearby robot dogs",
	},
	{
		"name": "Bels",
		"power": "Gravedad cero",
		"power_en": "Zero Gravity",
		"discipline": "Propulsión + Orientación",
		"discipline_en": "Propulsion + Attitude",
		"color": Color(0.3, 0.55, 1.0),
		"script": "res://scripts/characters/zero_gravity.gd",
		## Team sprite sheet (LPC). If the PNG is missing, a placeholder rectangle is drawn.
		"sprite": "res://personaje_2_gravedad/character-spritesheet (1).png",
		"hint": "E: activa/desactiva la gravedad cero (flotas y te orientas solo)",
		"hint_en": "E: toggle zero gravity (drift + auto-orient)",
	},
	{
		"name": "Ray",
		"power": "Visión infrarroja",
		"power_en": "Infrared Vision",
		"discipline": "Térmico",
		"discipline_en": "Thermal",
		"color": Color(1.0, 0.45, 0.2),
		"script": "res://scripts/characters/infrared.gd",
		## Team sprite sheet (LPC). If the PNG is missing, a placeholder rectangle is drawn.
		"sprite": "res://personaje_3_infrarroja/andres.png",
		"hint": "E: escanea fuentes de calor ocultas",
		"hint_en": "E: scan for hidden heat sources",
	},
	{
		"name": "Daenerys",
		"power": "Desencriptación",
		"power_en": "Decryption",
		"discipline": "Comunicaciones",
		"discipline_en": "Communications",
		"color": Color(0.4, 1.0, 0.45),
		"script": "res://scripts/characters/decryptor.gd",
		## Team sprite sheet (LPC). If the PNG is missing, a placeholder rectangle is drawn.
		"sprite": "res://personaje_4_desencriptacion/jeissa.png",
		"hint": "E: descifra las balizas alien cercanas",
		"hint_en": "E: decrypt nearby alien beacons",
	},
	{
		"name": "Rayan",
		"power": "Clon holográfico",
		"power_en": "Holo Clone",
		"discipline": "Riesgo + Redundancia",
		"discipline_en": "Risk + Redundancy",
		"color": Color(0.75, 0.45, 1.0),
		"script": "res://scripts/characters/holo_clone.gd",
		## Team sprite sheet (LPC). If the PNG is missing, a placeholder rectangle is drawn.
		"sprite": "res://personaje_5_clon/character-spritesheet.png",
		"hint": "E: deja un holograma de respaldo (reapareces ahí, recarga de 5 s)",
		"hint_en": "E: drop a backup hologram (respawn there, 5 s recharge)",
	},
]

var planets: Array[Dictionary] = [
	{
		"name": "Yuki",
		"image": "res://assets/planets/Planeta_VillaCaracas.png",
		## Diameter of the planet body inside the image, in px (rings and empty space excluded).
		"image_body": 99,
		"color": Color(0.5, 0.5, 0.68),
		"ground": Color(0.16, 0.16, 0.22),
		"problem": "El planeta se quedó sin luz y lo vigilan perros robot.",
		"problem_en": "The planet ran out of power and robot dogs guard it.",
		"story": "El módulo de Andrew cae en la oscuridad. No hay luz en ningún lado... y algo está ladrando.",
		"story_en": "Andrew's module crashes in the dark. No power anywhere... and something is barking.",
		"objective": "Apaga a los 5 perros robot: 2 hackeos cada uno (¡muerden!)",
		"objective_en": "Shut down the 5 robot dogs: 2 hacks each (they bite!)",
	},
	{
		"name": "Zero",
		"image": "res://assets/planets/Planeta_Zero.png",
		"image_body": 99,
		"color": Color(0.55, 0.8, 1.0),
		"ground": Color(0.1, 0.16, 0.26),
		"problem": "No hay gravedad y todo flota.",
		"problem_en": "There is no gravity and everything floats.",
		"story": "Bels despierta de cabeza. En Zero nada se queda en el suelo.",
		"story_en": "Bels wakes up upside down. On Zero, nothing stays on the ground.",
		"objective": "Activa la gravedad cero y atrapa 3 paneles solares (evita lo rojo)",
		"objective_en": "Turn on zero gravity and grab 3 solar panels (avoid the red)",
	},
	{
		"name": "Fernix",
		"image": "res://assets/planets/Planeta_Fernix.png",
		"image_body": 99,
		"color": Color(0.92, 0.42, 0.22),
		"ground": Color(0.24, 0.1, 0.07),
		"problem": "Calor extremo y frío extremo.",
		"problem_en": "Extreme heat and extreme cold.",
		"story": "El visor de Ray se empaña: abrasador de un lado, congelado del otro.",
		"story_en": "Ray's visor fogs up: scorching on one side, freezing on the other.",
		"objective": "Encuentra los 4 bolsillos de aire en 60 s",
		"objective_en": "Find the 4 trapped air pockets in 60 s",
	},
	{
		"name": "Draugr",
		"image": "res://assets/planets/Planeta_Draugr.png",
		"image_body": 99,
		"color": Color(0.3, 0.72, 0.52),
		"ground": Color(0.06, 0.18, 0.14),
		"problem": "Nadie se entiende y la radio es puro ruido.",
		"problem_en": "Nobody understands each other and the radio is pure noise.",
		"story": "Daenerys oye mil voces en la radio y ninguna tiene sentido.",
		"story_en": "Daenerys hears a thousand voices on the radio, and none of them make sense.",
		"objective": "Descifra las 3 balizas alien (evita el ruido rojo)",
		"objective_en": "Decrypt the 3 alien beacons (avoid the red noise)",
	},
	{
		"name": "Control C",
		"image": "res://assets/planets/Planeta_ControlC.png",
		"image_body": 99,
		"color": Color(0.62, 0.36, 0.85),
		"ground": Color(0.14, 0.08, 0.2),
		"problem": "Todo falla al menos una vez.",
		"problem_en": "Everything fails at least once.",
		"story": "Los sistemas de Rayan fallan y los fantasmas del laboratorio de Control C se acercan. Aquí todo falla al menos una vez.",
		"story_en": "Rayan's systems glitch and the ghosts of the Control C lab are coming. Here, everything fails at least once.",
		"objective": "Sobrevive 25 s. Los fantasmas aceleran; tu clon los distrae 3 s",
		"objective_en": "Survive 25 s. Ghosts speed up; your clone distracts them for 3 s",
	},
]

const SETTINGS_PATH := "user://settings.cfg"

## "es" or "en". Changed in the lobby or the pause menu.
var lang: String = "es"
var music_on: bool = true
## 0..1
var music_volume: float = 0.6

## Linear story: chapter i = astronaut i on planet i. 0..4, then the ending.
var chapter: int = 0
## Which of the planet's missions the missions screen opens on (DevCapture uses it).
var mission_index: int = 0
## Set by DevCapture (--touch) to show touch controls on a PC.
var force_touch: bool = false

## Data from Supabase (empty until it loads, or if there is no connection).
var questions: Array = []
var risks: Array = []

var _planet_textures: Dictionary = {}


func _ready() -> void:
	_load_settings()
	add_action("move_left", [KEY_A, KEY_LEFT])
	add_action("move_right", [KEY_D, KEY_RIGHT])
	add_action("move_up", [KEY_W, KEY_UP])
	add_action("move_down", [KEY_S, KEY_DOWN])
	add_action("ability", [KEY_E])
	add_action("confirm", [KEY_ENTER, KEY_SPACE, KEY_KP_ENTER])
	add_action("back", [KEY_ESCAPE])
	_load_remote_data()


func _load_remote_data() -> void:
	questions = await Supabase.fetch("preguntas_juego")
	risks = await Supabase.fetch("riesgos")
	print("Supabase: loaded %d questions, %d risks" % [questions.size(), risks.size()])


# --- language and settings ----------------------------------------------------

## The Spanish or English text, depending on the chosen language.
func t(es: String, en: String) -> String:
	return en if lang == "en" else es


## d[key] in Spanish, d[key + "_en"] in English (falls back to Spanish).
func txt(d: Dictionary, key: String) -> Variant:
	if lang == "en" and d.has(key + "_en"):
		return d[key + "_en"]
	return d.get(key, "")


func set_lang(value: String) -> void:
	lang = value
	save_settings()


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	lang = config.get_value("game", "lang", lang)
	music_on = config.get_value("audio", "music_on", music_on)
	music_volume = config.get_value("audio", "music_volume", music_volume)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "lang", lang)
	config.set_value("audio", "music_on", music_on)
	config.set_value("audio", "music_volume", music_volume)
	config.save(SETTINGS_PATH)


func add_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)


func current_character() -> Dictionary:
	return characters[chapter]


func current_planet() -> Dictionary:
	return planets[chapter]


## Planet image (assets/planets), or null if it is missing. Cached on purpose:
## a texture loaded inside _draw() and not kept alive renders as a white box.
## Where to draw planet i's image so its body is a circle of `radius` around
## `center`. The images have different canvas sizes (Draugr has rings, Control C
## has empty space), so they are scaled by the body size, not the image size.
func planet_rect(i: int, center: Vector2, radius: float) -> Rect2:
	var tex := planet_texture(i)
	var body: float = planets[i].get("image_body", 0)
	if tex == null or body <= 0.0:
		return Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	var size := tex.get_size() * (radius * 2.0 / body)
	return Rect2(center - size / 2.0, size)


func planet_texture(i: int) -> Texture2D:
	if _planet_textures.has(i):
		return _planet_textures[i]
	var path: String = planets[i].get("image", "")
	var tex: Texture2D = null
	if not path.is_empty() and ResourceLoader.exists(path):
		tex = load(path)
	_planet_textures[i] = tex
	return tex


func is_last_chapter() -> bool:
	return chapter >= planets.size() - 1


## Touch controls show on phones/tablets (or when forced for testing).
func use_touch() -> bool:
	return force_touch or DisplayServer.is_touchscreen_available()
