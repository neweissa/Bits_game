class_name TouchControls
extends CanvasLayer
## On-screen controls for phones: a virtual joystick on the left half of the
## screen and a power button on the right. They press the same input actions
## as the keyboard (move_*, ability), so the astronauts need no changes.

const STICK_RADIUS := 34.0
const BUTTON_CENTER := Vector2(584, 300)
const BUTTON_RADIUS := 30.0
const IDLE_STICK_CENTER := Vector2(70, 290)

var button_label: String = "E"
var button_color: Color = Color.WHITE

var _canvas: Node2D
var _stick_finger: int = -1
var _stick_center: Vector2 = IDLE_STICK_CENTER
var _stick_knob: Vector2 = IDLE_STICK_CENTER
var _button_finger: int = -1


func _ready() -> void:
	layer = 20
	_canvas = Node2D.new()
	add_child(_canvas)
	_canvas.draw.connect(_draw_controls)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(BUTTON_CENTER) <= BUTTON_RADIUS * 1.4:
				_button_finger = event.index
				Input.action_press("ability")
			elif event.position.x < 320.0 and _stick_finger == -1:
				_stick_finger = event.index
				_stick_center = event.position
				_stick_knob = event.position
		else:
			if event.index == _button_finger:
				_button_finger = -1
				Input.action_release("ability")
			elif event.index == _stick_finger:
				_release_stick()
		_canvas.queue_redraw()
	elif event is InputEventScreenDrag and event.index == _stick_finger:
		var offset: Vector2 = (event.position - _stick_center).limit_length(STICK_RADIUS)
		_stick_knob = _stick_center + offset
		_apply_stick(offset / STICK_RADIUS)
		_canvas.queue_redraw()


func _exit_tree() -> void:
	_release_stick()
	Input.action_release("ability")


func _release_stick() -> void:
	_stick_finger = -1
	_stick_center = IDLE_STICK_CENTER
	_stick_knob = IDLE_STICK_CENTER
	_apply_stick(Vector2.ZERO)


func _apply_stick(value: Vector2) -> void:
	# A small dead zone so a resting thumb does not drift.
	if value.length() < 0.2:
		value = Vector2.ZERO
	_set_axis("move_left", "move_right", value.x)
	_set_axis("move_up", "move_down", value.y)


func _set_axis(negative: String, positive: String, amount: float) -> void:
	if amount < 0.0:
		Input.action_press(negative, -amount)
		Input.action_release(positive)
	elif amount > 0.0:
		Input.action_press(positive, amount)
		Input.action_release(negative)
	else:
		Input.action_release(negative)
		Input.action_release(positive)


func _draw_controls() -> void:
	_canvas.draw_circle(_stick_center, STICK_RADIUS, Color(1, 1, 1, 0.12))
	_canvas.draw_arc(_stick_center, STICK_RADIUS, 0.0, TAU, 32, Color(1, 1, 1, 0.35), 1.0)
	_canvas.draw_circle(_stick_knob, 14.0, Color(1, 1, 1, 0.4))

	var pressed := _button_finger != -1
	_canvas.draw_circle(BUTTON_CENTER, BUTTON_RADIUS, Color(button_color, 0.55 if pressed else 0.3))
	_canvas.draw_arc(BUTTON_CENTER, BUTTON_RADIUS, 0.0, TAU, 32, Color(button_color, 0.8), 1.5)
	_canvas.draw_string(ThemeDB.fallback_font, BUTTON_CENTER + Vector2(-BUTTON_RADIUS, 4), button_label,
		HORIZONTAL_ALIGNMENT_CENTER, BUTTON_RADIUS * 2.0, 9, Color.WHITE)
