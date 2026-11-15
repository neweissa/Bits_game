extends Node2D
## Ending (ideas_del_juego.md, S5). Five acts:
## 1) Return: the rebuilt ship (all five modules) reaches the sick Earth.
## 2) Restore: the friends launch real climate CubeSats from the NASA data
##    (IceCube, MinXSS, CADRE, CSSWE, BisonSat); the ugly Earth (tierra_fea)
##    slowly turns into the beautiful one (tierra_bonita).
## 3) SDGs: 13 climate, 7 clean energy, 9 innovation, 17 partnerships.
## 4) Reunion: the five friends back on Earth, with the aliens as new friends.
##    Each line waits for ENTER / tap.
## 5) Credits, page by page (slow; ENTER / tap goes to the next page), then
##    back to the lobby. The NASA Space Apps Challenge logos (assets/brand) are
##    used as the brand guide says: white/red on blue, with clear space around.
## The reunion and the credits use the same background as the start (sky and
## sea of "fondo cohete" + grass); acts 1-3 happen in space.
## Acts 1-3 move on by themselves (or with ENTER / tap).

const W := 640.0
const H := 360.0
const EARTH := Vector2(320, 175)
const EARTH_R := 70.0
const MODULE := Vector2(28, 14)
const EARTH_SICK := preload("res://assets/earth/tierra_fea.png")
const EARTH_HEALTHY := preload("res://assets/earth/tierra_bonita.png")
const BACKGROUND := preload("res://assets/backgrounds/para_ocean.png")
const GRASS := preload("res://assets/tilesets/draugr/grass.png")
const GRASS_TILES: Array[Rect2] = [
	Rect2(16, 80, 16, 16), Rect2(32, 80, 16, 16), Rect2(48, 80, 16, 16), Rect2(64, 80, 16, 16),
	Rect2(16, 96, 16, 16), Rect2(32, 96, 16, 16), Rect2(48, 96, 16, 16), Rect2(64, 96, 16, 16),
]
const GROUND_Y := 236.0
const LOGO_STACKED := preload("res://assets/brand/space_apps_logo_stacked.png")
const LOGO_HORIZONTAL := preload("res://assets/brand/space_apps_logo_horizontal.png")
## NASA Space Apps palette (brand guide).
const DEEP_BLUE := Color("07173F")
const ELECTRIC_BLUE := Color("0042A6")
const NEON_YELLOW := Color("EAFE07")
## Seconds for each typed letter in the reunion.
const TYPE_SPEED := 0.035
## Seconds a credits page stays before moving on by itself.
const CREDITS_PAGE_TIME := 12.0

## [act id, seconds]. 0 = waits for ENTER / tap.
const ACTS := [["return", 8.0], ["restore", 18.0], ["sdg", 11.0], ["reunion", 0.0], ["credits", 0.0]]

## Real climate CubeSats from the NASA data (S5): [name, Spanish, English].
const CUBESATS := [
	["IceCube", "Mide el hielo en las nubes", "Measures ice in the clouds"],
	["MinXSS", "Estudia cómo las fulguraciones del Sol afectan la atmósfera", "Studies how solar flares affect the atmosphere"],
	["CADRE", "Clima espacial", "Space weather"],
	["CSSWE", "Clima espacial", "Space weather"],
	["BisonSat", "Fotos de la Tierra", "Photos of Earth"],
]
## [number, title es, title en, text es, text en, color]
const SDGS := [
	[13, "Acción por el clima", "Climate action", "Los CubeSats vigilan el clima de la Tierra", "CubeSats watch Earth's climate", Color(0.25, 0.5, 0.25)],
	[7, "Energía asequible y no contaminante", "Affordable and clean energy", "Paneles solares, como en Yuki", "Solar panels, like on Yuki", Color(0.98, 0.76, 0.1)],
	[9, "Industria, innovación e infraestructura", "Industry, innovation and infrastructure", "Naves pequeñas, baratas y hechas por estudiantes", "Small, cheap ships built by students", Color(0.95, 0.42, 0.15)],
	[17, "Alianzas para lograr los objetivos", "Partnerships for the goals", "Cinco amigos... y unos aliens", "Five friends... and some aliens", Color(0.1, 0.3, 0.55)],
]
## [speaker, Spanish, English] in the reunion.
const LINES := [
	[0, "Andrew: Volví a encender un planeta entero. Arreglar la Tierra no puede ser más difícil.", "Andrew: I turned a whole planet back on. Fixing Earth can't be harder."],
	[1, "Bels: Después de flotar tanto, nunca pensé que extrañaría la gravedad.", "Bels: After floating so long, I never thought I'd miss gravity."],
	[2, "Ray: Fuego, hielo... y aun así lo más difícil fue esperar el horneado en vacío.", "Ray: Fire, ice... and still the hardest part was waiting for the vacuum bake-out."],
	[3, "Daenerys: Los aliens dicen \"gracias\". Bueno... dicen \"JUDFLDV\".", "Daenerys: The aliens say \"thanks\". Well... they say \"WKDQNV\"."],
	[4, "Rayan: Siempre hay que tener un respaldo. Por eso éramos cinco.", "Rayan: Always have a backup. That's why there were five of us."],
]
const TEAM := ["Cardona Isabela", "Estrada Jeissa", "Ovalle Andrés", "Romero Santiago", "Suárez Edwin"]
## [role es, role en, names]
const ROLES := [
	["Líderes en experiencia de usuario, interfaz y diseñadores de personajes",
		"User experience and interface leads, character designers", "Cardona Isabela  ·  Ovalle Andrés"],
	["Líderes de grupo, creadores de base de datos y desarrolladores de videojuego",
		"Team leads, database creators and game developers", "Estrada Jeissa  ·  Suárez Edwin"],
	["Desarrollador de backend y enlaces de datos",
		"Backend and data integration developer", "Romero Santiago"],
]

