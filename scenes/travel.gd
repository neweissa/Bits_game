extends Node2D
## Ship engineering + trip between planets (ideas_del_juego.md, S3).
## GameData.chapter is the DESTINATION (1..4 = next planet, 5 = back to Earth).
## 1) Engineering: three quick steps on the ship (ENTER / tap each one). The
##    friend just rescued docks their module, so the ship grows every trip.
## 2) Trip: the ship flies along that leg's orbit while its hull, trail and the
##    space around it shift to the destination planet's colour.
## Then the chapter card of the next planet (or the ending) is shown.

const W := 640.0
const H := 360.0
const MODULE := Vector2(28, 14)
const SHIP_X := 220.0
const SHIP_BASE_Y := 250.0
const TRIP_TIME := 5.0
const STEP_TIME := 0.7
const EARTH_COLOR := Color(0.85, 0.5, 0.25)
const EARTH_SICK := preload("res://assets/earth/tierra_fea.png")

## One entry per destination 1..5: [orbit (S3), three engineering steps].
## Each step: [text, part drawn on the ship].
const LEGS := [
	["Órbita geoestacionaria (GEO)", [["Acoplar el módulo de Andrew", "module"], ["Desplegar paneles solares", "panels"], ["Poner inhibidores en los perros", "inhibitor"]]],
	["Órbita lunar", [["Acoplar el módulo de Bels", "module"], ["Abrir la vela solar", "sail"], ["Activar los giroscopios", "gyro"]]],
	["Órbita de libración", [["Acoplar el módulo de Ray", "module"], ["Ventilar el aire atrapado", "vent"], ["Blindaje de aluminio", "shield"]]],
	["Espacio profundo", [["Acoplar el módulo de Daenerys", "module"], ["Antena en 437 MHz", "antenna"], ["Calibrar la antena con el Sol", "sun"]]],
	["Salida de órbita controlada", [["Acoplar el módulo de Rayan", "module"], ["Instalar el segundo burn wire", "wire"], ["Quitar el pin \"Remove Before Flight\"", "pin"]]],
]
## English texts of LEGS: [orbit, [step 1, step 2, step 3]].
const LEGS_EN := [
	["Geostationary orbit (GEO)", ["Dock Andrew's module", "Deploy the solar panels", "Add inhibitors to the dogs"]],
	["Lunar orbit", ["Dock Bels's module", "Open the solar sail", "Turn on the gyroscopes"]],
	["Libration orbit", ["Dock Ray's module", "Vent the trapped air", "Aluminum shielding"]],
	["Deep space", ["Dock Daenerys's module", "Antenna at 437 MHz", "Calibrate the antenna with the Sun"]],
	["Controlled deorbit", ["Dock Rayan's module", "Install the second burn wire", "Pull the \"Remove Before Flight\" pin"]],
]

var _font: Font
var _t: float = 0.0
var _dest: int = 1
var _step: int = 0
var _step_t: float = 99.0
var _trip_t: float = -1.0
var _stars: Array[Vector3] = []
var _leaving: bool = false


