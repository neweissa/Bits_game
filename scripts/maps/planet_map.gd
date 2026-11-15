class_name PlanetMap
extends Node2D
## Base for the planet maps (one per planet). A map draws the ground and props
## inside the arena and adds collisions for the props. planet.gd asks it where
## things may spawn (is_free) and where enemies may move (walkable).

var arena: Rect2 = Rect2(16, 70, 608, 268)
## Rects that block walking (props). Used for collisions and to avoid spawning
## items or enemies inside props.
var blocked: Array[Rect2] = []
## Points that must stay clear (landing spot, aliens...). Set before add_child().
var keep_clear: Array[Vector2] = []

var _t: float = 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build()
	_build_collisions()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


## Override: create the layout (fill `blocked`, choose tiles...).
func _build() -> void:
	pass


## Area where enemies and items may move.
func walkable() -> Rect2:
	return arena


func is_free(point: Vector2, margin: float = 12.0) -> bool:
	if not walkable().grow(-margin).has_point(point):
		return false
	for rect in blocked:
		if rect.grow(margin).has_point(point):
			return false
	return true


## True if a prop of this size at `rect` would not cover a keep_clear point.
func _clear_of_points(rect: Rect2, margin: float = 26.0) -> bool:
	for point in keep_clear:
		if rect.grow(margin).has_point(point):
			return false
	return true


func _extra_walls() -> Array[Rect2]:
	return []


func _build_collisions() -> void:
	var body := StaticBody2D.new()
	add_child(body)
	var rects: Array[Rect2] = _extra_walls()
	rects.append_array(blocked)
	for rect in rects:
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = rect.get_center()
		body.add_child(collision)


## Fills `area` with tiles of `size` px taken from `texture` (regions picked by
## `pick(cell)` so the choice stays the same every frame). Clips at the area edge.
func _fill(texture: Texture2D, area: Rect2, size: float, pick: Callable) -> void:
	var y := area.position.y
	var row := 0
	while y < area.end.y:
		var x := area.position.x
		var col := 0
		var h := minf(size, area.end.y - y)
		while x < area.end.x:
			var w := minf(size, area.end.x - x)
			var region: Rect2 = pick.call(Vector2i(col, row))
			draw_texture_rect_region(texture, Rect2(x, y, w, h), Rect2(region.position, Vector2(w, h) * region.size.x / size))
			x += size
			col += 1
		y += size
		row += 1


## Stable pseudo-random number for a cell (same value every frame).
func _hash(cell: Vector2i, salt: int = 0) -> int:
	return absi((cell.x * 73856093) ^ (cell.y * 19349663) ^ (salt * 83492791))
