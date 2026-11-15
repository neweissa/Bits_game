class_name ZeroField
extends PlanetMap
## Map for planet Zero (Bels, no gravity): grey stone ground, a sci-fi landing
## pad where the module came down, and rocks that float over their shadows.
## Assets: assets/tilesets/zero (only the grey parts of floor.png are used).

const FLOOR := preload("res://assets/tilesets/zero/floor.png")
const ROCKS := preload("res://assets/tilesets/zero/rocks.png")
const SCIFI := preload("res://assets/tilesets/zero/scifi_tileset.png")

const TILE := 16.0
## Plain grey tiles in floor.png.
const GREY_TILES: Array[Rect2] = [
	Rect2(112, 48, 16, 16), Rect2(32, 112, 16, 16), Rect2(48, 112, 16, 16),
	Rect2(32, 128, 16, 16), Rect2(48, 128, 16, 16),
]
## Raised stone slab (grey octagon) used as decoration.
const SLAB := Rect2(112, 112, 32, 32)
## Dark metal floor plates in the sci-fi tileset (landing pad).
const PLATES: Array[Rect2] = [Rect2(0, 448, 32, 32), Rect2(32, 448, 32, 32)]
const BIG_ROCKS: Array[Rect2] = [Rect2(0, 32, 32, 32), Rect2(32, 32, 32, 32)]
const SMALL_ROCKS: Array[Rect2] = [
	Rect2(0, 0, 16, 16), Rect2(16, 0, 16, 16), Rect2(32, 0, 16, 16), Rect2(48, 0, 16, 16),
	Rect2(0, 16, 16, 16), Rect2(16, 16, 16, 16), Rect2(32, 16, 16, 16), Rect2(48, 16, 16, 16),
]
const FLOAT_HEIGHT := 9.0

## [region, ground position (center of the shadow), phase]
var _rocks: Array = []
var _slabs: Array[Vector2] = []
var _pad: Rect2


func _build() -> void:
	var center := arena.get_center()
	_pad = Rect2(center - Vector2(64, 32), Vector2(128, 64))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1010
	var big_spots := [Vector2(90, 120), Vector2(230, 280), Vector2(470, 120), Vector2(560, 270), Vector2(140, 250)]
	for spot in big_spots:
		_add_rock(BIG_ROCKS[rng.randi() % BIG_ROCKS.size()], spot, rng, true)
	var small_spots := [Vector2(300, 110), Vector2(400, 300), Vector2(60, 200), Vector2(520, 200), Vector2(380, 160), Vector2(200, 170)]
	for spot in small_spots:
		_add_rock(SMALL_ROCKS[rng.randi() % SMALL_ROCKS.size()], spot, rng, false)
	_slabs = [Vector2(40, 90), Vector2(330, 250), Vector2(580, 90)]


func _add_rock(region: Rect2, ground: Vector2, rng: RandomNumberGenerator, solid: bool) -> void:
	if not _clear_of_points(Rect2(ground - region.size / 2.0, region.size)):
		return
	_rocks.append([region, ground, rng.randf() * TAU])
	if solid:
		# You bump into the rock's shadow footprint.
		blocked.append(Rect2(ground - Vector2(region.size.x * 0.4, 5), Vector2(region.size.x * 0.8, 10)))


func _draw() -> void:
	_fill(FLOOR, arena, TILE, func(cell: Vector2i) -> Rect2:
		return GREY_TILES[_hash(cell, 3) % GREY_TILES.size()])
	for slab in _slabs:
		draw_texture_rect_region(FLOOR, Rect2(slab, SLAB.size), SLAB)
	# Landing pad: dark plates with a pulsing frame.
	for i in 8:
		var cell := Vector2(i % 4, i / 4)
		draw_texture_rect_region(SCIFI, Rect2(_pad.position + cell * 32.0, Vector2(32, 32)), PLATES[(i + i / 4) % 2])
	draw_rect(_pad, Color(0.55, 0.8, 1.0, 0.35 + 0.25 * sin(_t * 2.0)), false, 1.0)

	# Floating rocks: shadow on the ground, rock bobbing above it.
	var sorted := _rocks.duplicate()
	sorted.sort_custom(func(a, b): return a[1].y < b[1].y)
	for rock in sorted:
		var region: Rect2 = rock[0]
		var ground: Vector2 = rock[1]
		var bob := sin(_t * 1.4 + rock[2]) * 3.0
		var shadow_w := region.size.x * (0.7 - bob * 0.02)
		draw_set_transform(ground, 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, shadow_w / 2.0, Color(0, 0, 0, 0.3))
		draw_set_transform_matrix(Transform2D.IDENTITY)
		var top_left := ground - Vector2(region.size.x / 2.0, region.size.y + FLOAT_HEIGHT + bob)
		draw_texture_rect_region(ROCKS, Rect2(top_left.round(), region.size), region)