func _ready() -> void:
	add_to_group("pausable")
	_font = ThemeDB.fallback_font
	_dest = clampi(GameData.chapter, 1, LEGS.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 + _dest
	for i in 120:
		_stars.append(Vector3(rng.randf() * W, rng.randf() * H, 1.0 if rng.randf() < 0.8 else 2.0))


func _process(delta: float) -> void:
	_t += delta
	_step_t += delta
	if _trip_t >= 0.0:
		_trip_t += delta
		if _trip_t >= TRIP_TIME:
			_arrive()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var tapped: bool = event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
	if not (event.is_action_pressed("confirm") or tapped):
		return
	if _trip_t >= 0.0:
		if _trip_t > 1.0:
			_arrive()  # Skip the rest of the trip.
		return
	if _step_t < STEP_TIME:
		return  # Let the current part finish.
	_step += 1
	_step_t = 0.0
	if _step >= 3:
		_trip_t = 0.0


func _leg_name() -> String:
	return LEGS_EN[_dest - 1][0] if GameData.lang == "en" else LEGS[_dest - 1][0]


func _step_text(i: int) -> String:
	return LEGS_EN[_dest - 1][1][i] if GameData.lang == "en" else LEGS[_dest - 1][1][i][0]


func _dest_name() -> String:
	return GameData.t("la Tierra", "Earth") if _dest >= LEGS.size() else GameData.planets[_dest].name


func _arrive() -> void:
	if _leaving:
		return
	_leaving = true
	var next := "res://scenes/ending.tscn" if _dest >= LEGS.size() else "res://scenes/chapter.tscn"
	get_tree().change_scene_to_file.call_deferred(next)


# --- colours ------------------------------------------------------------------

func _origin_color() -> Color:
	return GameData.planets[_dest - 1].color


func _dest_color() -> Color:
	return EARTH_COLOR if _dest >= LEGS.size() else GameData.planets[_dest].color


## 0 while docked, then 0..1 during the trip.
func _trip_k() -> float:
	return clampf(_trip_t / (TRIP_TIME * 0.7), 0.0, 1.0) if _trip_t >= 0.0 else 0.0


func _ship_color() -> Color:
	return _origin_color().lerp(_dest_color(), _ease(_trip_k()))


# --- drawing --------------------------------------------------------------------

func _draw() -> void:
	var tint := _ship_color()
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.02, 0.06).lerp(tint.darkened(0.85), 0.6))
	var speed := 0.0 if _trip_t < 0.0 else 40.0 + 260.0 * _ease(clampf(_trip_t / 1.5, 0.0, 1.0))
	for star in _stars:
		var y := fmod(star.y + _t * 6.0 + maxf(_trip_t, 0.0) * speed * star.z * 0.5, H)
		var length := 1.0 + speed * 0.02 * star.z
		draw_rect(Rect2(star.x, y, star.z, length), Color(tint.lightened(0.6), 0.3 + 0.25 * star.z))

	if _trip_t < 0.0:
		_draw_blueprint(tint)
		_draw_origin_planet()
	else:
		_draw_destination()

	var ship_y := SHIP_BASE_Y
	if _trip_t >= 0.0:
		ship_y = 232.0 - sin(_t * 3.0) * 2.0
	_draw_ship(Vector2(SHIP_X if _trip_t < 0.0 else W / 2.0, ship_y), tint)

	if _trip_t < 0.0:
		_draw_checklist(tint)
	else:
		_draw_trip_text(tint)
	draw_rect(Rect2(0, 0, W, H), tint, false, 2.0)


func _draw_blueprint(tint: Color) -> void:
	var grid := Color(tint, 0.08)
	for x in range(0, int(W / 2.0), 16):
		draw_line(Vector2(x, 40), Vector2(x, H - 20), grid, 1.0)
	for y in range(40, int(H) - 20, 16):
		draw_line(Vector2(0, y), Vector2(W / 2.0 - 16, y), grid, 1.0)
	draw_string(_font, Vector2(16, 30), GameData.t("INGENIERÍA DE NAVE", "SHIP ENGINEERING"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, tint.lightened(0.3))


func _draw_origin_planet() -> void:
	var i := _dest - 1
	var tex := GameData.planet_texture(i)
	var pos := Vector2(80, 300)
	if tex != null:
		draw_texture_rect(tex, GameData.planet_rect(i, pos, 46.0), false)
	draw_string(_font, Vector2(20, 352), GameData.t("Saliendo de ", "Leaving ") + GameData.planets[i].name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.6))


func _draw_destination() -> void:
	# The destination grows in the distance as the ship gets there.
	var k := _ease(clampf(_trip_t / TRIP_TIME, 0.0, 1.0))
	var radius := lerpf(6.0, 46.0, k)
	var pos := Vector2(W / 2.0 + 150.0, lerpf(40.0, 80.0, k))
	if _dest >= LEGS.size():
		# The sick Earth they are coming back to (it heals in the ending).
		draw_texture_rect(EARTH_SICK, Rect2(pos - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false)
	else:
		var tex := GameData.planet_texture(_dest)
		if tex != null:
			draw_texture_rect(tex, GameData.planet_rect(_dest, pos, radius), false)


func _draw_trip_text(tint: Color) -> void:
	var alpha := clampf(_trip_t * 2.0, 0.0, 1.0)
	draw_string(_font, Vector2(0, 306), GameData.t("Rumbo a ", "Heading to ") + _dest_name(), HORIZONTAL_ALIGNMENT_CENTER, W, 18, Color(tint.lightened(0.4), alpha))
	draw_string(_font, Vector2(0, 324), GameData.t("Tramo: ", "Leg: ") + _leg_name(), HORIZONTAL_ALIGNMENT_CENTER, W, 11, Color(1, 1, 1, 0.7 * alpha))
	var crew := []
	for i in _modules():
		crew.append(GameData.characters[i].name)
	draw_string(_font, Vector2(0, 340), GameData.t("A bordo: ", "On board: ") + ", ".join(crew), HORIZONTAL_ALIGNMENT_CENTER, W, 9, Color(1, 1, 1, 0.5 * alpha))
	if _trip_t > 1.0:
		draw_string(_font, Vector2(0, 354), GameData.t("ENTER / toca para llegar", "ENTER / tap to arrive"), HORIZONTAL_ALIGNMENT_RIGHT, W - 8, 8, Color(1, 1, 1, 0.35))


func _draw_checklist(tint: Color) -> void:
	var leg: Array = LEGS[_dest - 1]
	var panel := Rect2(W / 2.0 + 8, 40, W / 2.0 - 24, 230)
	draw_rect(panel, Color(0.03, 0.04, 0.08, 0.9))
	draw_rect(panel, Color(tint, 0.8), false, 1.0)
	draw_string(_font, panel.position + Vector2(12, 20), GameData.t("Próximo destino: ", "Next stop: ") + _dest_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, _dest_color().lightened(0.2))
	draw_string(_font, panel.position + Vector2(12, 36), GameData.t("Tramo: ", "Leg: ") + _leg_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.6))
	var steps: Array = leg[1]
	for i in steps.size():
		var y := panel.position.y + 70 + i * 40
		var done := i < _step
		var current := i == _step
		var box := Rect2(panel.position.x + 12, y - 11, 14, 14)
		draw_rect(box, Color(0.5, 1.0, 0.6) if done else Color(0.1, 0.12, 0.2))
		draw_rect(box, Color(1, 1, 1, 0.9 if current else 0.4), false, 1.0)
		if done:
			draw_polyline(PackedVector2Array([box.position + Vector2(3, 7), box.position + Vector2(6, 11), box.position + Vector2(11, 3)]), Color(0.05, 0.2, 0.08), 2.0)
		var color := Color.WHITE if current else Color(1, 1, 1, 0.75 if done else 0.4)
		draw_string(_font, Vector2(box.end.x + 8, y), _step_text(i), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 50, 10, color)
	var blink := 0.5 + 0.4 * sin(_t * 5.0)
	var prompt: String = GameData.t("ENTER / toca: ", "ENTER / tap: ") + _step_text(_step) if _step < steps.size() else GameData.t("Lista para despegar", "Ready for liftoff")
	draw_string(_font, Vector2(panel.position.x, panel.end.y + 22), prompt, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 10, Color(1.0, 0.9, 0.5, blink))


