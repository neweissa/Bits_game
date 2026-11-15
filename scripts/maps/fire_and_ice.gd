class_name FireAndIce
extends PlanetMap
## Map for planet Fernix (Ray, extreme heat and extreme cold): the left half is
## frozen (snow, an ice lake, snowy pines, snowmen), the right half is volcanic
## (dark rock, animated lava pools, rocks and torches). Lava pools block the way.
## Assets: assets/tilesets/fernix.

const LAVA_SHEET := preload("res://assets/tilesets/fernix/lava_sheet.png")
const LAVA_LAND := preload("res://assets/tilesets/fernix/lava_land.png")
const ROCK_A := preload("res://assets/tilesets/fernix/lava_rock1.png")
const ROCK_B := preload("res://assets/tilesets/fernix/lava_rock2.png")
const TREE_A := preload("res://assets/tilesets/fernix/Tree_0.png")
const TREE_B := preload("res://assets/tilesets/fernix/Tree_2.png")
const SNOWMAN_A := preload("res://assets/tilesets/fernix/Snowman_0.png")
const SNOWMAN_B := preload("res://assets/tilesets/fernix/Snowman_3.png")
const LOG := preload("res://assets/tilesets/fernix/Log.png")
const SNOW: Array[Texture2D] = [
	preload("res://assets/tilesets/fernix/Snow_0.png"), preload("res://assets/tilesets/fernix/Snow_1.png"),
	preload("res://assets/tilesets/fernix/Snow_2.png"), preload("res://assets/tilesets/fernix/Snow_3.png"),
	preload("res://assets/tilesets/fernix/Snow_4.png"), preload("res://assets/tilesets/fernix/Snow_5.png"),
]
## Ice lake 9-slice: [top-left, top, top-right, left, center, right, bottom-left, bottom, bottom-right]
const ICE: Array[Texture2D] = [
	preload("res://assets/tilesets/fernix/Ice_Top_Left.png"), preload("res://assets/tilesets/fernix/Ice_Top_Middle.png"),
	preload("res://assets/tilesets/fernix/Ice_Top_Right.png"), preload("res://assets/tilesets/fernix/Ice_Left.png"),
	preload("res://assets/tilesets/fernix/Ice.png"), preload("res://assets/tilesets/fernix/Ice_Right.png"),
	preload("res://assets/tilesets/fernix/Ice_Bottom_Left.png"), preload("res://assets/tilesets/fernix/Ice_Bottom_Middle.png"),
	preload("res://assets/tilesets/fernix/Ice_Bottom_Right.png"),
]
const TORCH: Array[Texture2D] = [
	preload("res://assets/tilesets/fernix/torch1.png"), preload("res://assets/tilesets/fernix/torch2.png"),
	preload("res://assets/tilesets/fernix/torch3.png"), preload("res://assets/tilesets/fernix/torch4.png"),
	preload("res://assets/tilesets/fernix/torch5.png"), preload("res://assets/tilesets/fernix/torch6.png"),
	preload("res://assets/tilesets/fernix/torch7.png"),
]
## 16px solid lava tile in frame 0 of lava_sheet.png; frame k is 128 px to the right.
const LAVA_TILE := Rect2(0, 48, 16, 16)
const LAVA_FRAMES := 7
const LAVA_FRAME_W := 128.0
## Cracked dark rock tiles inside lava_land.png.
const ROCK_TILES: Array[Rect2] = [
	Rect2(32, 32, 16, 16), Rect2(48, 32, 16, 16), Rect2(64, 32, 16, 16),
	Rect2(32, 48, 16, 16), Rect2(48, 48, 16, 16), Rect2(64, 48, 16, 16),
	Rect2(32, 64, 16, 16), Rect2(48, 64, 16, 16), Rect2(64, 64, 16, 16),
]

var _cold: Rect2
var _hot: Rect2
var _ice_lake: Rect2
var _lava_pools: Array[Rect2] = []
## [texture, top-left, scale, kind]
var _props: Array = []


func _build() -> void:
	var half := floorf(arena.size.x / 2.0 / 32.0) * 32.0
	_cold = Rect2(arena.position, Vector2(half, arena.size.y))
	_hot = Rect2(arena.position.x + half, arena.position.y, arena.size.x - half, arena.size.y)
	_ice_lake = Rect2(arena.position + Vector2(48, 168), Vector2(128, 96))
	var pools: Array[Rect2] = [
		Rect2(_hot.position + Vector2(48, 32), Vector2(64, 48)),
		Rect2(_hot.position + Vector2(176, 160), Vector2(80, 48)),
		Rect2(_hot.position + Vector2(32, 192), Vector2(48, 32)),
	]
	for pool in pools:
		if _clear_of_points(pool, 10.0):
			_lava_pools.append(pool)
			blocked.append(pool.grow(-3.0))
	# Cold side.
	_prop(TREE_A, Vector2(56, 112), 1.0, Rect2(12, 46, 10, 10))
	_prop(TREE_B, Vector2(206, 92), 1.0, Rect2(12, 46, 10, 10))
	_prop(TREE_A, Vector2(250, 250), 1.0, Rect2(12, 46, 10, 10))
	_prop(SNOWMAN_A, Vector2(140, 104), 0.5, Rect2(4, 22, 8, 8))
	_prop(SNOWMAN_B, Vector2(210, 196), 0.5, Rect2(4, 22, 8, 8))
	_prop(LOG, Vector2(226, 300), 0.75, Rect2(2, 8, 20, 12))
	# Hot side.
	_prop(ROCK_A, _hot.position + Vector2(140, 40), 1.0, Rect2(2, 6, 12, 10))
	_prop(ROCK_B, _hot.position + Vector2(230, 70), 1.0, Rect2(2, 6, 12, 10))
	_prop(ROCK_A, _hot.position + Vector2(110, 230), 1.0, Rect2(2, 6, 12, 10))
	_prop(ROCK_B, _hot.position + Vector2(20, 120), 1.0, Rect2(2, 6, 12, 10))
	_prop(null, _hot.position + Vector2(130, 120), 1.0, Rect2(4, 24, 8, 8), "torch")
	_prop(null, _hot.position + Vector2(260, 220), 1.0, Rect2(4, 24, 8, 8), "torch")


