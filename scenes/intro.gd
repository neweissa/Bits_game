extends Node2D
## Opening cinematic. Five friends who already know each other chat before
## launch, board the rocket, lift off, and in deep space the rocket splits into
## five modules (like a CubeSat deployer) that each land on a different planet.
## The friends use the team's LPC sprite sheets (see CharacterSprites); anyone
## whose PNG is not in the project yet is drawn as a placeholder rectangle.
## Earth scenes use the "fondo cohete" background (sky and sea) and Sprout Lands
## grass for the launch site. Texts follow GameData.lang.
## Tap / SPACE / ENTER / ESC skips to chapter 1.

const W := 640.0
const H := 360.0
const GROUND_Y := 236.0
const PAD_X := 480.0
const MODULE := Vector2(28, 14)
const CHAR := Vector2(12, 24)
const SPACE_ROCKET_X := 320.0
const SPACE_ROCKET_Y := 300.0
const PLANET_RADIUS := 26.0
const BACKGROUND := preload("res://assets/backgrounds/para_ocean.png")
const GRASS := preload("res://assets/tilesets/draugr/grass.png")
const BIOM := preload("res://assets/tilesets/draugr/biom.png")
const GRASS_TILES: Array[Rect2] = [
	Rect2(16, 80, 16, 16), Rect2(32, 80, 16, 16), Rect2(48, 80, 16, 16), Rect2(64, 80, 16, 16),
	Rect2(16, 96, 16, 16), Rect2(32, 96, 16, 16), Rect2(48, 96, 16, 16), Rect2(64, 96, 16, 16),
]
## [region in biom.png, feet position] trees and bushes around the launch site.
const PLANTS := [
	[Rect2(16, 0, 32, 32), Vector2(20, 238)], [Rect2(0, 0, 16, 32), Vector2(318, 238)],
	[Rect2(48, 0, 32, 32), Vector2(608, 238)], [Rect2(0, 48, 16, 16), Vector2(350, 240)],
	[Rect2(16, 48, 16, 16), Vector2(580, 240)], [Rect2(0, 48, 16, 16), Vector2(408, 240)],
]
const PLANET_POS: Array[Vector2] = [
	Vector2(72, 96), Vector2(196, 66), Vector2(320, 54), Vector2(444, 66), Vector2(568, 96),
]

## [phase id, seconds]. Slower than the first version so every line can be read.
const PHASES := [
	["arrive", 4.0],
	["talk", 25.0],
	["board", 4.0],
	["countdown", 4.0],
	["launch", 4.5],
	["travel", 4.5],
	["alarm", 4.0],
	["split", 5.0],
	["landed", 7.0],
]

## [speaker index, Spanish, English]. Shows they have been friends for years.
const LINES := [
	[0, "Diez años desde el club de robótica... ¡y ahora somos astronautas!", "Ten years since robotics club... and now we're astronauts!"],
	[1, "Los mismos cinco que hicieron un cohete de cartón en quinto grado.", "Same five kids who built a cardboard rocket in 5th grade."],
	[2, "Se incendió, Bels.", "It caught fire, Bels."],
	[3, "Bitácora: cinco amigos, una nave, cero secretos.", "Crew log: five friends, one ship, zero secrets."],
	[4, "Pase lo que pase allá arriba, seguimos juntos. ¿Trato?", "Whatever happens up there, we stick together. Deal?"],
]

var _t: float = 0.0
var _total: float = 0.0
var _stars: Array[Vector3] = []  # x, y, size
var _font: Font
var _leaving: bool = false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_font = ThemeDB.fallback_font
	for phase in PHASES:
		_total += phase[1]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in 140:
		_stars.append(Vector3(rng.randf() * W, rng.randf() * H, 1.0 if rng.randf() < 0.8 else 2.0))


func _process(delta: float) -> void:
	_t += delta
	if _t >= _total:
		_finish()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var tapped: bool = event is InputEventMouseButton and event.is_pressed()
	if event.is_action_pressed("confirm") or event.is_action_pressed("back") or tapped:
		_finish()


func _finish() -> void:
	if _leaving:
		return
	_leaving = true
	GameData.chapter = 0
	get_tree().change_scene_to_file.call_deferred("res://scenes/chapter.tscn")


# --- timeline -------------------------------------------------------------

func _current_phase() -> Array:
	var start := 0.0
	for phase in PHASES:
		var length: float = phase[1]
		if _t < start + length:
			return [phase[0], clampf((_t - start) / length, 0.0, 1.0)]
		start += length
	return [PHASES[-1][0], 1.0]


