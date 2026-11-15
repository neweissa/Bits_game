class_name Debris
extends Node2D
## Floating rock on planet Zero (no gravity): drifts forever, spins slowly and
## bounces off the arena edges. Uses the small rocks of assets/tilesets/zero.

const ROCKS := preload("res://assets/tilesets/zero/rocks.png")

var arena: Rect2 = Rect2(0, 0, 640, 360)
var _velocity: Vector2 = Vector2.ZERO
var _spin: float = 0.0
var _size: float = 8.0
var _region: Rect2
var _phase: float = 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_velocity = Vector2.from_angle(randf() * TAU) * randf_range(10.0, 30.0)
	_spin = randf_range(-1.0, 1.0)
	_region = Rect2((randi() % 4) * 16, (randi() % 2) * 16, 16, 16)
	_phase = randf() * TAU


func _process(delta: float) -> void:
	position += _velocity * delta
	_phase += delta * 2.0
	if position.x < arena.position.x + _size or position.x > arena.end.x - _size:
		_velocity.x = -_velocity.x
	if position.y < arena.position.y + _size or position.y > arena.end.y - _size:
		_velocity.y = -_velocity.y
	queue_redraw()


func _draw() -> void:
	# Shadow on the ground, rock floating and turning above it.
	draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, -4 + sin(_phase) * 2.0), _phase * _spin * 0.3, Vector2.ONE)
	draw_texture_rect_region(ROCKS, Rect2(-8, -8, 16, 16), _region)
