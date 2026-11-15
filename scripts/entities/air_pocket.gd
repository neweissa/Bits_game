class_name AirPocket
extends Node2D
## Hidden pocket of trapped air on Fernix (group "heat_sources"). Invisible
## until Ray's infrared finds it; once found it stays marked.
## Real link: trapped air can burst a spacecraft in vacuum.

var found: bool = false
var _glow: float = 0.0


func _ready() -> void:
	add_to_group("heat_sources")
	visible = false


func on_infrared(duration: float) -> void:
	found = true
	visible = true
	_glow = duration


func _process(delta: float) -> void:
	_glow = maxf(0.0, _glow - delta)
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
	if _glow > 0.0:
		draw_circle(Vector2.ZERO, 10.0 + pulse * 3.0, Color(1.0, 0.25, 0.1, 0.35))
		draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.8, 0.2))
	else:
		draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 16, Color(1.0, 0.4, 0.2, 0.7), 1.0)
