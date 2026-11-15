class_name BlackoutStreet
extends PlanetMap
## "Se fue la luz" map for planet Yuki (chapter 1, Andrew): a city street where the
## power went out. Built from the Neo Zero tilesets in assets/tilesets/neo_zero.
##
## Layout inside the arena (top to bottom):
##   - a row of storefronts (signs + shop fronts), solid wall
##   - the sidewalk (16px tiles, some cracked), with vending machines and dead lamps
##   - the curb and the road, with a food cart, a generator and crates as obstacles
## Everything is drawn darker because there is no power; one lamp still flickers.

const TILESET := preload("res://assets/tilesets/neo_zero/neo_zero_tileset_03.png")
const BUILDINGS := preload("res://assets/tilesets/neo_zero/neo_zero_buildings_02.png")
const PROPS := preload("res://assets/tilesets/neo_zero/neo_zero_props_02_free.png")

const TILE := 16
const FACADE_W := 48
const SIGN_H := 16
const SHOP_H := 32
const WALL_H := SIGN_H + SHOP_H
const SIDEWALK_H := 80

## Plain and cracked sidewalk tiles (column, row) in neo_zero_tileset_03.
const SIDEWALK_PLAIN: Array[Vector2i] = [
	Vector2i(0, 10), Vector2i(5, 10), Vector2i(6, 10), Vector2i(0, 11), Vector2i(1, 11), Vector2i(5, 11), Vector2i(6, 11),
]
const SIDEWALK_CRACKED: Array[Vector2i] = [
	Vector2i(1, 10), Vector2i(2, 10), Vector2i(3, 10), Vector2i(2, 11), Vector2i(3, 11), Vector2i(4, 11),
]
const ROAD_COLOR := Color(0.105, 0.118, 0.145)
const LANE_COLOR := Color(0.85, 0.87, 0.84, 0.25)
const CURB_COLOR := Color(0.2, 0.23, 0.26)

## Regions in neo_zero_props_02_free.png.
const LAMP_TALL := Rect2(160, 0, 16, 48)
const LAMP_SIGN := Rect2(176, 0, 16, 48)
const LAMP_RED := Rect2(144, 16, 16, 32)
const VENDING_WIDE := Rect2(80, 16, 32, 24)
const VENDING_A := Rect2(112, 16, 16, 24)
const VENDING_B := Rect2(128, 16, 16, 24)
const FOOD_CART := Rect2(116, 52, 44, 28)
const GENERATOR := Rect2(162, 56, 28, 24)
const CRATES := Rect2(18, 74, 28, 22)
const CONSOLE := Rect2(144, 80, 32, 16)
const BIN := Rect2(178, 80, 12, 16)


## [region, top-left position, collision rect relative to the top-left or empty]
var _props: Array = []
var _tiles: Array[Vector2i] = []
var _flicker_lamp: Vector2 = Vector2.ZERO


func _build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4040
	var cols := int(ceil(arena.size.x / TILE))
	var rows := SIDEWALK_H / TILE
	for i in cols * rows:
		var cracked := rng.randf() < 0.22
		var pool := SIDEWALK_CRACKED if cracked else SIDEWALK_PLAIN
		_tiles.append(pool[rng.randi() % pool.size()])
	_place_props()


## Area where enemies and items may move (below the storefront wall).
func walkable() -> Rect2:
	return Rect2(arena.position.x, arena.position.y + WALL_H, arena.size.x, arena.size.y - WALL_H)


# --- layout ----------------------------------------------------------------------

func _sidewalk_top() -> float:
	return arena.position.y + WALL_H


func _road_top() -> float:
	return _sidewalk_top() + SIDEWALK_H


