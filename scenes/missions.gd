extends Node2D
## The three missions of the current planet, played after its objective.
## Questions and risks come from Supabase (see MissionData). Wrong answers do not
## fail the mission: they show why and let you try again.
## Keys: UP/DOWN (or W/S) choose, LEFT/RIGHT (or A/D) turn dials, ENTER/SPACE
## confirm. Mouse and touch: tap an option or the - / + / OK buttons.

const W := 640.0
const H := 360.0
const OPTION_X := 60.0
const OPTION_W := W - 120.0
const OPTION_H := 24.0
const BUTTON_MINUS := Rect2(150, 236, 60, 28)
const BUTTON_PLUS := Rect2(430, 236, 60, 28)
const BUTTON_OK := Rect2(270, 236, 100, 28)

var _font: Font
var _t: float = 0.0
var _index: int = 0
var _mission: Dictionary = {}
var _selected: int = 0
var _value: int = 0
var _tries: int = 0
## "playing" -> "wrong" (try again) or "right" (continue)
var _state: String = "playing"
var _state_t: float = 0.0
var _feedback: String = ""


func _ready() -> void:
	add_to_group("pausable")
	_font = ThemeDB.fallback_font
	_index = clampi(GameData.mission_index, 0, MissionData.count(GameData.chapter) - 1)
	# New random questions from the database every time.
	MissionData.new_run(GameData.chapter)
	GameData.mission_index = 0
	_load_mission()


func _process(delta: float) -> void:
	_t += delta
	_state_t += delta
	queue_redraw()


func _load_mission() -> void:
	_mission = MissionData.build(GameData.chapter, _index)
	_selected = 0
	_tries = 0
	_state = "playing"
	_state_t = 0.0
	_feedback = ""
	match _mission.type:
		"tune":
			_value = _mission.start
		"cipher":
			_value = 0


# --- input ----------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _state_t < 0.25:
		return  # Ignore the tap/press that opened this screen or answered.
	if _state != "playing":
		var tapped: bool = event is InputEventMouseButton and event.is_pressed()
		if event.is_action_pressed("confirm") or tapped:
			if _state == "right":
				_next()
			else:
				_state = "playing"
				_state_t = 0.0
		return

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		_click(get_global_mouse_position())
		return
	if _has_options():
		if event.is_action_pressed("move_up"):
			_selected = posmod(_selected - 1, _mission.options.size())
		elif event.is_action_pressed("move_down"):
			_selected = posmod(_selected + 1, _mission.options.size())
		elif event.is_action_pressed("confirm"):
			_answer_option(_selected)
	else:
		if event.is_action_pressed("move_left", true):
			_turn(-1)
		elif event.is_action_pressed("move_right", true):
			_turn(1)
		elif event.is_action_pressed("confirm"):
			_check_dial()


func _click(pos: Vector2) -> void:
	if _has_options():
		for i in _mission.options.size():
			if _option_rect(i).has_point(pos):
				_selected = i
				_answer_option(i)
				return
	else:
		if BUTTON_MINUS.has_point(pos):
			_turn(-1)
		elif BUTTON_PLUS.has_point(pos):
			_turn(1)
		elif BUTTON_OK.has_point(pos):
			_check_dial()


func _has_options() -> bool:
	return _mission.has("options")


func _turn(direction: int) -> void:
	if _mission.type == "tune":
		_value = clampi(_value + direction * int(_mission.step), int(_mission.min), int(_mission.max))
	else:
		_value = posmod(_value + direction, 26)


func _answer_option(i: int) -> void:
	if _mission.options[i] == _mission.answer:
		_right(_mission.get("explanation", ""))
	else:
		_wrong(_mission.get("explanation", "") if _mission.type == "risk" else GameData.t("Esa no es. Piénsalo otra vez.", "That is not it. Think again."))


func _check_dial() -> void:
	if _mission.type == "tune":
		if _value == int(_mission.target):
			_right(_mission.get("explanation", ""))
		else:
			_wrong(GameData.t("Todavía no. Sigue ajustando.", "Not yet. Keep adjusting."))
	else:
		# The shift that decodes the beacon is the one it was encoded with.
		if _value == int(_mission.shift):
			_right(_mission.get("explanation", ""))
		else:
			_wrong(GameData.t("El mensaje sigue sin sentido. Sigue corriendo las letras.", "The message still makes no sense. Keep shifting the letters."))