func _draw() -> void:
	var phase := _current_phase()
	var id: String = phase[0]
	var p: float = phase[1]

	match id:
		"arrive", "talk", "board", "countdown":
			_draw_earth(id, p)
		"launch":
			_draw_launch(p)
		_:
			_draw_space(id, p)

	draw_set_transform_matrix(Transform2D.IDENTITY)
	_text(GameData.t("Toca / ESPACIO para saltar", "Tap / SPACE to skip"), Vector2(0, 352), 8, Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_RIGHT, W - 8)

	# Fade in at the start, fade out at the end.
	var fade := maxf(1.0 - _t / 0.8, (_t - (_total - 0.8)) / 0.8)
	if fade > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, clampf(fade, 0.0, 1.0)))


# --- earth: arrive, talk, board, countdown --------------------------------

func _draw_earth(id: String, p: float) -> void:
	_draw_dawn_sky(0.0)
	_draw_ground(0.0)
	_draw_rocket(Vector2(PAD_X, GROUND_Y), 0.0)

	match id:
		"arrive":
			for i in 5:
				var k := _ease_out(clampf(p * 1.25 - i * 0.05, 0.0, 1.0))
				var x := lerpf(-30.0 - i * 34.0, _home_x(i), k)
				var bob := absf(sin(_t * 9.0 + i)) * 2.0 if k < 1.0 else 0.0
				_draw_char(i, Vector2(x, GROUND_Y - bob), 1.0, k < 1.0)
			var title := GameData.t("TIERRA  -  DÍA DEL LANZAMIENTO", "EARTH  -  LAUNCH DAY")
			_text(title, Vector2(1, 41), 22, Color(0, 0, 0, 0.5 * minf(p * 2.0, 1.0)))
			_text(title, Vector2(0, 40), 22, Color(1, 1, 1, minf(p * 2.0, 1.0)))
		"talk":
			var line := mini(int(p * LINES.size()), LINES.size() - 1)
			var line_p := p * LINES.size() - line
			var speaker: int = LINES[line][0]
			for i in 5:
				var bob := absf(sin(_t * 9.0)) * 3.0 if i == speaker else 0.0
				_draw_char(i, Vector2(_home_x(i), GROUND_Y - bob))
			# Little marker over whoever is talking.
			var head := Vector2(_home_x(speaker), GROUND_Y - CHAR.y - 8)
			draw_colored_polygon(PackedVector2Array([head + Vector2(-4, -5), head + Vector2(4, -5), head]), Color.WHITE)
			_draw_dialogue(speaker, LINES[line][2 if GameData.lang == "en" else 1], line_p)
		"board":
			for i in 5:
				var k := clampf((p - i * 0.12) / 0.45, 0.0, 1.0)
				var x := lerpf(_home_x(i), PAD_X, _ease_in_out(k))
				var alpha := 1.0 - clampf((k - 0.8) / 0.2, 0.0, 1.0)
				var walking := k > 0.0 and k < 1.0
				var bob := absf(sin(_t * 9.0 + i)) * 2.0 if walking else 0.0
				_draw_char(i, Vector2(x, GROUND_Y - bob), alpha, walking)
			var aboard := GameData.t("¡Todos a bordo!", "All aboard!")
			draw_string_outline(_font, Vector2(0, 300), aboard, HORIZONTAL_ALIGNMENT_CENTER, W, 16, 5, Color.BLACK)
			_text(aboard, Vector2(0, 300), 16, Color.WHITE)
		"countdown":
			var number := 3 - mini(int(p * 3.0), 2)
			var pulse := 1.0 - fmod(p * 3.0, 1.0)
			_text(str(number), Vector2(0, 150), 48, Color(1, 1, 1, pulse))
			_draw_smoke(Vector2(PAD_X, GROUND_Y), p * 0.4)


func _draw_dialogue(speaker: int, line: String, line_p: float) -> void:
	var box := Rect2(12, 258, W - 24, 86)
	draw_rect(box, Color(0.04, 0.04, 0.1, 0.92))
	draw_rect(box, Color(1, 1, 1, 0.8), false, 1.0)
	var character: Dictionary = GameData.characters[speaker]
	_text(character.name.to_upper(), Vector2(24, 280), 12, character.color, HORIZONTAL_ALIGNMENT_LEFT, -1)
	var shown := line.substr(0, int(line.length() * clampf(line_p * 1.6, 0.0, 1.0)))
	draw_multiline_string(_font, Vector2(24, 302), shown, HORIZONTAL_ALIGNMENT_LEFT, W - 48, 12, -1, Color.WHITE)