func _place_props() -> void:
	var x0 := arena.position.x
	var sidewalk := _sidewalk_top()
	var road := _road_top()
	# Vending machines against the shop fronts (they block like part of the wall).
	_add(VENDING_WIDE, Vector2(x0 + 40, sidewalk), Rect2(0, 10, 32, 14))
	_add(VENDING_A, Vector2(x0 + 76, sidewalk), Rect2(0, 10, 16, 14))
	_add(VENDING_B, Vector2(x0 + 420, sidewalk), Rect2(0, 10, 16, 14))
	_add(VENDING_A, Vector2(x0 + 438, sidewalk), Rect2(0, 10, 16, 14))
	_add(BIN, Vector2(x0 + 230, sidewalk + 8), Rect2(0, 8, 12, 8))
	_add(CONSOLE, Vector2(x0 + 520, sidewalk + 6), Rect2(0, 6, 32, 10))
	# Dead street lamps along the curb (the base is what you bump into).
	var lamps := [[LAMP_TALL, 100.0], [LAMP_RED, 250.0], [LAMP_SIGN, 360.0], [LAMP_TALL, 500.0]]
	for lamp in lamps:
		var region: Rect2 = lamp[0]
		var pos := Vector2(x0 + lamp[1], road - region.size.y + 2.0)
		_add(region, pos, Rect2(4, region.size.y - 6, 8, 6))
	_flicker_lamp = Vector2(x0 + 250.0 + 8.0, road - LAMP_RED.size.y + 8.0)
	# Obstacles on the road.
	_add(FOOD_CART, Vector2(x0 + 70, road + 70), Rect2(0, 12, 44, 16))
	_add(GENERATOR, Vector2(x0 + 455, road + 40), Rect2(0, 8, 28, 16))
	_add(CRATES, Vector2(x0 + 190, road + 95), Rect2(0, 6, 28, 16))
	_add(CRATES, Vector2(x0 + 545, road + 105), Rect2(0, 6, 28, 16))


func _add(region: Rect2, pos: Vector2, collision: Rect2) -> void:
	_props.append([region, pos.round(), collision])
	if collision.size != Vector2.ZERO:
		blocked.append(Rect2(pos.round() + collision.position, collision.size))


func _extra_walls() -> Array[Rect2]:
	# The storefront row is a solid wall.
	return [Rect2(arena.position, Vector2(arena.size.x, WALL_H))]


# --- drawing ---------------------------------------------------------------------

func _draw() -> void:
	var x0 := arena.position.x
	var y0 := arena.position.y
	var right := arena.end.x

	# Storefronts: sign strip (top of each facade) + shop front (bottom).
	var x := x0
	var facade := 0
	while x < right:
		var w := minf(FACADE_W, right - x)
		var fx := float((facade % 7) * FACADE_W)
		draw_texture_rect_region(BUILDINGS, Rect2(x, y0, w, SIGN_H), Rect2(fx, 0, w, SIGN_H))
		draw_texture_rect_region(BUILDINGS, Rect2(x, y0 + SIGN_H, w, SHOP_H), Rect2(fx, 112 - SHOP_H, w, SHOP_H))
		x += FACADE_W
		facade += 3  # Skip around the sheet so neighbours do not repeat.

	# Sidewalk tiles.
	var cols := int(ceil(arena.size.x / TILE))
	var sidewalk := _sidewalk_top()
	for i in _tiles.size():
		var cell := Vector2(x0 + (i % cols) * TILE, sidewalk + (i / cols) * TILE)
		var w := minf(TILE, right - cell.x)
		var tile: Vector2i = _tiles[i]
		draw_texture_rect_region(TILESET, Rect2(cell, Vector2(w, TILE)), Rect2(tile.x * TILE, tile.y * TILE, w, TILE))

	# Curb and road with a dashed lane line.
	var road := _road_top()
	draw_rect(Rect2(x0, road, arena.size.x, arena.end.y - road), ROAD_COLOR)
	draw_rect(Rect2(x0, road, arena.size.x, 3), CURB_COLOR)
	var lane_y := road + (arena.end.y - road) / 2.0
	for dash_x in range(int(x0) + 8, int(right) - 16, 40):
		draw_rect(Rect2(dash_x, lane_y, 20, 2), LANE_COLOR)

	# Props, sorted top to bottom.
	var sorted := _props.duplicate()
	sorted.sort_custom(func(a, b): return a[1].y + a[0].size.y < b[1].y + b[0].size.y)
	for prop in sorted:
		var region: Rect2 = prop[0]
		draw_texture_rect_region(PROPS, Rect2(prop[1], region.size), region)

	# Blackout: everything is dim...
	draw_rect(arena, Color(0.0, 0.0, 0.05, 0.45))
	# ...except one lamp that keeps trying to turn on.
	var on := sin(_t * 23.0) + sin(_t * 7.3) > 1.2
	if on:
		draw_circle(_flicker_lamp + Vector2(0, 40), 26.0, Color(1.0, 0.3, 0.25, 0.08))
		draw_circle(_flicker_lamp, 4.0, Color(1.0, 0.5, 0.4, 0.9))
