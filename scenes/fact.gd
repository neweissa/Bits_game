extends Node2D
## "¿Sabías que?" card, shown after a planet's missions and before the ship
## engineering: the real CubeSat (or the real engineering) behind that planet,
## with three facts from the NASA data in our Supabase database.
## GameData.chapter is already the NEXT planet here, so the card is for chapter - 1.
## ENTER / tap continues to scenes/travel.tscn.

const W := 640.0
const H := 360.0

## One card per planet: name, tag and three facts, in Spanish and English;
## "art" picks the drawing; "source" says where the facts come from.
const CARDS := [
	{
		"name": "ChargerSat-1", "art": "panels",
		"tag": "Energía", "tag_en": "Energy",
		"facts": [
			"Sus paneles solares desplegables casi duplican la energía de la nave y además mejoran la señal de su antena.",
			"Dentro del dispensador, los interruptores de separación mantienen el CubeSat apagado; al salir al espacio se sueltan y la nave se enciende.",
			"Las baterías deben tener certificación UL. Si no la tienen, el lanzador exige pruebas extra.",
		],
		"facts_en": [
			"Its deployable solar panels almost double the ship's power and also improve its antenna signal.",
			"Inside the deployer, separation switches keep the CubeSat off; once in space they release and the ship turns on.",
			"Batteries must be UL certified. If not, the launch provider asks for extra tests.",
		],
		"source": "preguntas_juego #6, #7, #8",
	},
	{
		"name": "LightSail", "art": "sail",
		"tag": "Propulsión", "tag_en": "Propulsion",
		"facts": [
			"Su vela solar mide 32 m² y se mueve con la radiación del Sol: no necesita combustible.",
			"LightSail-2 reunió más de 1,24 millones de dólares con crowdfunding en Kickstarter.",
			"Llevar motor puede retrasar tu lanzamiento: pone nerviosos al cohete y a su carga principal.",
		],
		"facts_en": [
			"Its solar sail is 32 m² and is pushed by the Sun's radiation: it needs no fuel.",
			"LightSail-2 raised more than 1.24 million dollars through Kickstarter crowdfunding.",
			"Carrying an engine can delay your launch: it makes the rocket and its main payload nervous.",
		],
		"source": "preguntas_juego #9, #10, #18",
	},
	{
		"name": "TVAC", "art": "thermal",
		"tag": "Térmico", "tag_en": "Thermal",
		"facts": [
			"Casi todas las misiones hacen un horneado en vacío térmico (TVAC) para que la nave suelte contaminantes antes del lanzamiento.",
			"Los cambios de temperatura en órbita pueden romper soldaduras o derretir una batería.",
			"Si la presión baja rápido, un bolsillo de aire atrapado podría reventar la estructura: por eso se hace un análisis de ventilación.",
		],
		"facts_en": [
			"Almost every mission does a thermal vacuum bake-out (TVAC) so the ship releases contaminants before launch.",
			"Temperature changes in orbit can break solder joints or melt a battery.",
			"If pressure drops fast, a trapped air pocket could burst the structure: that's why teams do a venting analysis.",
		],
		"source": "preguntas_juego #11, riesgos #13, #15",
	},
	{
		"name": "437 MHz", "art": "antenna",
		"tag": "Comunicaciones", "tag_en": "Communications",
		"facts": [
			"Muchos CubeSats transmiten balizas en la banda de 70 cm (437 MHz) que cualquier radioaficionado puede escuchar.",
			"La FCC tarda mínimo 90 días en dar una licencia experimental: hay que pedirla cuanto antes.",
			"Después del lanzamiento puede tardar semanas saber cuál objeto es tu satélite; ayudan el GPS, los TLE y los radioaficionados.",
		],
		"facts_en": [
			"Many CubeSats send beacons in the 70 cm band (437 MHz) that any radio amateur can hear.",
			"The FCC takes at least 90 days to grant an experimental license: apply as early as you can.",
			"After launch it can take weeks to know which object is your satellite; GPS, TLEs and radio amateurs help.",
		],
		"source": "preguntas_juego #13, #15, riesgos #22",
	},
	{
		"name": "Chasqui 1", "art": "twins",
		"tag": "Riesgo y redundancia", "tag_en": "Risk and redundancy",
		"facts": [
			"Chasqui 1 llegó al espacio de una forma única: un cosmonauta lo lanzó a mano durante una caminata espacial en 2014.",
			"NASA recomienda dos burn wires separados para que nada se despliegue antes de tiempo.",
			"Es más barato construir dos satélites a la vez que uno y luego otro: por eso Rayan tiene un clon.",
		],
		"facts_en": [
			"Chasqui 1 reached space in a unique way: a cosmonaut threw it by hand during a spacewalk in 2014.",
			"NASA recommends two separate burn wires so nothing deploys too early.",
			"It is cheaper to build two satellites at once than one after the other: that's why Rayan has a clone.",
		],
		"source": "preguntas_juego #4, #19, riesgos #21",
	},
]