func _prop(tex: Texture2D, pos: Vector2, scale_k: float, collision: Rect2, kind: String = "") -> void:
	var size := (tex.get_size() if tex != null else Vector2(16, 32)) * scale_k
	if not _clear_of_points(Rect2(pos, size)):
		return
	_props.append([tex, pos, scale_k, kind])
	if collision.size != Vector2.ZERO:
		blocked.append(Rect2(pos + collision.position, collision.size))


func _draw() -> void:
	# Cold half: snow, mostly the plain tile.
	_fill(SNOW[0], _cold, 32.0, func(_cell): return Rect2(0, 0, 32, 32))
	var y := _cold.position.y
	while y < _cold.end.y:
		var x := _cold.position.x
		while x < _cold.end.x:
			var h := _hash(Vector2i(int(x), int(y)), 5) % 10
			if h >= 6:
				draw_texture_rect_region(SNOW[h - 5], Rect2(x, y, 32, minf(32, _cold.end.y - y)), Rect2(0, 0, 32, minf(32, _cold.end.y - y)))
			x += 32.0
		y += 32.0
	_draw_ice_lake()

	# Hot half: cracked dark rock and animated lava.
	_fill(LAVA_LAND, _hot, 16.0, func(cell: Vector2i) -> Rect2:
		return ROCK_TILES[_hash(cell, 9) % ROCK_TILES.size()])
	var frame := int(_t * 6.0) % LAVA_FRAMES
	for pool in _lava_pools:
		var lava := Rect2(LAVA_TILE.position + Vector2(frame * LAVA_FRAME_W, 0), LAVA_TILE.size)
		_fill(LAVA_SHEET, pool, 16.0, func(_cell): return lava)
		# Bubbles that pop on the surface.
		for b in 5:
			var seed_v := Vector2i(int(pool.position.x) + b, int(pool.position.y))
			var life := fmod(_t * 0.8 + b * 0.37, 1.0)
			var spot := pool.position + Vector2(6 + (_hash(seed_v, b) % int(pool.size.x - 12)), 6 + (_hash(seed_v, b + 7) % int(pool.size.y - 12)))
			draw_circle(spot, 1.0 + life * 3.0, Color(1.0, 0.85, 0.3, 0.7 * (1.0 - life)))
		draw_rect(pool, Color(1.0, 0.75, 0.25, 0.5 + 0.3 * sin(_t * 3.0)), false, 2.0)
		draw_rect(pool.grow(4.0), Color(1.0, 0.35, 0.1, 0.12), false, 4.0)

	# Border between the two climates: frost meets heat haze.
	for i in 6:
		var k := i / 6.0
		draw_rect(Rect2(_hot.position.x - 3.0 + i, arena.position.y, 1, arena.size.y), Color(0.9, 0.95, 1.0, 0.5 - k * 0.4))
	for i in 6:
		draw_rect(Rect2(_hot.position.x + i, arena.position.y, 1, arena.size.y), Color(1.0, 0.4, 0.1, 0.3 - i * 0.05))

	# Props sorted by their feet.
	var sorted := _props.duplicate()
	sorted.sort_custom(func(a, b): return _prop_bottom(a) < _prop_bottom(b))
	for prop in sorted:
		var tex: Texture2D = TORCH[int(_t * 10.0) % TORCH.size()] if prop[3] == "torch" else prop[0]
		draw_texture_rect(tex, Rect2(prop[1], tex.get_size() * prop[2]), false)
		if prop[3] == "torch":
			draw_circle(prop[1] + Vector2(8, 6), 14.0, Color(1.0, 0.55, 0.15, 0.08 + 0.04 * sin(_t * 9.0)))

	# Temperature labels so the theme reads at a glance.
	var font := ThemeDB.fallback_font
	draw_string(font, _cold.position + Vector2(6, 12), "-150 °C", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.3, 0.5, 0.8, 0.8))
	draw_string(font, Vector2(_hot.end.x - 50, _hot.position.y + 12), "+120 °C", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.6, 0.3, 0.8))


func _prop_bottom(prop: Array) -> float:
	var tex: Texture2D = prop[0] if prop[0] != null else TORCH[0]
	return prop[1].y + tex.get_size().y * prop[2]


func _draw_ice_lake() -> void:
	var cols := int(_ice_lake.size.x / 32.0)
	var rows := int(_ice_lake.size.y / 32.0)
	for r in rows:
		for c in cols:
			var row_kind := 0 if r == 0 else (2 if r == rows - 1 else 1)
			var col_kind := 0 if c == 0 else (2 if c == cols - 1 else 1)
			draw_texture(ICE[row_kind * 3 + col_kind], _ice_lake.position + Vector2(c, r) * 32.0)