# --- launch ---------------------------------------------------------------

func _draw_launch(p: float) -> void:
	var shake := (1.0 - p) * 3.0
	draw_set_transform(Vector2(sin(_t * 61.0), cos(_t * 53.0)) * shake)
	_draw_dawn_sky(p)
	_draw_ground(p)
	var lift := _ease_in(p) * (GROUND_Y + 160.0)
	_draw_smoke(Vector2(PAD_X, GROUND_Y), 0.4 + p * 0.6)
	_draw_rocket(Vector2(PAD_X, GROUND_Y - lift), 1.0)


# --- space: travel, alarm, split, landed ----------------------------------

func _draw_space(id: String, p: float) -> void:
	var scroll_speed := 0.0 if id == "landed" else 90.0
	var shake := 0.0
	if id == "alarm":
		shake = 2.0
	elif id == "split":
		shake = 2.0 * (1.0 - p)
	draw_set_transform(Vector2(sin(_t * 61.0), cos(_t * 53.0)) * shake)

	draw_rect(Rect2(-8, -8, W + 16, H + 16), Color(0.02, 0.02, 0.06))
	for star in _stars:
		var y := fmod(star.y + _t * scroll_speed * star.z * 0.6, H)
		draw_rect(Rect2(star.x, y, star.z, star.z), Color(1, 1, 1, 0.4 + 0.3 * star.z))

	# Planets slide in during travel, then stay.
	var planet_k := _ease_out(p) if id == "travel" else 1.0
	for i in 5:
		var pos := Vector2(PLANET_POS[i].x, lerpf(-60.0, PLANET_POS[i].y, planet_k))
		_draw_planet(i, pos)

	var base := Vector2(SPACE_ROCKET_X, SPACE_ROCKET_Y)
	match id:
		"travel":
			base.y = lerpf(H + 140.0, SPACE_ROCKET_Y, _ease_out(clampf(p * 1.4, 0.0, 1.0)))
			_draw_rocket(base, 1.0)
			_text(GameData.t("ESPACIO PROFUNDO", "DEEP SPACE"), Vector2(0, 340), 12, Color(1, 1, 1, 0.7))
		"alarm":
			_draw_rocket(base, 1.0)
			# Sparks around the rocket.
			for s in 6:
				var a := _t * 7.0 + s * 1.7
				var spark := base + Vector2(cos(a) * 22.0, -35.0 + sin(a * 1.3) * 30.0)
				draw_rect(Rect2(spark, Vector2(2, 2)), Color(1.0, 0.9, 0.3))
			draw_set_transform_matrix(Transform2D.IDENTITY)
			if sin(_t * 14.0) > 0.0:
				draw_rect(Rect2(0, 0, W, H), Color(1, 0, 0, 0.18))
			_text(GameData.t("ALERTA: FALLA EN LA SEPARACIÓN DE MÓDULOS", "WARNING: MODULE SEPARATION FAILURE"), Vector2(0, 190), 16, Color(1.0, 0.3, 0.3))
			_text(GameData.t("¡Los módulos se están soltando antes de tiempo!", "Modules releasing early!"), Vector2(0, 210), 11, Color(1.0, 0.7, 0.7))
		"split":
			_draw_split(base, p)
		"landed":
			_draw_landed(p)


func _draw_split(base: Vector2, p: float) -> void:
	# The nose cone and fins drift away; each module flies to its planet.
	var top := base.y - 5.0 * MODULE.y
	# Drift up through the gap between Zero and Fernix so it does not cover a planet.
	var nose_pos := Vector2(base.x, top).lerp(Vector2(258.0, -60.0), _ease_in(p))
	_draw_nose(nose_pos, Color(0.85, 0.85, 0.9))
	var fin_drop := _ease_in(p) * 120.0
	_draw_fins(base + Vector2(0, fin_drop), Color(0.7, 0.2, 0.2))

	for i in 5:
		var from := _module_center(i, base)
		var to: Vector2 = PLANET_POS[i]
		var k := _ease_in_out(clampf(p * 1.25 - i * 0.05, 0.0, 1.0))
		var pos := from.lerp(to, k)
		var color: Color = GameData.characters[i].color
		draw_line(from, pos, Color(color, 0.25 * (1.0 - k)), 1.0)
		if k < 1.0:
			var spin := k * TAU * (1.0 if i % 2 == 0 else -1.0)
			_draw_module(i, pos, spin, lerpf(1.0, 0.5, k))
		else:
			# Impact flash.
			var flash := clampf(1.0 - (p * 1.25 - i * 0.05 - 1.0) * 4.0, 0.0, 1.0)
			draw_circle(to, PLANET_RADIUS + 6.0, Color(1, 1, 1, flash * 0.8))


