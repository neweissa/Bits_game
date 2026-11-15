class_name CharacterSprites
extends RefCounted
## Uses the team's LPC character sheets (64x64 frames, 13 columns) for the five
## astronauts. Each character in GameData has a "sprite" path; if that PNG is not
## in the project yet, everything falls back to the placeholder rectangle.
##
## LPC rows used (same ones as the team's scenes): walk up 8, walk left 9,
## walk down 10, walk right 11. Frame 0 of each row is the standing pose.

const FRAME := 64
const WALK_FRAMES := 9
const ROW_UP := 8
const ROW_LEFT := 9
const ROW_DOWN := 10
const ROW_RIGHT := 11
## The character inside a 64px frame stands with its feet at about y = 62.
const FEET_Y := 62.0

static var _cache: Dictionary = {}


## Texture for character i, or null if that sprite sheet is not in the project.
static func texture(i: int) -> Texture2D:
	if _cache.has(i):
		return _cache[i]
	var path: String = GameData.characters[i].get("sprite", "")
	var tex: Texture2D = null
	if not path.is_empty() and ResourceLoader.exists(path):
		tex = load(path)
	_cache[i] = tex
	return tex


static func has_sprite(i: int) -> bool:
	return texture(i) != null


static func region(row: int, frame: int) -> Rect2:
	return Rect2(frame * FRAME, row * FRAME, FRAME, FRAME)


## Draws character i on `canvas` standing at `feet`, about `height` px tall.
## Returns false (and draws nothing) when there is no sprite for that character.
static func draw(canvas: CanvasItem, i: int, feet: Vector2, height: float, row: int = ROW_DOWN,
		frame: int = 0, alpha: float = 1.0) -> bool:
	var tex := texture(i)
	if tex == null:
		return false
	# The visible body is about 48 of the 64 px, so scale the whole frame up a bit.
	var size := height * FRAME / 48.0
	var scale_k := size / FRAME
	var rect := Rect2(feet.x - size / 2.0, feet.y - FEET_Y * scale_k, size, size)
	canvas.draw_texture_rect_region(tex, rect, region(row, frame), Color(1, 1, 1, alpha))
	return true


## SpriteFrames with walk_up / walk_down / walk_left / walk_right / idle for character i.
static func frames(i: int) -> SpriteFrames:
	var tex := texture(i)
	if tex == null:
		return null
	var sf := SpriteFrames.new()
	sf.remove_animation(&"default")
	var rows := {&"walk_up": ROW_UP, &"walk_left": ROW_LEFT, &"walk_down": ROW_DOWN, &"walk_right": ROW_RIGHT}
	for anim in rows:
		sf.add_animation(anim)
		sf.set_animation_speed(anim, 10.0)
		for f in range(1, WALK_FRAMES):
			sf.add_frame(anim, _atlas(tex, rows[anim], f))
	sf.add_animation(&"idle")
	sf.add_frame(&"idle", _atlas(tex, ROW_DOWN, 0))
	return sf


static func _atlas(tex: Texture2D, row: int, frame: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = region(row, frame)
	return atlas
