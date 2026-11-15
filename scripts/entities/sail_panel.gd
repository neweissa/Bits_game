class_name SailPanel
extends Node2D
## Solar panel floating on planet Zero. Bels can only grab it while in zero
## gravity (planet.gd checks the distance). Drawn like a CubeSat deployable
## panel: blue solar cells in a gold frame, a hinge in the middle, slowly
## turning while it floats. Real link: ChargerSat-1's deployable panels almost
## double its power, and LightSail's 32 m2 sail moves with sunlight.

const CELL := Vector2(5, 6)
const COLS := 5
const ROWS := 2

var collected: bool = false
var _phase: float = randf() * TAU


func _process(delta: float) -> void:
	_phase += delta * 2.0
	queue_redraw()


func _draw() -> void:
	if collected:
		return
	var y := sin(_phase) * 3.0
	# Shadow on the ground.
	draw_set_transform(Vector2(0, 14), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 12.0 - y, Color(0, 0, 0, 0.25))
	# The panel tilts a little while it floats (it looks like it turns in 3D).
	var tilt := 0.75 + 0.25 * cos(_phase * 0.5)
	draw_set_transform(Vector2(0, y), sin(_phase * 0.5) * 0.15, Vector2(1.0, tilt))
	var wing := Vector2(COLS * CELL.x + 2, ROWS * CELL.y + 2)
	for side in [-1.0, 1.0]:
		var origin := Vector2(3.0 if side > 0 else -3.0 - wing.x, -wing.y / 2.0)
		draw_rect(Rect2(origin, wing), Color(0.85, 0.68, 0.25))
		for c in COLS:
			for r in ROWS:
				var cell := Rect2(origin + Vector2(1 + c * CELL.x, 1 + r * CELL.y), CELL - Vector2(1, 1))
				var shade := 0.85 + 0.15 * sin(_phase * 1.5 + c * 0.6 + r)
				draw_rect(cell, Color(0.12, 0.25, 0.62) * shade)
				draw_line(cell.position + Vector2(1, 1), cell.position + Vector2(cell.size.x - 1, 1), Color(0.5, 0.7, 1.0, 0.5), 1.0)
	# Hinge / body in the middle.
	draw_rect(Rect2(-3, -5, 6, 10), Color(0.8, 0.82, 0.88))
	draw_rect(Rect2(-1, -2, 2, 4), Color(0.25, 0.3, 0.4))
	# Glint that sweeps across the cells.
	var sweep := fmod(_phase * 0.4, 1.0) * (wing.x * 2.0 + 20.0) - wing.x - 10.0
	draw_line(Vector2(sweep, -wing.y / 2.0), Vector2(sweep + 4, wing.y / 2.0), Color(1, 1, 1, 0.55), 2.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# Pulsing ring so it is easy to spot.
	draw_arc(Vector2(0, y), 22.0, 0.0, TAU, 24, Color(0.6, 0.85, 1.0, 0.2 + 0.15 * sin(_phase * 2.0)), 1.0)