func _draw_landed(p: float) -> void:
	for i in 5:
		var planet_pos: Vector2 = PLANET_POS[i]
		var pod := planet_pos + Vector2(0, -PLANET_RADIUS - 3.0)
		_draw_module(i, pod, 0.0, 0.5)
		var planet: Dictionary = GameData.planets[i]
		var character: Dictionary = GameData.characters[i]
		var label_alpha := clampf(p * 4.0 - i * 0.3, 0.0, 1.0)
		_text(planet.name.to_upper(), Vector2(planet_pos.x - 60, planet_pos.y + PLANET_RADIUS + 14), 10,
			Color(1, 1, 1, label_alpha), HORIZONTAL_ALIGNMENT_CENTER, 120)
		_text(character.name, Vector2(planet_pos.x - 60, planet_pos.y + PLANET_RADIUS + 26), 9,
			Color(character.color, label_alpha), HORIZONTAL_ALIGNMENT_CENTER, 120)
	var text_alpha := clampf((p - 0.3) * 3.0, 0.0, 1.0)
	_text(GameData.t("Cinco amigos. Cinco planetas.", "Five friends. Five planets."), Vector2(0, 230), 18, Color(1, 1, 1, text_alpha))
	_text(GameData.t("Uno por uno, cada uno tendrá que sobrevivir.", "One by one, each of them has to survive."), Vector2(0, 256), 11,
		Color(0.8, 0.85, 1.0, text_alpha))


# --- drawing helpers ------------------------------------------------------

func _home_x(i: int) -> float:
	return 70.0 + i * 46.0


func _draw_char(i: int, feet: Vector2, alpha: float = 1.0, walking: bool = false) -> void:
	# Team sprite: walking right while moving, facing the camera when standing.
	var row := CharacterSprites.ROW_RIGHT if walking else CharacterSprites.ROW_DOWN
	var frame := 1 + int(_t * 8.0 + i) % (CharacterSprites.WALK_FRAMES - 1) if walking else 0
	if CharacterSprites.draw(self, i, feet, CHAR.y, row, frame, alpha):
		return
	var color: Color = GameData.characters[i].color
	draw_rect(Rect2(feet - Vector2(CHAR.x / 2.0, CHAR.y), CHAR), Color(color, alpha))
	draw_rect(Rect2(feet + Vector2(-4, -CHAR.y + 3), Vector2(8, 4)), Color(0.08, 0.08, 0.14, alpha))


func _module_center(i: int, base: Vector2) -> Vector2:
	return Vector2(base.x, base.y - (i + 0.5) * MODULE.y)


func _draw_module(i: int, center: Vector2, angle: float, scale_k: float) -> void:
	var color: Color = GameData.characters[i].color
	draw_set_transform(center, angle, Vector2(scale_k, scale_k))
	draw_rect(Rect2(-MODULE / 2.0, MODULE), color)
	draw_rect(Rect2(-MODULE / 2.0, MODULE), Color(1, 1, 1, 0.9), false, 1.0)
	draw_rect(Rect2(Vector2(-3, -3), Vector2(6, 6)), Color(0.1, 0.15, 0.25))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_nose(bottom_center: Vector2, color: Color) -> void:
	var half := MODULE.x / 2.0
	draw_colored_polygon(PackedVector2Array([
		bottom_center + Vector2(-half, 0), bottom_center + Vector2(half, 0), bottom_center + Vector2(0, -22),
	]), color)


func _draw_fins(base: Vector2, color: Color) -> void:
	var half := MODULE.x / 2.0
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-half, -18), base + Vector2(-half, 0), base + Vector2(-half - 10, 0),
	]), color)
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(half, -18), base + Vector2(half, 0), base + Vector2(half + 10, 0),
	]), color)


func _draw_rocket(base: Vector2, flame: float) -> void:
	if flame > 0.0:
		var length := 16.0 + flame * (10.0 + absf(sin(_t * 40.0)) * 10.0)
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-9, 0), base + Vector2(9, 0), base + Vector2(0, length),
		]), Color(1.0, 0.45, 0.1))
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-5, 0), base + Vector2(5, 0), base + Vector2(0, length * 0.6),
		]), Color(1.0, 0.9, 0.3))
	_draw_fins(base, Color(0.7, 0.2, 0.2))
	for i in 5:
		_draw_module(i, _module_center(i, base), 0.0, 1.0)
	_draw_nose(Vector2(base.x, base.y - 5.0 * MODULE.y), Color(0.85, 0.85, 0.9))


