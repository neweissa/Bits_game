extends CanvasLayer
## Pause menu (autoload "PauseMenu"). Works in any scene that is in the group
## "pausable" (planets, missions, travel). ESC or P pauses; on phones and with
## the mouse there is a "II" button in the top-right corner.
## Options: continue, music on/off, volume, language, restart this screen,
## back to the lobby. LEFT/RIGHT change the volume and the language.

const W := 640.0
const H := 360.0
const BUTTON := Rect2(W - 34, 2, 30, 16)
const OPTIONS := ["continue", "music", "volume", "lang", "restart", "lobby"]
const OPTION_SIZE := Vector2(220, 24)

var _canvas: Node2D
var _font: Font
var _selected: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_font = ThemeDB.fallback_font
	_canvas = Node2D.new()
	add_child(_canvas)
	_canvas.draw.connect(_draw_menu)
	GameData.add_action("pause", [KEY_P, KEY_ESCAPE])


func _process(_delta: float) -> void:
	_canvas.queue_redraw()


func _pausable() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.is_in_group("pausable")


func _unhandled_input(event: InputEvent) -> void:
	if not _pausable():
		return
	var paused := get_tree().paused
	var click: bool = event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
	var pos := _canvas.get_global_mouse_position()

	if event.is_action_pressed("pause") or (click and BUTTON.has_point(pos)):
		_set_paused(not paused)
		get_viewport().set_input_as_handled()
		return
	if not paused:
		return
	if event.is_action_pressed("move_up"):
		_selected = posmod(_selected - 1, OPTIONS.size())
	elif event.is_action_pressed("move_down"):
		_selected = posmod(_selected + 1, OPTIONS.size())
	elif event.is_action_pressed("move_left"):
		_choose(_selected, -1)
	elif event.is_action_pressed("move_right"):
		_choose(_selected, 1)
	elif event.is_action_pressed("confirm"):
		_choose(_selected)
	elif click:
		for i in OPTIONS.size():
			var rect := _option_rect(i)
			if rect.has_point(pos):
				_selected = i
				_choose(i, -1 if pos.x < rect.get_center().x - 50.0 else (1 if pos.x > rect.get_center().x + 50.0 else 0))
	get_viewport().set_input_as_handled()


func _set_paused(value: bool) -> void:
	get_tree().paused = value
	_selected = 0


## side: -1 / 1 for LEFT / RIGHT (or tapping the sides of a row), 0 for ENTER.
func _choose(i: int, side: int = 0) -> void:
	match OPTIONS[i]:
		"continue":
			if side == 0:
				_set_paused(false)
		"music":
			Music.toggle()
		"volume":
			Music.change_volume(side if side != 0 else 1)
		"lang":
			GameData.set_lang("en" if GameData.lang == "es" else "es")
		"restart":
			if side == 0:
				_set_paused(false)
				get_tree().reload_current_scene()
		"lobby":
			if side == 0:
				_set_paused(false)
				GameData.chapter = 0
				get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _option_text(i: int) -> String:
	match OPTIONS[i]:
		"continue":
			return GameData.t("Continuar", "Resume")
		"music":
			return GameData.t("Música: ", "Music: ") + (GameData.t("Sí", "On") if GameData.music_on else GameData.t("No", "Off"))
		"volume":
			return "<  " + GameData.t("Volumen", "Volume") + ": %d%%  >" % roundi(GameData.music_volume * 100.0)
		"lang":
			return "<  " + GameData.t("Idioma: Español", "Language: English") + "  >"
		"restart":
			return GameData.t("Reiniciar esta parte", "Restart this part")
		"lobby":
			return GameData.t("Volver al inicio", "Back to the lobby")
	return ""


func _option_rect(i: int) -> Rect2:
	return Rect2(Vector2((W - OPTION_SIZE.x) / 2.0, 128 + i * 32), OPTION_SIZE)


func _draw_menu() -> void:
	if not _pausable():
		return
	if not get_tree().paused:
		# Small pause button.
		_canvas.draw_rect(BUTTON, Color(0, 0, 0, 0.5))
		_canvas.draw_rect(BUTTON, Color(1, 1, 1, 0.4), false, 1.0)
		_canvas.draw_rect(Rect2(BUTTON.position + Vector2(11, 4), Vector2(3, 8)), Color(1, 1, 1, 0.8))
		_canvas.draw_rect(Rect2(BUTTON.position + Vector2(17, 4), Vector2(3, 8)), Color(1, 1, 1, 0.8))
		return
	_canvas.draw_rect(Rect2(0, 0, W, H), Color(0.01, 0.01, 0.04, 0.8))
	_canvas.draw_string(_font, Vector2(0, 90), GameData.t("PAUSA", "PAUSED"), HORIZONTAL_ALIGNMENT_CENTER, W, 28, Color.WHITE)
	_canvas.draw_string(_font, Vector2(0, 112), GameData.t("ESC / P para continuar", "ESC / P to resume"), HORIZONTAL_ALIGNMENT_CENTER, W, 9, Color(1, 1, 1, 0.5))
	for i in OPTIONS.size():
		var rect := _option_rect(i)
		var chosen := i == _selected
		_canvas.draw_rect(rect, Color(0.16, 0.2, 0.34) if chosen else Color(0.06, 0.08, 0.14))
		_canvas.draw_rect(rect, Color(1, 1, 1, 0.8 if chosen else 0.25), false, 1.0)
		_canvas.draw_string(_font, rect.position + Vector2(0, 17), _option_text(i), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, Color.WHITE)
