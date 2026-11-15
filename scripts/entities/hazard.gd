class_name Hazard
extends Node2D
## Something that hurts the player on contact (group "hazards"). Always drawn
## with a pulsing RED OUTLINE so the player knows to stay away.
## "shard" (Zero): sharp space junk that drifts and spins, bouncing off the edges.
## "static" (Draugr): a cloud of radio noise that wanders slowly.
## Real link: orbital debris is a real danger for CubeSats; on Draugr, radio
## noise is what drowns the beacons.

@export var kind: String = "shard"
@export var damage: int = 15
@export var radius: float = 9.0
@export var speed: float = 35.0
## Seconds between hits.
@export var hit_cooldown: float = 1.0

var arena: Rect2 = Rect2(0, 0, 640, 360)
var _velocity: Vector2
var _cooldown: float = 0.0
var _phase: float = randf() * TAU
var _points: PackedVector2Array


func _ready() -> void:
	add_to_group("hazards")
	_velocity = Vector2.from_angle(randf() * TAU) * speed
	if kind == "static":
		radius = 14.0
	# Jagged outline for the shard (same shape every frame).
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x * 13.0 + position.y * 7.0)
	for i in 7:
		var r := radius * (0.55 if i % 2 == 1 else rng.randf_range(0.9, 1.25))
		_points.append(Vector2.from_angle(TAU * i / 7.0) * r)


func _physics_process(delta: float) -> void:
	_phase += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	if kind == "static":
		# Wanders: turns a little all the time.
		_velocity = _velocity.rotated(sin(_phase * 0.7) * delta * 1.5)
	position += _velocity * delta
	var margin := radius + 4.0
	if position.x < arena.position.x + margin or position.x > arena.end.x - margin:
		_velocity.x = -_velocity.x
	if position.y < arena.position.y + margin or position.y > arena.end.y - margin:
		_velocity.y = -_velocity.y
	position = position.clamp(arena.position + Vector2.ONE * margin, arena.end - Vector2.ONE * margin)

	for player in get_tree().get_nodes_in_group("player"):
		if _cooldown == 0.0 and global_position.distance_to(player.global_position) < radius + 7.0 \
				and player.has_method("take_damage"):
			player.take_damage(damage)
			_cooldown = hit_cooldown
	queue_redraw()


func _draw() -> void:
	var pulse := 0.6 + 0.4 * sin(_phase * 6.0)
	var red := Color(1.0, 0.15, 0.15, pulse)
	if kind == "static":
		# Noise cloud: flickering bars inside a red circle.
		draw_circle(Vector2.ZERO, radius, Color(0.15, 0.1, 0.12, 0.55))
		for i in 7:
			var y := -radius + 3.0 + i * (radius * 2.0 - 6.0) / 6.0
			var half := sqrt(maxf(radius * radius - y * y, 0.0)) * (0.5 + 0.5 * absf(sin(_phase * 17.0 + i * 2.3)))
			draw_line(Vector2(-half, y), Vector2(half, y), Color(0.85, 0.85, 0.9, 0.7), 1.0)
		draw_arc(Vector2.ZERO, radius + 1.0, 0.0, TAU, 24, red, 2.0)
		return
	# Spinning shard of metal with a red outline.
	draw_set_transform(Vector2.ZERO, _phase * 2.0)
	draw_colored_polygon(_points, Color(0.55, 0.58, 0.65))
	var outline := _points.duplicate()
	outline.append(_points[0])
	draw_polyline(outline, red, 2.0)
	draw_line(_points[0] * 0.3, _points[2] * 0.5, Color(0.85, 0.88, 0.95), 1.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)