var _font: Font
var _t: float = 0.0
var _act: int = 0
var _act_t: float = 0.0
var _stars: Array[Vector3] = []
## Reunion: current line and seconds since it started typing.
var _line: int = 0
var _line_t: float = 0.0
## Credits: current page and seconds on it.
var _page: int = 0
var _page_t: float = 0.0
var _leaving: bool = false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_font = ThemeDB.fallback_font
	var rng := RandomNumberGenerator.new()
	rng.seed = 2027
	for i in 160:
		_stars.append(Vector3(rng.randf() * W, rng.randf() * H, 1.0 if rng.randf() < 0.8 else 2.0))


func _process(delta: float) -> void:
	_t += delta
	_act_t += delta
	_line_t += delta
	_page_t += delta
	var length: float = ACTS[_act][1]
	if length > 0.0 and _act_t >= length:
		_next_act()
	if ACTS[_act][0] == "credits" and _page_t >= CREDITS_PAGE_TIME:
		_next_page()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var tapped: bool = event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
	if not (event.is_action_pressed("confirm") or tapped) or _act_t < 0.6:
		return
	match ACTS[_act][0]:
		"reunion":
			if _typed() < 1.0:
				_line_t = 999.0  # Show the whole line first.
			elif _line < LINES.size() - 1:
				_line += 1
				_line_t = 0.0
			else:
				_next_act()
		"credits":
			if _page_t > 0.5:
				_next_page()
		_:
			_next_act()


func _next_act() -> void:
	if _act >= ACTS.size() - 1:
		_back_to_lobby()
		return
	_act += 1
	_act_t = 0.0
	_line = 0
	_line_t = 0.0
	_page = 0
	_page_t = 0.0


func _next_page() -> void:
	if _page >= _pages().size() - 1:
		_back_to_lobby()
		return
	_page += 1
	_page_t = 0.0


func _back_to_lobby() -> void:
	if _leaving:
		return
	_leaving = true
	GameData.chapter = 0
	get_tree().change_scene_to_file.call_deferred("res://scenes/lobby.tscn")


## 0..1 progress of the current act (timed acts only).
func _p() -> float:
	var length: float = ACTS[_act][1]
	return clampf(_act_t / length, 0.0, 1.0) if length > 0.0 else 1.0


## 0..1 how much of the current reunion line is typed.
func _typed() -> float:
	var text := _line_text(_line)
	return clampf(_line_t / (TYPE_SPEED * text.length()), 0.0, 1.0)


func _line_text(i: int) -> String:
	return LINES[i][2 if GameData.lang == "en" else 1]


# --- drawing --------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.02, 0.06))
	for star in _stars:
		draw_rect(Rect2(star.x, star.y, star.z, star.z), Color(1, 1, 1, 0.3 + 0.2 * star.z * (0.6 + 0.4 * sin(_t * 2.0 + star.x))))
	match ACTS[_act][0]:
		"return":
			_draw_return()
		"restore":
			_draw_restore()
		"sdg":
			_draw_sdg()
		"reunion":
			_draw_reunion()
		"credits":
			_draw_credits()
	var hint := GameData.t("ENTER / toca para seguir", "ENTER / tap to continue")
	draw_string(_font, Vector2(0, 354), hint, HORIZONTAL_ALIGNMENT_RIGHT, W - 8, 8, Color(1, 1, 1, 0.4))
	# Fade in at the start of each act.
	var fade := 1.0 - clampf(_act_t / 0.8, 0.0, 1.0)
	if fade > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, fade))