var _font: Font
var _t: float = 0.0
var _planet: int = 0
var _leaving: bool = false


func _ready() -> void:
	add_to_group("pausable")
	_font = ThemeDB.fallback_font
	_planet = clampi(GameData.chapter - 1, 0, CARDS.size() - 1)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _t < 0.8 or _leaving:
		return
	var tapped: bool = event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
	if event.is_action_pressed("confirm") or tapped:
		_leaving = true
		get_tree().change_scene_to_file.call_deferred("res://scenes/travel.tscn")


func _draw() -> void:
	var card: Dictionary = CARDS[_planet]
	var planet: Dictionary = GameData.planets[_planet]
	var color: Color = planet.color
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.02, 0.06))
	# Blueprint grid in the planet's colour.
	for x in range(0, int(W), 20):
		draw_line(Vector2(x, 0), Vector2(x, H), Color(color, 0.05), 1.0)
	for y in range(0, int(H), 20):
		draw_line(Vector2(0, y), Vector2(W, y), Color(color, 0.05), 1.0)

	var a := clampf(_t * 2.0, 0.0, 1.0)
	draw_string(_font, Vector2(0, 40), GameData.t("¿SABÍAS QUE?", "DID YOU KNOW?"), HORIZONTAL_ALIGNMENT_CENTER, W, 22, Color(1.0, 0.9, 0.4, a))
	draw_string(_font, Vector2(0, 58), GameData.t("Lo real detrás de %s", "The real thing behind %s") % planet.name,
		HORIZONTAL_ALIGNMENT_CENTER, W, 10, Color(1, 1, 1, 0.6 * a))

	# Picture on the left.
	var art_center := Vector2(130, 170)
	draw_rect(Rect2(art_center - Vector2(90, 80), Vector2(180, 160)), Color(color, 0.08 * a))
	draw_rect(Rect2(art_center - Vector2(90, 80), Vector2(180, 160)), Color(color, 0.5 * a), false, 1.0)
	_draw_art(card.art, art_center, color, a)
	draw_string(_font, Vector2(40, 270), card.name, HORIZONTAL_ALIGNMENT_CENTER, 180, 16, Color(color.lightened(0.3), a))
	draw_string(_font, Vector2(40, 286), GameData.txt(card, "tag"), HORIZONTAL_ALIGNMENT_CENTER, 180, 9, Color(1, 1, 1, 0.6 * a))

	# Facts on the right, one after another.
	var facts: Array = GameData.txt(card, "facts")
	var y := 96.0
	for i in facts.size():
		var fa := clampf(_t * 2.0 - 0.6 - i * 0.6, 0.0, 1.0)
		draw_circle(Vector2(262, y - 4), 9.0, Color(color, fa))
		draw_string(_font, Vector2(254, y), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 16, 11, Color(0.02, 0.02, 0.06, fa))
		draw_multiline_string(_font, Vector2(282, y), facts[i], HORIZONTAL_ALIGNMENT_LEFT, W - 312, 10, -1, Color(1, 1, 1, fa))
		y += 62.0

	draw_string(_font, Vector2(0, 336), GameData.t("Fuente: datos de la NASA en Supabase (", "Source: NASA data in Supabase (") + card.source + ")",
		HORIZONTAL_ALIGNMENT_CENTER, W, 8, Color(1, 1, 1, 0.4))
	if _t > 0.8:
		var blink := 0.5 + 0.4 * sin(_t * 4.0)
		draw_string(_font, Vector2(0, 354), GameData.t("ENTER / toca para ir a la nave", "ENTER / tap to go to the ship"),
			HORIZONTAL_ALIGNMENT_RIGHT, W - 10, 9, Color(1, 1, 1, blink))