# --- ship -----------------------------------------------------------------------

## Module indexes on board: everyone rescued so far (+ the one docking now).
func _modules() -> Array:
	var count := _dest - 1
	if _step > 0 or _trip_t >= 0.0:
		count += 1
	var list := []
	for i in count:
		list.append(i)
	return list


func _part_done(part: String) -> float:
	## 0..1 how far that part is installed (steps of earlier legs count as done).
	var installed := 0.0
	for leg_i in _dest:
		var steps: Array = LEGS[leg_i][1]
		for s in steps.size():
			if steps[s][1] != part:
				continue
			if leg_i < _dest - 1 or s < _step - 1 or _trip_t >= 0.0:
				installed = 1.0
			elif s == _step - 1:
				installed = maxf(installed, clampf(_step_t / STEP_TIME, 0.0, 1.0))
	return installed


func _draw_ship(base: Vector2, tint: Color) -> void:
	var modules := _modules()
	var hull := tint.lerp(Color(0.85, 0.85, 0.9), 0.35)
	# Engine flame and coloured trail during the trip.
	if _trip_t >= 0.0:
		var length := 18.0 + absf(sin(_t * 40.0)) * 10.0 + 20.0 * _ease(clampf(_trip_t, 0.0, 1.0))
		for i in 5:
			var trail_y := base.y + 10.0 + i * 11.0
			draw_circle(Vector2(base.x, trail_y), 6.0 - i * 0.8, Color(tint.lightened(0.3), 0.35 - i * 0.05))
		draw_colored_polygon(PackedVector2Array([base + Vector2(-9, 0), base + Vector2(9, 0), base + Vector2(0, length)]), Color(1.0, 0.5, 0.15))
		draw_colored_polygon(PackedVector2Array([base + Vector2(-5, 0), base + Vector2(5, 0), base + Vector2(0, length * 0.6)]), Color(1.0, 0.9, 0.4))
	# Fins.
	var half := MODULE.x / 2.0
	draw_colored_polygon(PackedVector2Array([base + Vector2(-half, -18), base + Vector2(-half, 0), base + Vector2(-half - 10, 0)]), hull.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([base + Vector2(half, -18), base + Vector2(half, 0), base + Vector2(half + 10, 0)]), hull.darkened(0.3))

	# Modules, the newest one sliding in from the left while it docks.
	var top := base.y
	for n in modules.size():
		var i: int = modules[n]
		var center := Vector2(base.x, base.y - (n + 0.5) * MODULE.y)
		if n == modules.size() - 1 and n == _dest - 1 and _trip_t < 0.0:
			var k := _ease(clampf(_step_t / STEP_TIME, 0.0, 1.0)) if _step == 1 else 1.0
			center.x = lerpf(base.x - 160.0, base.x, k)
		var color: Color = GameData.characters[i].color
		draw_rect(Rect2(center - MODULE / 2.0, MODULE), color)
		draw_rect(Rect2(center - MODULE / 2.0, MODULE), Color(hull, 0.9), false, 1.0)
		draw_rect(Rect2(center - Vector2(3, 3), Vector2(6, 6)), Color(0.1, 0.15, 0.25))
		top = base.y - (n + 1) * MODULE.y
	if modules.is_empty():
		top = base.y - MODULE.y
		draw_rect(Rect2(Vector2(base.x - half, top), MODULE), Color(hull, 0.25), false, 1.0)
	# Nose.
	draw_colored_polygon(PackedVector2Array([Vector2(base.x - half, top), Vector2(base.x + half, top), Vector2(base.x, top - 22)]), hull)

	_draw_parts(base, top, tint)