func _text(value: String, y: float, size: int, color: Color) -> void:
	draw_string(_font, Vector2(0, y), value, HORIZONTAL_ALIGNMENT_CENTER, W, size, color)


func _draw_return() -> void:
	var p := _p()
	_draw_earth(EARTH, EARTH_R, 0.0)
	# The rebuilt ship, all five modules, comes in from the bottom.
	var base := Vector2(EARTH.x + 150.0, lerpf(H + 90.0, 300.0, _ease(minf(p * 1.6, 1.0))))
	_draw_ship(base)
	var a := clampf((p - 0.2) * 3.0, 0.0, 1.0)
	_text(GameData.t("De vuelta en casa", "Back home"), 40, 20, Color(1, 1, 1, a))
	_text(GameData.t("Pero la Tierra que dejaron tiene problemas: el clima está fuera de control.",
		"But the Earth they left is in trouble: the climate is out of control."), 62, 10, Color(0.9, 0.8, 0.7, a))
	_text(GameData.t("La nave reconstruida trae cinco módulos... y una idea.", "The rebuilt ship carries five modules... and an idea."),
		330, 10, Color(0.8, 0.9, 1.0, clampf((p - 0.55) * 3.0, 0.0, 1.0)))


func _draw_restore() -> void:
	var p := _p()
	var per := 1.0 / CUBESATS.size()
	var launched := clampi(int(p / per) + 1, 1, CUBESATS.size())
	var heal := clampf(p * 1.15, 0.0, 1.0)
	_draw_earth(EARTH, EARTH_R, heal)
	# Each CubeSat leaves the ship and settles on its own orbit.
	var ship := Vector2(EARTH.x + 150.0, 300.0)
	_draw_ship(ship)
	for i in launched:
		var k := _ease(clampf((p - i * per) / (per * 0.6), 0.0, 1.0))
		var radius := EARTH_R + 18.0 + i * 11.0
		var angle := _t * (0.6 - i * 0.07) + i * 1.3
		var orbit := EARTH + Vector2.from_angle(angle) * radius
		var pos := ship.lerp(orbit, k)
		if k >= 1.0:
			draw_arc(EARTH, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.08), 1.0)
		_draw_cubesat(pos, GameData.characters[i].color)
	var current: Array = CUBESATS[launched - 1]
	_text(GameData.t("Lanzando CubeSats de clima reales", "Launching real climate CubeSats"), 34, 16, Color.WHITE)
	_text("%d/%d  %s" % [launched, CUBESATS.size(), current[0]], 300, 16, GameData.characters[launched - 1].color.lightened(0.2))
	_text(current[2 if GameData.lang == "en" else 1], 320, 10, Color(1, 1, 1, 0.8))
	# Healing bar.
	var bar := Rect2(170, 48, 300, 6)
	draw_rect(bar, Color(0.2, 0.1, 0.1))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * heal, bar.size.y)), Color(0.9, 0.3, 0.2).lerp(Color(0.3, 0.9, 0.5), heal))
	draw_string(_font, bar.position + Vector2(0, 18), GameData.t("Salud del planeta %d%%", "Planet health %d%%") % int(heal * 100.0),
		HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 8, Color(1, 1, 1, 0.6))


func _draw_sdg() -> void:
	var p := _p()
	_draw_earth(Vector2(W / 2.0, 330.0), 120.0, 1.0)
	_text(GameData.t("Objetivos de Desarrollo Sostenible", "Sustainable Development Goals"), 36, 16, Color.WHITE)
	var en := GameData.lang == "en"
	for i in SDGS.size():
		var a := clampf(p * 5.0 - i * 0.8, 0.0, 1.0)
		var sdg: Array = SDGS[i]
		var box := Rect2(28 + i * 150, 60, 134, 120)
		draw_rect(box, Color(sdg[5], 0.92 * a))
		draw_rect(box, Color(1, 1, 1, 0.6 * a), false, 1.0)
		draw_string(_font, box.position + Vector2(10, 34), GameData.t("ODS %d", "SDG %d") % sdg[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, a))
		draw_multiline_string(_font, box.position + Vector2(10, 56), sdg[2 if en else 1], HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 20, 10, -1, Color(1, 1, 1, a))
		draw_multiline_string(_font, box.position + Vector2(10, 92), sdg[4 if en else 3], HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 20, 8, -1, Color(1, 1, 1, 0.85 * a))