## A small CubeSat drawing for each card.
func _draw_art(art: String, c: Vector2, color: Color, a: float) -> void:
	var body := Rect2(c - Vector2(16, 16), Vector2(32, 32))
	var frame := Color(0.8, 0.82, 0.88, a)
	match art:
		"panels":
			var open := clampf(_t * 0.8, 0.0, 1.0)
			for side in [-1.0, 1.0]:
				var w := 44.0 * open
				var x: float = c.x + side * 18.0 + (0.0 if side > 0 else -w)
				draw_rect(Rect2(x, c.y - 14, w, 28), Color(0.12, 0.25, 0.62, a))
				for k in int(w / 8.0):
					draw_line(Vector2(x + k * 8.0, c.y - 14), Vector2(x + k * 8.0, c.y + 14), Color(0.5, 0.7, 1.0, 0.5 * a), 1.0)
		"sail":
			var size := 70.0 + sin(_t * 1.5) * 3.0
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -size), c + Vector2(size, 0), c + Vector2(0, size), c + Vector2(-size, 0)]),
				Color(0.85, 0.9, 1.0, 0.25 * a))
			draw_line(c + Vector2(0, -size), c + Vector2(0, size), Color(0.85, 0.9, 1.0, 0.5 * a), 1.0)
			draw_line(c + Vector2(-size, 0), c + Vector2(size, 0), Color(0.85, 0.9, 1.0, 0.5 * a), 1.0)
			# Sunlight pushing it.
			for k in 4:
				var x := fmod(_t * 40.0 + k * 22.0, 80.0)
				draw_line(Vector2(c.x - 88 + x, c.y - 60 + k * 30), Vector2(c.x - 78 + x, c.y - 60 + k * 30), Color(1.0, 0.85, 0.3, 0.6 * a), 1.0)
		"thermal":
			var heat := 0.5 + 0.5 * sin(_t * 2.0)
			draw_circle(c, 40.0, Color(Color(0.3, 0.6, 1.0).lerp(Color(1.0, 0.4, 0.2), heat), 0.25 * a))
		"antenna":
			draw_line(c + Vector2(16, -16), c + Vector2(40, -44), frame, 2.0)
			for k in 3:
				var r := fmod(_t * 30.0 + k * 14.0, 42.0)
				draw_arc(c + Vector2(40, -44), r, -PI * 0.75, PI * 0.25, 12, Color(0.4, 1.0, 0.6, (1.0 - r / 42.0) * a), 1.0)
		"twins":
			_draw_cube(Rect2(c - Vector2(46, 14), Vector2(26, 26)), color, a)
			_draw_cube(Rect2(c + Vector2(20, -12), Vector2(26, 26)), color, a)
			return
	_draw_cube(body, color, a)


func _draw_cube(body: Rect2, color: Color, a: float) -> void:
	draw_rect(body, Color(0.75, 0.77, 0.83, a))
	draw_rect(body, Color(color, a), false, 2.0)
	var inner := body.grow(-6.0)
	draw_rect(inner, Color(0.12, 0.25, 0.62, a))
	draw_line(inner.position + Vector2(inner.size.x / 2.0, 0), inner.position + Vector2(inner.size.x / 2.0, inner.size.y), Color(0.5, 0.7, 1.0, 0.6 * a), 1.0)