func _right(text: String) -> void:
	_state = "right"
	_state_t = 0.0
	_feedback = text


func _wrong(text: String) -> void:
	_tries += 1
	_state = "wrong"
	_state_t = 0.0
	_feedback = text


func _next() -> void:
	_index += 1
	if _index < MissionData.count(GameData.chapter):
		_load_mission()
		return
	# Planet done: a "¿Sabías que?" card, then engineer the ship and travel on.
	GameData.chapter += 1
	get_tree().change_scene_to_file("res://scenes/fact.tscn")


# --- drawing --------------------------------------------------------------------

func _draw() -> void:
	var planet := GameData.current_planet()
	var character := GameData.current_character()
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.02, 0.06))

	# Header: planet image, name, and the three missions as progress.
	var tex := GameData.planet_texture(GameData.chapter)
	if tex != null:
		draw_texture_rect(tex, GameData.planet_rect(GameData.chapter, Vector2(34, 32), 18.0), false)
	draw_string(_font, Vector2(62, 26), GameData.t("MISIONES EN %s", "MISSIONS ON %s") % planet.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, planet.color)
	draw_string(_font, Vector2(62, 42), "%s  -  %s" % [character.name, GameData.txt(character, "discipline")], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, character.color)
	for i in MissionData.count(GameData.chapter):
		var box := Rect2(W - 132 + i * 28, 18, 20, 20)
		var color: Color = character.color
		draw_rect(box, color if i < _index else Color(color, 0.15))
		draw_rect(box, Color(1, 1, 1, 0.9 if i == _index else 0.3), false, 1.0)
		draw_string(_font, box.position + Vector2(0, 14), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 20, 10, Color.WHITE)

	draw_string(_font, Vector2(40, 72), GameData.t("MISIÓN %d: %s", "MISSION %d: %s") % [_index + 1, _mission.title], HORIZONTAL_ALIGNMENT_LEFT, W - 80, 12, Color(1.0, 0.9, 0.5))

	match _mission.type:
		"tune":
			_draw_tune()
		"cipher":
			_draw_cipher()
		_:
			_draw_question()

	draw_string(_font, Vector2(0, 352), GameData.t("Fuente: ", "Source: ") + str(_mission.get("source", "")), HORIZONTAL_ALIGNMENT_LEFT, W, 8, Color(1, 1, 1, 0.35))
	if _state != "playing":
		_draw_feedback()


func _draw_question() -> void:
	draw_multiline_string(_font, Vector2(40, 94), _mission.question, HORIZONTAL_ALIGNMENT_LEFT, W - 80, 11, -1, Color.WHITE)
	for i in _mission.options.size():
		var rect := _option_rect(i)
		var chosen: bool = i == _selected
		draw_rect(rect, Color(0.08, 0.1, 0.18) if not chosen else Color(0.16, 0.2, 0.34))
		draw_rect(rect, Color(1, 1, 1, 0.8 if chosen else 0.25), false, 1.0)
		draw_string(_font, rect.position + Vector2(10, 16), "%s  %s" % ["ABCD"[i], _mission.options[i]],
			HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, 10, Color.WHITE)
	draw_string(_font, Vector2(0, 336), GameData.t("ARRIBA/ABAJO elegir   ENTER confirmar   o toca una opción", "UP/DOWN choose   ENTER confirm   or tap an option"),
		HORIZONTAL_ALIGNMENT_CENTER, W, 8, Color(1, 1, 1, 0.45))


func _option_rect(i: int) -> Rect2:
	var top := 164.0 if _mission.type == "risk" else 136.0
	return Rect2(OPTION_X, top + i * (OPTION_H + 6.0), OPTION_W, OPTION_H)