func _draw_parts(base: Vector2, top: float, tint: Color) -> void:
	var half := MODULE.x / 2.0
	var mid := Vector2(base.x, (base.y + top) / 2.0)
	var k := _part_done("panels")
	if k > 0.0:
		for side in [-1.0, 1.0]:
			var w := 34.0 * k
			var x: float = base.x + side * (half + 2.0) + (0.0 if side > 0 else -w)
			draw_rect(Rect2(x, mid.y - 6, w, 12), Color(0.2, 0.35, 0.8))
			for c in int(w / 6.0):
				draw_line(Vector2(x + c * 6.0, mid.y - 6), Vector2(x + c * 6.0, mid.y + 6), Color(0.6, 0.8, 1.0, 0.6), 1.0)
	k = _part_done("sail")
	if k > 0.0:
		var size := 60.0 * k
		var c := Vector2(base.x, top - 50)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -size / 2), c + Vector2(size / 2, 0), c + Vector2(0, size / 2), c + Vector2(-size / 2, 0)]), Color(0.85, 0.9, 1.0, 0.35))
		draw_line(Vector2(base.x, top - 22), c, Color(0.85, 0.9, 1.0, 0.6), 1.0)
	k = _part_done("antenna")
	if k > 0.0:
		var tip := Vector2(base.x + half + 4, top + 4) + Vector2(18, -18) * k
		draw_line(Vector2(base.x + half, top + 6), tip, Color(0.9, 0.9, 0.95), 1.0)
		draw_arc(tip, 5.0, PI * 0.8, PI * 1.8, 8, Color(0.9, 0.9, 0.95), 1.0)
	k = _part_done("shield")
	if k > 0.0:
		draw_rect(Rect2(base.x - half - 3, top - 2, MODULE.x + 6, base.y - top + 4), Color(0.75, 0.78, 0.82, 0.8 * k), false, 2.0)
	k = _part_done("gyro")
	if k > 0.0:
		draw_arc(mid, 20.0, _t * 3.0, _t * 3.0 + PI * 1.2 * k, 16, Color(tint.lightened(0.5), 0.8), 1.0)
	k = _part_done("inhibitor")
	if k > 0.0:
		draw_rect(Rect2(base.x - 4, base.y - 6, 8, 4), Color(1.0, 0.85, 0.2, k))
	k = _part_done("vent")
	if k > 0.0 and _trip_t < 0.0 and _step <= 3:
		for p in 4:
			var puff := fmod(_t * 1.5 + p * 0.25, 1.0)
			draw_circle(Vector2(base.x - half - puff * 30.0, mid.y - 8 + p * 5), 2.0 + puff * 3.0, Color(1, 1, 1, 0.4 * (1.0 - puff) * k))
	k = _part_done("sun")
	if k > 0.0 and _trip_t < 0.0:
		draw_circle(Vector2(40, 60), 14.0, Color(1.0, 0.85, 0.3, k))
		draw_line(Vector2(base.x + half + 22, top - 14), Vector2(52, 66), Color(1.0, 0.85, 0.3, 0.4 * k), 1.0)
	k = _part_done("wire")
	if k > 0.0:
		draw_line(Vector2(base.x - half + 3, top + 3), Vector2(base.x - half + 3, base.y - 3), Color(1.0, 0.4, 0.2, k), 1.0)
		draw_line(Vector2(base.x + half - 3, top + 3), Vector2(base.x + half - 3, base.y - 3), Color(1.0, 0.4, 0.2, k), 1.0)
	k = _part_done("pin")
	if _dest >= LEGS.size() and _trip_t < 0.0 and k < 1.0:
		# The red "Remove Before Flight" tag until it is pulled.
		var tag := Vector2(base.x + half + 4, base.y - 20) + Vector2(40, 30) * k
		draw_rect(Rect2(tag, Vector2(26, 7)), Color(0.9, 0.1, 0.1, 1.0 - k))
		draw_string(_font, tag + Vector2(1, 6), "REMOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 1, 1, 1.0 - k))


func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)