## Same place as the start: sky and sea of "fondo cohete" and the grass field.
func _draw_start_background() -> void:
	draw_texture_rect(BACKGROUND, Rect2(-8, -52, W + 16, H + 16), false)
	var x := -16.0
	var col := 0
	while x < W + 16.0:
		var y := GROUND_Y
		var row := 0
		while y < H + 8.0:
			var region: Rect2 = GRASS_TILES[absi(col * 7 + row * 13 + (col * row) % 5) % GRASS_TILES.size()]
			draw_texture_rect_region(GRASS, Rect2(x, y, 16, 16), region)
			y += 16.0
			row += 1
		x += 16.0
		col += 1
	draw_rect(Rect2(-8, GROUND_Y - 1, W + 16, 3), Color(0.2, 0.42, 0.22))


func _draw_reunion() -> void:
	# Back at the launch site of the intro (they are standing on the healed Earth).
	_draw_start_background()
	draw_rect(Rect2(504, 126, 6, 110), Color(0.45, 0.45, 0.5))
	_draw_ship(Vector2(480, 236))
	# The five friends, together again.
	var speaker: int = LINES[_line][0]
	for i in 5:
		var talking := i == speaker and _typed() < 1.0
		var bob := absf(sin(_t * 8.0)) * 3.0 if talking else absf(sin(_t * 2.0 + i)) * 1.0
		var feet := Vector2(120 + i * 52, 236 - bob)
		if not CharacterSprites.draw(self, i, feet, 28.0, CharacterSprites.ROW_DOWN, 0):
			draw_rect(Rect2(feet - Vector2(7, 28), Vector2(14, 28)), GameData.characters[i].color)
	# Aliens from Draugr and a ghost from Control C, friends now.
	for a in 2:
		var pos := Vector2(390 + a * 30, 228 - absf(sin(_t * 4.0 + a)) * 4.0)
		draw_circle(pos, 7.0, Color(0.35, 0.8, 0.7) if a == 0 else Color(0.82, 0.9, 1.0))
		draw_rect(Rect2(pos + Vector2(-4, -3), Vector2(3, 3)), Color.BLACK)
		draw_rect(Rect2(pos + Vector2(1, -3), Vector2(3, 3)), Color.BLACK)
		draw_line(pos + Vector2(0, -7), pos + Vector2(0, -13), Color(1, 1, 0.4), 1.0)
	var head := Vector2(120 + speaker * 52, 200)
	draw_colored_polygon(PackedVector2Array([head + Vector2(-4, -5), head + Vector2(4, -5), head]), Color.WHITE)
	var box := Rect2(12, 258, W - 24, 70)
	draw_rect(box, Color(0.04, 0.04, 0.1, 0.92))
	draw_rect(box, Color(1, 1, 1, 0.8), false, 1.0)
	var text := _line_text(_line)
	var shown := text.substr(0, int(text.length() * _typed()))
	draw_multiline_string(_font, Vector2(24, 282), shown, HORIZONTAL_ALIGNMENT_LEFT, W - 48, 11, -1, GameData.characters[speaker].color.lightened(0.5))
	draw_string(_font, box.position + Vector2(0, box.size.y - 6), "%d/%d" % [_line + 1, LINES.size()], HORIZONTAL_ALIGNMENT_RIGHT, box.size.x - 10, 8, Color(1, 1, 1, 0.4))
	_text(GameData.t("Cinco amigos. Cinco planetas. Un solo equipo.", "Five friends. Five planets. One team."), 40, 16, Color(1, 1, 1, clampf(_act_t, 0.0, 1.0)))


# --- credits ------------------------------------------------------------------