func _draw_tune() -> void:
	draw_multiline_string(_font, Vector2(40, 94), _mission.instructions, HORIZONTAL_ALIGNMENT_LEFT, W - 80, 11, -1, Color.WHITE)
	# Dial: a bar with the current value; static noise gets calmer near the target.
	var bar := Rect2(80, 170, W - 160, 10)
	draw_rect(bar, Color(0.12, 0.14, 0.22))
	var k := inverse_lerp(float(_mission.min), float(_mission.max), float(_value))
	var knob_x := bar.position.x + bar.size.x * k
	draw_rect(Rect2(knob_x - 3, bar.position.y - 6, 6, 22), Color(1.0, 0.9, 0.5))
	var off := absf(_value - float(_mission.target)) / absf(float(_mission.max) - float(_mission.min))
	for n in 40:
		var x := bar.position.x + n * bar.size.x / 40.0
		var amp := 2.0 + off * 30.0 * absf(sin(_t * 17.0 + n * 1.7))
		draw_line(Vector2(x, 150 - amp), Vector2(x, 150 + amp), Color(0.4, 1.0, 0.6, 0.6), 1.0)
	draw_string(_font, Vector2(0, 214), "%s: %d%s" % [_mission.label, _value, _mission.unit], HORIZONTAL_ALIGNMENT_CENTER, W, 16, Color.WHITE)
	_draw_dial_buttons()


func _draw_cipher() -> void:
	draw_multiline_string(_font, Vector2(40, 94), _mission.instructions, HORIZONTAL_ALIGNMENT_LEFT, W - 80, 11, -1, Color.WHITE)
	draw_string(_font, Vector2(0, 140), GameData.t("SEÑAL:  ", "SIGNAL:  ") + str(_mission.encrypted), HORIZONTAL_ALIGNMENT_CENTER, W, 14, Color(0.4, 1.0, 0.45))
	var decoded := MissionData.caesar(_mission.encrypted, -_value)
	draw_string(_font, Vector2(0, 172), decoded, HORIZONTAL_ALIGNMENT_CENTER, W, 16, Color.WHITE)
	draw_string(_font, Vector2(0, 200), GameData.t("Correr letras: %d", "Shift letters: %d") % _value, HORIZONTAL_ALIGNMENT_CENTER, W, 11, Color(1, 1, 1, 0.7))
	_draw_dial_buttons()


func _draw_dial_buttons() -> void:
	for pair in [[BUTTON_MINUS, "-"], [BUTTON_OK, "OK"], [BUTTON_PLUS, "+"]]:
		var rect: Rect2 = pair[0]
		draw_rect(rect, Color(0.08, 0.1, 0.18))
		draw_rect(rect, Color(1, 1, 1, 0.5), false, 1.0)
		draw_string(_font, rect.position + Vector2(0, 19), pair[1], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14, Color.WHITE)
	draw_string(_font, Vector2(0, 336), GameData.t("IZQUIERDA/DERECHA ajustar   ENTER confirmar   o toca - / + / OK", "LEFT/RIGHT adjust   ENTER confirm   or tap - / + / OK"),
		HORIZONTAL_ALIGNMENT_CENTER, W, 8, Color(1, 1, 1, 0.45))


func _draw_feedback() -> void:
	var right := _state == "right"
	var panel := Rect2(40, 254, W - 80, 76)
	draw_rect(panel, Color(0.03, 0.08, 0.05, 0.96) if right else Color(0.1, 0.03, 0.03, 0.96))
	draw_rect(panel, Color(0.5, 1.0, 0.6) if right else Color(1.0, 0.4, 0.4), false, 1.0)
	var title := GameData.t("¡CORRECTO!", "CORRECT!") if right else GameData.t("INTÉNTALO DE NUEVO", "TRY AGAIN")
	draw_string(_font, panel.position + Vector2(12, 18), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
		Color(0.5, 1.0, 0.6) if right else Color(1.0, 0.5, 0.5))
	draw_multiline_string(_font, panel.position + Vector2(12, 34), _feedback, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 24, 9, 3, Color.WHITE)
	if _state_t > 0.25:
		var last := _index >= MissionData.count(GameData.chapter) - 1
		var next := GameData.t("Planeta completado. ENTER para ir a la nave", "Planet complete. ENTER to go to the ship") if last else GameData.t("ENTER o toca para la siguiente misión", "ENTER or tap for the next mission")
		var hint := next if right else GameData.t("ENTER o toca para volver a intentar", "ENTER or tap to try again")
		draw_string(_font, panel.position + Vector2(0, 70), hint, HORIZONTAL_ALIGNMENT_RIGHT, panel.size.x - 12, 8, Color(1, 1, 1, 0.6))