func _draw_planet(i: int, pos: Vector2) -> void:
	var tex := GameData.planet_texture(i)
	if tex != null:
		draw_texture_rect(tex, GameData.planet_rect(i, pos, PLANET_RADIUS), false)
		return
	var color: Color = GameData.planets[i].color
	draw_circle(pos, PLANET_RADIUS, color.darkened(0.45))
	draw_circle(pos - Vector2(3, 3), PLANET_RADIUS - 4.0, color)
	# A couple of craters so they read as planets.
	draw_circle(pos + Vector2(-8, 4), 4.0, color.darkened(0.2))
	draw_circle(pos + Vector2(7, -8), 3.0, color.darkened(0.2))


## Sky and sea from the "fondo cohete" image; it gets dark as the rocket climbs.
func _draw_dawn_sky(darken: float) -> void:
	var night := Color(0.02, 0.02, 0.06)
	# Raised a bit so more sea shows above the launch field.
	draw_texture_rect(BACKGROUND, Rect2(-8, -52, W + 16, H + 16), false, Color.WHITE.lerp(night, darken))


## Launch site: Sprout Lands grass with a darker edge, a few trees, the tower.
func _draw_ground(darken: float) -> void:
	var night := Color(0.02, 0.02, 0.06)
	var tint := Color.WHITE.lerp(night, darken * 0.6)
	var x := -16.0
	var col := 0
	while x < W + 16.0:
		var y := GROUND_Y
		var row := 0
		while y < H + 8.0:
			var region: Rect2 = GRASS_TILES[absi(col * 7 + row * 13 + (col * row) % 5) % GRASS_TILES.size()]
			draw_texture_rect_region(GRASS, Rect2(x, y, 16, 16), region, tint)
			y += 16.0
			row += 1
		x += 16.0
		col += 1
	# Edge of the field and little tufts of grass.
	draw_rect(Rect2(-8, GROUND_Y - 1, W + 16, 3), Color(0.2, 0.42, 0.22).lerp(night, darken * 0.6))
	var tuft := Color(0.36, 0.62, 0.3).lerp(night, darken * 0.6)
	for t in 40:
		var tx := fmod(t * 47.0, W + 16.0) - 8.0
		draw_line(Vector2(tx, GROUND_Y), Vector2(tx - 2, GROUND_Y - 4), tuft, 1.0)
		draw_line(Vector2(tx + 2, GROUND_Y), Vector2(tx + 3, GROUND_Y - 5), tuft, 1.0)
	for plant in PLANTS:
		var region: Rect2 = plant[0]
		var feet: Vector2 = plant[1]
		var size := region.size * 1.5
		draw_texture_rect_region(BIOM, Rect2(feet - Vector2(size.x / 2.0, size.y), size), region, tint)
	# Launch pad and tower.
	var tower := Color(0.45, 0.45, 0.5).lerp(night, darken * 0.6)
	draw_rect(Rect2(PAD_X - 26, GROUND_Y - 2, 52, 4), Color(0.35, 0.35, 0.38).lerp(night, darken * 0.6))
	draw_rect(Rect2(PAD_X + 24, GROUND_Y - 110, 6, 110), tower)
	for y in range(int(GROUND_Y) - 100, int(GROUND_Y), 20):
		draw_rect(Rect2(PAD_X + 14, y, 16, 2), tower)


func _draw_smoke(pad: Vector2, amount: float) -> void:
	for s in 8:
		var side := -1.0 if s % 2 == 0 else 1.0
		var spread := amount * (20.0 + s * 8.0)
		var pos := pad + Vector2(side * spread, -4.0 - (s % 3) * 4.0)
		draw_circle(pos, 4.0 + amount * 10.0, Color(0.85, 0.85, 0.85, 0.6 * minf(amount * 3.0, 1.0)))


func _text(value: String, pos: Vector2, size: int, color: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, width: float = W) -> void:
	draw_string(_font, pos, value, align, width, size, color)


func _ease_in(x: float) -> float:
	return x * x


func _ease_out(x: float) -> float:
	return 1.0 - (1.0 - x) * (1.0 - x)


func _ease_in_out(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)
