extends Node2D
## Lobby (first screen): play, language (Español / English), music on/off and
## volume. Settings are saved (GameData.save_settings) so they stay next time.
## Keys: UP/DOWN choose, LEFT/RIGHT change, ENTER confirm. Mouse/touch: tap a
## row; on the language and volume rows tap the < or > side.

const W := 640.0
const H := 360.0
const BACKGROUND := preload("res://assets/backgrounds/para_ocean.png")
const ROWS := ["play", "lang", "music", "volume"]
const ROW_SIZE := Vector2(240, 28)
const ROW_TOP := 168.0
const ROW_GAP := 36.0

var _font: Font
var _t: float = 0.0
var _selected: int = 0
var _leaving: bool = false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_font = ThemeDB.fallback_font
	get_tree().paused = false


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or _t < 0.3:
		return
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		var pos := get_global_mouse_position()
		for i in ROWS.size():
			var rect := _row_rect(i)
			if rect.has_point(pos):
				_selected = i
				var side := -1 if pos.x < rect.position.x + rect.size.x * 0.3 else (1 if pos.x > rect.end.x - rect.size.x * 0.3 else 0)
				_activate(i, side)
		return
	if event.is_action_pressed("move_up"):
		_selected = posmod(_selected - 1, ROWS.size())
	elif event.is_action_pressed("move_down"):
		_selected = posmod(_selected + 1, ROWS.size())
	elif event.is_action_pressed("move_left"):
		_activate(_selected, -1)
	elif event.is_action_pressed("move_right"):
		_activate(_selected, 1)
	elif event.is_action_pressed("confirm"):
		_activate(_selected, 0)


## side: -1 left, 1 right, 0 the row itself (ENTER / tap in the middle).
func _activate(i: int, side: int) -> void:
	match ROWS[i]:
		"play":
			if side == 0:
				_play()
		"lang":
			GameData.set_lang("en" if GameData.lang == "es" else "es")
		"music":
			Music.toggle()
		"volume":
			if side == 0:
				side = 1 if GameData.music_volume < 1.0 else -10
			Music.change_volume(side)


func _play() -> void:
	_leaving = true
	GameData.chapter = 0
	get_tree().change_scene_to_file.call_deferred("res://scenes/intro.tscn")


func _row_rect(i: int) -> Rect2:
	return Rect2(Vector2((W - ROW_SIZE.x) / 2.0, ROW_TOP + i * ROW_GAP), ROW_SIZE)


func _row_text(i: int) -> String:
	match ROWS[i]:
		"play":
			return GameData.t("JUGAR", "PLAY")
		"lang":
			return GameData.t("Idioma:  Español", "Language:  English")
		"music":
			var on := GameData.music_on
			return GameData.t("Música:  " + ("Sí" if on else "No"), "Music:  " + ("On" if on else "Off"))
		"volume":
			return GameData.t("Volumen:  %d%%", "Volume:  %d%%") % roundi(GameData.music_volume * 100.0)
	return ""


# --- drawing --------------------------------------------------------------------

func _draw() -> void:
	draw_texture_rect(BACKGROUND, Rect2(0, 0, W, H), false)
	# Darker at the bottom so the menu reads well.
	for b in 8:
		draw_rect(Rect2(0, 200 + b * 20, W, 20), Color(0.01, 0.03, 0.08, 0.08 + b * 0.07))

	# Title.
	var title := "BIG HERO HACKATHON 2026"
	draw_string(_font, Vector2(2, 44), title, HORIZONTAL_ALIGNMENT_CENTER, W, 30, Color(0.02, 0.05, 0.12, 0.7))
	draw_string(_font, Vector2(0, 42), title, HORIZONTAL_ALIGNMENT_CENTER, W, 30, Color.WHITE)
	draw_string(_font, Vector2(0, 62), GameData.t("Cinco amigos. Cinco planetas. Un solo equipo.", "Five friends. Five planets. One team."),
		HORIZONTAL_ALIGNMENT_CENTER, W, 11, Color(0.92, 1.0, 0.95))

	# The five planets floating over the sea.
	for i in GameData.planets.size():
		var pos := Vector2(W / 2.0 + (i - 2) * 64.0, 104.0 + sin(_t * 1.5 + i) * 3.0)
		var tex := GameData.planet_texture(i)
		if tex != null:
			draw_texture_rect(tex, GameData.planet_rect(i, pos, 17.0), false)
		else:
			draw_circle(pos, 17.0, GameData.planets[i].color)
		draw_string(_font, pos + Vector2(-40, 30), GameData.planets[i].name, HORIZONTAL_ALIGNMENT_CENTER, 80, 8, Color(1, 1, 1, 0.8))

	# Menu.
	for i in ROWS.size():
		var rect := _row_rect(i)
		var chosen := i == _selected
		var play: bool = ROWS[i] == "play"
		var fill := Color(0.12, 0.45, 0.4) if play else Color(0.05, 0.1, 0.18)
		draw_rect(rect, fill.lightened(0.15) if chosen else Color(fill, 0.85))
		draw_rect(rect, Color(1, 1, 1, 0.9 if chosen else 0.3), false, 1.0)
		draw_string(_font, rect.position + Vector2(0, 19), _row_text(i), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14 if play else 11, Color.WHITE)
		if ROWS[i] in ["lang", "volume"]:
			var arrow := Color(1, 1, 1, 0.8 if chosen else 0.35)
			draw_string(_font, rect.position + Vector2(10, 19), "<", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, arrow)
			draw_string(_font, rect.position + Vector2(rect.size.x - 18, 19), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, arrow)
		if ROWS[i] == "volume":
			var bar := Rect2(rect.position + Vector2(40, 23), Vector2(rect.size.x - 80, 2))
			draw_rect(bar, Color(1, 1, 1, 0.15))
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * GameData.music_volume, 2)), Color(0.5, 1.0, 0.8, 0.9 if GameData.music_on else 0.3))

	# The five friends on the left, ready for launch.
	for i in GameData.characters.size():
		var feet := Vector2(40 + i * 30, 336 - absf(sin(_t * 2.0 + i)) * 1.5)
		if not CharacterSprites.draw(self, i, feet, 30.0, CharacterSprites.ROW_DOWN, 0):
			draw_rect(Rect2(feet - Vector2(6, 30), Vector2(12, 30)), GameData.characters[i].color)

	if GameData.music_on:
		draw_string(_font, Vector2(12, 354), GameData.t("Música: ", "Music: ") + Music.track_name() + "  (DavidKBD)",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.45))
	draw_string(_font, Vector2(0, 354), GameData.t("ARRIBA/ABAJO elegir   IZQ/DER cambiar   ENTER aceptar", "UP/DOWN choose   LEFT/RIGHT change   ENTER accept"),
		HORIZONTAL_ALIGNMENT_RIGHT, W - 12, 8, Color(1, 1, 1, 0.45))

	var fade := 1.0 - clampf(_t / 0.6, 0.0, 1.0)
	if fade > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, fade))
