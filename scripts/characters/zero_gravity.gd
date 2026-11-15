extends Astronaut
## BELS - ZERO GRAVITY (Propulsion + Attitude)
## E: toggles zero-gravity mode.
##  - Propulsion: you move by thrust and keep drifting by inertia (like a solar sail).
##  - Attitude: the body turns toward where it is going (like gyroscopes).

@export var thrust: float = 220.0
@export var max_speed: float = 180.0
@export var turn_rate: float = 8.0

var zero_gravity: bool = false


func _use_ability() -> void:
	zero_gravity = not zero_gravity
	modulate = Color(0.6, 0.85, 1.0) if zero_gravity else Color.WHITE


func _move(delta: float) -> void:
	var direction := _input_direction()
	if zero_gravity:
		# No friction: you keep sliding.
		velocity += direction * thrust * delta
		velocity = velocity.limit_length(max_speed)
		if velocity.length() > 5.0:
			# The rectangle stands "up", so its forward is -Y: offset by 90 degrees.
			rotation = lerp_angle(rotation, velocity.angle() + PI / 2.0, turn_rate * delta)
	else:
		velocity = direction * speed
		rotation = lerp_angle(rotation, 0.0, turn_rate * delta)
	move_and_slide()


func _draw_ability() -> void:
	# Thruster flame at the feet while floating.
	if zero_gravity:
		draw_rect(Rect2(Vector2(-3, 12), Vector2(6, 5)), Color(0.6, 0.9, 1.0, 0.8))
