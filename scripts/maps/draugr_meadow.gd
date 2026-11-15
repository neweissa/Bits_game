class_name DraugrMeadow
extends PlanetMap
## Map for planet Draugr (Daenerys, radio noise): a quiet meadow with a pond,
## trees, bushes and flowers where the alien beacons stand. Uses the Sprout Lands
## pack (assets/tilesets/draugr, by Cup Nooble - credit required, see LICENSE).

const GRASS := preload("res://assets/tilesets/draugr/grass.png")
const WATER := preload("res://assets/tilesets/draugr/water.png")
const BIOM := preload("res://assets/tilesets/draugr/biom.png")

## Full grass tiles (with small details) in grass.png.
const GRASS_TILES: Array[Rect2] = [
	Rect2(0, 80, 16, 16), Rect2(16, 80, 16, 16), Rect2(32, 80, 16, 16), Rect2(48, 80, 16, 16),
	Rect2(64, 80, 16, 16), Rect2(80, 80, 16, 16), Rect2(0, 96, 16, 16), Rect2(16, 96, 16, 16),
	Rect2(32, 96, 16, 16), Rect2(48, 96, 16, 16), Rect2(64, 96, 16, 16), Rect2(80, 96, 16, 16),
]
## Regions in biom.png: [region, collision rect relative to the top-left or empty]
const BIG_TREE := [Rect2(16, 0, 32, 32), Rect2(10, 22, 12, 8)]
const APPLE_TREE := [Rect2(48, 0, 32, 32), Rect2(10, 22, 12, 8)]
const SMALL_TREE := [Rect2(0, 0, 16, 32), Rect2(4, 22, 8, 8)]
const BUSH := [Rect2(0, 48, 16, 16), Rect2(2, 6, 12, 8)]
const BERRY_BUSH := [Rect2(16, 48, 16, 16), Rect2(2, 6, 12, 8)]
const LONG_BUSH := [Rect2(0, 64, 32, 16), Rect2(2, 4, 28, 10)]
const ROCK := [Rect2(128, 16, 16, 16), Rect2(2, 6, 12, 8)]
const MUSHROOM := [Rect2(80, 0, 16, 16), Rect2()]
const FLOWER_A := [Rect2(96, 32, 16, 16), Rect2()]
const FLOWER_B := [Rect2(112, 32, 16, 16), Rect2()]
const SUNFLOWER := [Rect2(128, 32, 16, 32), Rect2(4, 24, 8, 6)]
const STUMP := [Rect2(64, 32, 16, 16), Rect2(2, 6, 12, 8)]

var _pond: Rect2
## [region, top-left]
var _props: Array = []


func _build() -> void:
	_pond = Rect2(arena.position + Vector2(400, 176), Vector2(112, 64))
	if _clear_of_points(_pond, 8.0):
		blocked.append(_pond.grow(-2.0))
	else:
		_pond = Rect2()
	var o := arena.position
	var layout := [
		[BIG_TREE, Vector2(20, 12)], [APPLE_TREE, Vector2(70, 200)], [SMALL_TREE, Vector2(250, 20)],
		[BIG_TREE, Vector2(560, 20)], [SMALL_TREE, Vector2(530, 210)], [APPLE_TREE, Vector2(230, 222)],
		[BUSH, Vector2(110, 90)], [BERRY_BUSH, Vector2(380, 40)], [LONG_BUSH, Vector2(20, 120)],
		[ROCK, Vector2(330, 120)], [STUMP, Vector2(470, 100)], [SUNFLOWER, Vector2(380, 160)],
		[MUSHROOM, Vector2(60, 160)], [FLOWER_A, Vector2(200, 60)], [FLOWER_B, Vector2(420, 90)],
		[FLOWER_A, Vector2(300, 200)], [MUSHROOM, Vector2(590, 140)], [FLOWER_B, Vector2(160, 240)],
	]
	for item in layout:
		var region: Rect2 = item[0][0]
		var collision: Rect2 = item[0][1]
		var pos: Vector2 = o + item[1]
		if not _clear_of_points(Rect2(pos, region.size)):
			continue
		_props.append([region, pos])
		if collision.size != Vector2.ZERO:
			blocked.append(Rect2(pos + collision.position, collision.size))


func _draw() -> void:
	_fill(GRASS, arena, 16.0, func(cell: Vector2i) -> Rect2:
		var h := _hash(cell, 11) % 20
		# Mostly the plain tiles, some with details.
		return GRASS_TILES[0] if h < 12 else GRASS_TILES[h - 8])
	if _pond.size != Vector2.ZERO:
		var frame := int(_t * 3.0) % 4
		_fill(WATER, _pond, 16.0, func(_cell): return Rect2(frame * 16, 0, 16, 16))
		draw_rect(_pond, Color(0.25, 0.42, 0.22), false, 2.0)
		# Radio noise ripples on the water.
		for i in 3:
			var r := fmod(_t * 12.0 + i * 10.0, 30.0)
			draw_arc(_pond.get_center(), r, 0.0, TAU, 24, Color(1, 1, 1, 0.25 * (1.0 - r / 30.0)), 1.0)
	var sorted := _props.duplicate()
	sorted.sort_custom(func(a, b): return a[1].y + a[0].size.y < b[1].y + b[0].size.y)
	for prop in sorted:
		draw_texture_rect_region(BIOM, Rect2(prop[1], prop[0].size), prop[0])