## Each page: [[text, size, color], ...]. Built each time so it follows the language.
func _pages() -> Array:
	# A page can also be [["@logo", ...]] for a Space Apps logo page.
	var gold := Color(1.0, 0.85, 0.45)
	var soft := Color(1, 1, 1, 0.8)
	var pages := []
	pages.append([
		["BIG HERO HACKATHON 2026", 22, Color.WHITE],
		[GameData.t("Cinco amigos. Cinco planetas. Un solo equipo.", "Five friends. Five planets. One team."), 11, soft],
		["@logo_horizontal", 0, Color.WHITE],
	])
	var team := [[GameData.t("CREADORES", "CREATORS"), 16, gold]]
	for member in TEAM:
		team.append([member, 13, Color.WHITE])
	pages.append(team)
	var roles := [[GameData.t("ROLES EN EL EQUIPO", "TEAM ROLES"), 16, gold]]
	for role in ROLES:
		roles.append([role[1] if GameData.lang == "en" else role[0], 9, Color(0.6, 0.9, 1.0)])
		roles.append([role[2], 13, Color.WHITE])
	pages.append(roles)
	var cast := [[GameData.t("PERSONAJES", "CHARACTERS"), 16, gold]]
	for c in GameData.characters:
		var color: Color = c.color
		cast.append(["%s  -  %s (%s)" % [c.name, GameData.txt(c, "power"), GameData.txt(c, "discipline")], 10, color.lightened(0.3)])
	pages.append(cast)
	pages.append([
		[GameData.t("DATOS Y RECURSOS", "DATA AND ASSETS"), 16, gold],
		[GameData.t("Datos de CubeSats, riesgos y trivia: NASA, vía nuestra base de datos en Supabase",
			"CubeSat data, risks and trivia: NASA, through our Supabase database"), 9, soft],
		[GameData.t("Personajes: generador LPC (Liberated Pixel Cup)", "Characters: LPC generator (Liberated Pixel Cup)"), 9, soft],
		["Yuki: Neo Zero tileset   ·   Zero: Ditharts Free Sci-fi Tileset", 9, soft],
		[GameData.t("Fernix: Top Down Lava Tileset (BeyonderBoy) y mundo de nieve", "Fernix: Top Down Lava Tileset (BeyonderBoy) and snow world"), 9, soft],
		["Draugr: Sprout Lands (Cup Nooble)   ·   Control C: Laboratory Tileset (ExceptRea)", 9, soft],
		[GameData.t("Música: DavidKBD - My Little Bots Pack", "Music: DavidKBD - My Little Bots Pack"), 9, soft],
		[GameData.t("Motor: Godot Engine", "Engine: Godot Engine"), 9, soft],
	])
	pages.append([["@logo_stacked", 0, Color.WHITE]])
	pages.append([
		[GameData.t("Gracias por jugar", "Thanks for playing"), 16, Color.WHITE],
		[GameData.t("FIN", "THE END"), 26, gold],
	])
	return pages


func _draw_credits() -> void:
	# Start background, darkened with the Space Apps deep blue so text reads well.
	_draw_start_background()
	draw_rect(Rect2(0, 0, W, H), Color(DEEP_BLUE, 0.82))
	_draw_orbit_pattern()
	var pages := _pages()
	var page: Array = pages[_page]
	# The page fades in, drifts up very slowly and fades out at the end.
	var a := clampf(_page_t / 1.2, 0.0, 1.0) * clampf((CREDITS_PAGE_TIME - _page_t) / 1.0, 0.0, 1.0)
	if page[0][0] == "@logo_stacked":
		_draw_space_apps_page(a)
	else:
		var height := 0.0
		for entry in page:
			height += _entry_height(entry)
		var y := (H - height) / 2.0 + 18.0 - _page_t * 1.5
		for entry in page:
			if entry[0] == "@logo_horizontal":
				# Default (horizontal) logo, with clear space around it.
				var size := LOGO_HORIZONTAL.get_size() * 0.36
				draw_texture_rect(LOGO_HORIZONTAL, Rect2(Vector2((W - size.x) / 2.0, y + 6.0), size), false, Color(1, 1, 1, a))
			else:
				var color: Color = entry[2]
				_text(entry[0], y, entry[1], Color(color, color.a * a))
			y += _entry_height(entry)
	# Dots: which page this is.
	for i in pages.size():
		draw_circle(Vector2(W / 2.0 + (i - (pages.size() - 1) / 2.0) * 12.0, 336), 2.5, Color(1, 1, 1, 0.8 if i == _page else 0.25))
	if _page == pages.size() - 1:
		_text(GameData.t("ENTER / toca para volver al inicio", "ENTER / tap to go back to the start"), 322, 9, Color(1, 1, 1, 0.5 * a))


func _entry_height(entry: Array) -> float:
	if entry[0] == "@logo_horizontal":
		return LOGO_HORIZONTAL.get_size().y * 0.36 + 24.0
	return entry[1] + 14.0


