class_name LabMap
extends PlanetMap
## Map for Control C (Rayan): a lab where everything fails at least once.
## The room frame of the lab tileset is stretched around the arena (9-slice),
## with consoles and crates to dodge around, floor grates and arrows, posters on
## the wall, and the glowing core in the middle where the module landed. The
## alarm light pulses red now and then. Ghosts fly through everything.
## Asset: assets/tilesets/lab (Laboratory Tileset Revamped LITE, ExceptRea,
## CC BY-NC 4.0).

const LAB := preload("res://assets/tilesets/lab/lab_tileset_LITE.png")

## Big room in the tileset: tech border around a dark floor.
const ROOM := Rect2(64, 128, 160, 160)
const ROOM_MARGIN := 32.0
const BORDER := 22.0
const FLOOR_COLOR := Color(0.086, 0.13, 0.19)

const CORE := Rect2(160, 32, 64, 64)
const CONSOLE := Rect2(128, 96, 96, 32)
const MONITOR := Rect2(64, 96, 32, 32)
const CRATE := Rect2(96, 96, 32, 32)
const GRATE := Rect2(64, 64, 32, 32)
const SLATS := Rect2(96, 64, 32, 32)
const ARROW_RIGHT := Rect2(0, 96, 32, 32)
const ARROW_LEFT := Rect2(0, 64, 32, 32)
const DANGER := Rect2(128, 32, 32, 32)
const EXTINGUISHER := Rect2(64, 32, 32, 32)
const SLIME := Rect2(32, 128, 32, 32)
const POSTERS: Array[Rect2] = [Rect2(0, 0, 32, 32), Rect2(32, 0, 32, 32), Rect2(64, 0, 32, 32), Rect2(96, 0, 32, 32), Rect2(128, 0, 32, 32)]

## [region, top-left position, solid]
var _props: Array = []
var _style: StyleBoxTexture


func _build() -> void:
	_style = StyleBoxTexture.new()
	_style.texture = LAB
	_style.region_rect = ROOM
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_style.set_texture_margin(side, ROOM_MARGIN)
	_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT

	var o := arena.position
	# Floor decoration first (drawn under everything, never blocks).
	for spot in [Vector2(170, 52), Vector2(400, 176), Vector2(236, 196), Vector2(362, 40)]:
		_add(GRATE, o + spot, false)
	_add(SLATS, o + Vector2(520, 130), false)
	_add(ARROW_RIGHT, o + Vector2(150, 118), false)
	_add(ARROW_LEFT, o + Vector2(426, 102), false)
	_add(DANGER, o + Vector2(540, 196), false)
	_add(SLIME, o + Vector2(28, 210), false)
	# Furniture you have to walk around.
	_add(CONSOLE, o + Vector2(48, 40), true)
	_add(CONSOLE, o + Vector2(464, 206), true)
	_add(MONITOR, o + Vector2(480, 36), true)
	_add(CRATE, o + Vector2(512, 36), true)
	_add(CRATE, o + Vector2(72, 200), true)
	_add(MONITOR, o + Vector2(104, 200), true)
	_add(CRATE, o + Vector2(300, 214), true)
	_add(EXTINGUISHER, o + Vector2(24, 112), true)


func _add(region: Rect2, top_left: Vector2, solid: bool) -> void:
	var rect := Rect2(top_left, region.size)
	if solid and not _clear_of_points(rect):
		return
	_props.append([region, top_left, solid])
	if solid:
		# Collide with the lower part only, so you can stand "behind" a prop.
		blocked.append(Rect2(top_left + Vector2(2, region.size.y * 0.35), Vector2(region.size.x - 4, region.size.y * 0.6)))


func walkable() -> Rect2:
	return arena.grow(-BORDER)


func _extra_walls() -> Array[Rect2]:
	# The tech border is a wall all around.
	var a := arena
	return [
		Rect2(a.position, Vector2(a.size.x, BORDER)),
		Rect2(Vector2(a.position.x, a.end.y - BORDER), Vector2(a.size.x, BORDER)),
		Rect2(a.position, Vector2(BORDER, a.size.y)),
		Rect2(Vector2(a.end.x - BORDER, a.position.y), Vector2(BORDER, a.size.y)),
	]


func _draw() -> void:
	draw_rect(arena, FLOOR_COLOR)
	# Faint floor tiles.
	var line := Color(1, 1, 1, 0.03)
	for x in range(int(arena.position.x), int(arena.end.x), 32):
		draw_line(Vector2(x, arena.position.y), Vector2(x, arena.end.y), line, 1.0)
	for y in range(int(arena.position.y), int(arena.end.y), 32):
		draw_line(Vector2(arena.position.x, y), Vector2(arena.end.x, y), line, 1.0)
	draw_style_box(_style, arena)

	# The core where Rayan's module came down.
	var core := Rect2(arena.get_center() - CORE.size / 2.0, CORE.size)
	draw_texture_rect_region(LAB, core, CORE)
	draw_circle(arena.get_center(), 10.0 + 2.0 * sin(_t * 3.0), Color(0.75, 1.0, 1.0, 0.15 + 0.1 * sin(_t * 3.0)))

	# Posters on the top wall.
	for i in POSTERS.size():
		var pos := Vector2(arena.position.x + 96 + i * 96, arena.position.y - 4)
		draw_texture_rect_region(LAB, Rect2(pos, Vector2(32, 26)), Rect2(POSTERS[i].position, Vector2(32, 26)))

	# Props, sorted by their bottom so the lower ones are drawn on top.
	var sorted := _props.duplicate()
	sorted.sort_custom(func(a, b): return (not a[2] and b[2]) or (a[2] == b[2] and a[1].y + a[0].size.y < b[1].y + b[0].size.y))
	for prop in sorted:
		var region: Rect2 = prop[0]
		var pos: Vector2 = prop[1]
		var color := Color(1, 1, 1, 1.0 if prop[2] else 0.75)
		draw_texture_rect_region(LAB, Rect2(pos, region.size), region, color)

	# Alarm: every few seconds the lights fail and pulse red.
	var alarm := maxf(0.0, sin(_t * 0.9)) * maxf(0.0, sin(_t * 9.0))
	if alarm > 0.0:
		draw_rect(arena, Color(1.0, 0.1, 0.15, 0.1 * alarm))