## The stacked NASA Space Apps Challenge logo on its own page (1U clear space:
## nothing else inside the square around it), with a short line below.
func _draw_space_apps_page(a: float) -> void:
	var size := LOGO_STACKED.get_size() * 0.62
	var pos := Vector2((W - size.x) / 2.0, 40.0)
	draw_texture_rect(LOGO_STACKED, Rect2(pos, size), false, Color(1, 1, 1, a))
	var y := pos.y + size.y + 46.0
	_text(GameData.t("Un juego hecho para el reto de NASA Space Apps Challenge", "A game made for the NASA Space Apps Challenge"), y, 11, Color(1, 1, 1, a))
	# Neon Yellow only as a small accent (the guide's 60-30-10 rule).
	draw_rect(Rect2(W / 2.0 - 30.0, y + 8.0, 60.0, 2.0), Color(NEON_YELLOW, a))


## Brand pattern: orbit lines and coordinate crosses at about 25% opacity.
func _draw_orbit_pattern() -> void:
	var line := Color(ELECTRIC_BLUE.lightened(0.5), 0.25)
	draw_arc(Vector2(-60, -40), 230.0, 0.0, TAU, 96, line, 1.0)
	draw_arc(Vector2(-60, -40), 300.0, 0.0, TAU, 96, line, 1.0)
	draw_arc(Vector2(W + 80, H + 60), 260.0, 0.0, TAU, 96, line, 1.0)
	for p in [Vector2(560, 60), Vector2(600, 150), Vector2(70, 300), Vector2(120, 250), Vector2(520, 110)]:
		draw_line(p - Vector2(5, 0), p + Vector2(5, 0), line, 1.0)
		draw_line(p - Vector2(0, 5), p + Vector2(0, 5), line, 1.0)


# --- helpers ----------------------------------------------------------------

## Earth: the ugly sprite (tierra_fea) at heal 0 turns into the beautiful one
## (tierra_bonita) at heal 1, with smog that clears and a glow that turns blue.
func _draw_earth(pos: Vector2, radius: float, heal: float) -> void:
	var rect := Rect2(pos - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	var glow := Color(0.85, 0.5, 0.3).lerp(Color(0.45, 0.75, 1.0), heal)
	draw_circle(pos, radius + 5.0, Color(glow, 0.22))
	if heal < 1.0:
		draw_texture_rect(EARTH_SICK, rect, false)
	if heal > 0.0:
		draw_texture_rect(EARTH_HEALTHY, rect, false, Color(1, 1, 1, heal))
	# Smog that clears as the planet heals.
	if heal < 1.0:
		for i in 6:
			var a := _t * 0.3 + i
			draw_circle(pos + Vector2.from_angle(a) * radius * 0.5, radius * 0.3, Color(0.45, 0.38, 0.32, 0.22 * (1.0 - heal)))


func _draw_ship(base: Vector2) -> void:
	var half := MODULE.x / 2.0
	draw_colored_polygon(PackedVector2Array([base + Vector2(-half, -18), base + Vector2(-half, 0), base + Vector2(-half - 10, 0)]), Color(0.7, 0.2, 0.2))
	draw_colored_polygon(PackedVector2Array([base + Vector2(half, -18), base + Vector2(half, 0), base + Vector2(half + 10, 0)]), Color(0.7, 0.2, 0.2))
	for i in 5:
		var center := Vector2(base.x, base.y - (i + 0.5) * MODULE.y)
		draw_rect(Rect2(center - MODULE / 2.0, MODULE), GameData.characters[i].color)
		draw_rect(Rect2(center - MODULE / 2.0, MODULE), Color(1, 1, 1, 0.9), false, 1.0)
	var top := base.y - 5.0 * MODULE.y
	draw_colored_polygon(PackedVector2Array([Vector2(base.x - half, top), Vector2(base.x + half, top), Vector2(base.x, top - 22)]), Color(0.85, 0.85, 0.9))


func _draw_cubesat(pos: Vector2, color: Color) -> void:
	draw_rect(Rect2(pos - Vector2(3, 3), Vector2(6, 6)), Color(0.85, 0.85, 0.9))
	draw_rect(Rect2(pos - Vector2(3, 3), Vector2(6, 6)), color, false, 1.0)
	draw_rect(Rect2(pos + Vector2(-11, -1.5), Vector2(7, 3)), Color(0.2, 0.35, 0.8))
	draw_rect(Rect2(pos + Vector2(4, -1.5), Vector2(7, 3)), Color(0.2, 0.35, 0.8))


func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)
