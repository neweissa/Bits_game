class_name Robot
extends Node2D
## Enemy (group "enemies").
## "dog" mode (Yuki): patrols the street; when the player comes close it chases
## them and bites (bark animation + lunge + bite marks), dealing dog_damage.
## "alien" mode (Control C ghosts): flies through everything after the player,
## gets faster the longer it lives and hits hard. When Rayan drops a new clone,
## the ghosts chase the clone for a few seconds (and break it if they touch it).
## Moves in _physics_process, so Andrew's hack (which stops physics) freezes it.
## Dogs use the team's German shepherd sprite from res://personaje_perros/perros.tscn when it is
## in the project; otherwise they are drawn with placeholder shapes.

const DOG_SCENE := "res://personaje_perros/perros.tscn"
const DOG_SCALE := 0.22
## Dogs notice the player from this far and bite from this close.
const DOG_SIGHT := 110.0
const DOG_BITE_RANGE := 20.0
const DOG_ATTACK_TIME := 0.45

@export var mode: String = "dog"
@export var speed: float = 50.0
## Ghost damage per touch (it was 20).
@export var damage: int = 30
@export var dog_damage: int = 12
## Seconds between bites / touches.
@export var attack_cooldown: float = 1.3
## Alien mode: speed added per second alive, up to max_speed.
@export var acceleration: float = 2.5
@export var max_speed: float = 95.0

var arena: Rect2 = Rect2(0, 0, 640, 360)
var _velocity: Vector2 = Vector2.ZERO
var _cooldown: float = 0.0
var _sprite: AnimatedSprite2D = null
## Seconds left of the current bite (dogs).
var _attack_t: float = 0.0
var _attack_dir: Vector2 = Vector2.RIGHT
var _phase: float = randf() * TAU


func _ready() -> void:
	add_to_group("enemies")
	hacks_left = hacks_to_defeat
	_velocity = Vector2.from_angle(randf() * TAU) * speed
	if mode == "dog":
		_sprite = _team_dog_sprite()
		if _sprite != null:
			_sprite.scale = Vector2(DOG_SCALE, DOG_SCALE)
			_sprite.play(&"correr")
			add_child(_sprite)


## Takes the AnimatedSprite2D (animations correr / estatica / ladrido) out of
## the team's dog scene, without its chase script.
func _team_dog_sprite() -> AnimatedSprite2D:
	if not ResourceLoader.exists(DOG_SCENE):
		return null
	var scene: PackedScene = load(DOG_SCENE)
	var root := scene.instantiate()
	var anim := root.get_node_or_null("Animated") as AnimatedSprite2D
	if anim != null:
		root.remove_child(anim)
		anim.owner = null
	root.free()
	return anim


## True once Andrew has hacked this robot at least once.
var hacked_once: bool = false
## Dogs need this many hacks to shut down for good (planet Yuki objective).
@export var hacks_to_defeat: int = 2
var hacks_left: int = 2
## True once the dog is shut down for good.
var defeated: bool = false


func is_powered() -> bool:
	return not has_meta("powered_off")


## Called by Andrew's hack: stops moving and goes dark for `duration` seconds.
func power_off(duration: float) -> void:
	if defeated:
		return
	hacked_once = true
	_attack_t = 0.0
	if mode == "dog":
		hacks_left -= 1
		if hacks_left <= 0:
			_defeat()
			return
	set_meta("powered_off", true)
	set_physics_process(false)
	modulate = Color(0.35, 0.35, 0.35)
	if _sprite != null:
		_sprite.play(&"estatica")
	queue_redraw()
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self) and not defeated:
		remove_meta("powered_off")
		set_physics_process(true)
		modulate = Color.WHITE
		if _sprite != null:
			_sprite.play(&"correr")


## Second hack: the dog shuts down for good (fades out and stops counting as an enemy).
func _defeat() -> void:
	defeated = true
	set_physics_process(false)
	remove_from_group("enemies")
	add_to_group("defeated_dogs")
	if _sprite != null:
		_sprite.play(&"desaparecer")
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(0.4, 0.9, 1.0, 0.0), 1.0)
	tween.tween_callback(hide)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	var player := _find_player()

	_phase += delta
	if mode == "alien":
		speed = minf(max_speed, speed + acceleration * delta)
		if player != null:
			# A fresh clone is a decoy: the ghosts go after it for a few seconds.
			var decoy: bool = player.has_method("is_decoy_active") and player.is_decoy_active()
			var target: Node2D = player.clone if decoy else player
			_velocity = (target.global_position - global_position).normalized() * speed
			position += _velocity * delta
			if not decoy and _cooldown == 0.0 and global_position.distance_to(player.global_position) < 14.0 \
					and player.has_method("take_damage"):
				player.take_damage(damage)
				_cooldown = attack_cooldown
			# Touching the holo clone breaks it (and restarts its recharge).
			if player.has_method("has_clone") and player.has_clone() \
					and global_position.distance_to(player.clone.global_position) < 14.0:
				player.destroy_clone()
	elif mode == "dog" and player != null and global_position.distance_to(player.global_position) < DOG_SIGHT:
		_dog_attack(player, delta)
	else:
		position += _velocity * delta
		if position.x < arena.position.x + 10.0 or position.x > arena.end.x - 10.0:
			_velocity.x = -_velocity.x
		if position.y < arena.position.y + 10.0 or position.y > arena.end.y - 10.0:
			_velocity.y = -_velocity.y
		position = position.clamp(arena.position + Vector2(10, 10), arena.end - Vector2(10, 10))
	if _sprite != null:
		# The team sheet faces left, so flip when running right.
		_sprite.flip_h = _velocity.x > 0.0
		var bite := 1.0 + 0.18 * sin(_attack_t / DOG_ATTACK_TIME * PI)
		_sprite.scale = Vector2(DOG_SCALE, DOG_SCALE) * bite
	queue_redraw()


## Chase the player and bite when close enough.
func _dog_attack(player: Node2D, delta: float) -> void:
	var to_player := player.global_position - global_position
	_attack_dir = to_player.normalized()
	if _attack_t > 0.0:
		# Lunge forward during the first part of the bite.
		_attack_t = maxf(0.0, _attack_t - delta)
		if _attack_t > DOG_ATTACK_TIME * 0.5:
			position += _attack_dir * speed * 2.2 * delta
		if _attack_t == 0.0 and _sprite != null:
			_sprite.play(&"correr")
	else:
		_velocity = _attack_dir * speed * 1.35
		if to_player.length() > DOG_BITE_RANGE * 0.7:
			position += _velocity * delta
	# Keep a little apart from the other dogs so they don't pile up.
	for other in get_tree().get_nodes_in_group("enemies"):
		if other != self and other.mode == "dog":
			var away: Vector2 = global_position - other.global_position
			if away.length() < 22.0:
				position += (away.normalized() if away.length() > 0.1 else Vector2.from_angle(randf() * TAU)) * 40.0 * delta
	position = position.clamp(arena.position + Vector2(10, 10), arena.end - Vector2(10, 10))
	if _cooldown == 0.0 and to_player.length() < DOG_BITE_RANGE:
		_cooldown = attack_cooldown
		_attack_t = DOG_ATTACK_TIME
		if _sprite != null:
			_sprite.play(&"ladrido")
		if player.has_method("take_damage"):
			player.take_damage(dog_damage)


func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if not players.is_empty() else null


func _draw() -> void:
	if mode == "alien":
		_draw_alien()
		return
	if _attack_t > 0.0:
		_draw_bite()
	if mode == "dog" and not defeated:
		# Hacks still needed, as little lights over the dog.
		for i in hacks_to_defeat:
			var on := i < hacks_left
			draw_rect(Rect2(Vector2(-7 + i * 9, -20), Vector2(5, 3)), Color(1.0, 0.85, 0.2) if on else Color(0.2, 0.2, 0.25))
	if _sprite != null:
		return
	# Robot dog: body, head, legs, red eye.
	var facing := 1.0 if _velocity.x >= 0.0 else -1.0
	draw_rect(Rect2(-9, -5, 18, 9), Color(0.65, 0.68, 0.75))
	draw_rect(Rect2(facing * 7.0 - 3.0, -10, 7, 7), Color(0.75, 0.78, 0.85))
	draw_rect(Rect2(facing * 8.0, -8, 2, 2), Color(1, 0.1, 0.1) if is_powered() else Color(0.2, 0.2, 0.2))
	for leg_x in [-7.0, -2.0, 3.0, 7.0]:
		draw_rect(Rect2(leg_x - 1.0, 4, 2, 4), Color(0.45, 0.48, 0.55))


## Bite marks in front of the dog while it attacks.
func _draw_bite() -> void:
	var k := _attack_t / DOG_ATTACK_TIME
	var center := _attack_dir * 14.0 + Vector2(0, -4)
	var angle := _attack_dir.angle()
	for side in [-1.0, 1.0]:
		draw_arc(center + Vector2.from_angle(angle + PI / 2.0) * side * 3.0, 6.0,
			angle - 0.9, angle + 0.9, 8, Color(1.0, 0.25, 0.2, k), 2.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-8, -10), "GRR!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.3, k))


## Ghost of the Control C lab: floats, wavy tail, turns red as it speeds up.
func _draw_alien() -> void:
	var jitter := Vector2(randf_range(-0.6, 0.6), randf_range(-0.6, 0.6)) if is_physics_processing() else Vector2.ZERO
	var heat := clampf((speed - 30.0) / (max_speed - 30.0), 0.0, 1.0)
	var body := Color(0.82, 0.9, 1.0, 0.82).lerp(Color(1.0, 0.35, 0.4, 0.88), heat)
	var c := jitter + Vector2(0, -4 + sin(_phase * 4.0) * 2.0)
	# Shadow on the floor.
	draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.25))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# Glow.
	draw_circle(c, 12.0, Color(body, 0.12 + 0.1 * heat))
	# Head and body with a wavy bottom.
	var points := PackedVector2Array()
	for i in 9:
		points.append(c + Vector2.from_angle(PI + PI * i / 8.0) * 8.0)
	for i in 7:
		var x := 8.0 - i * (16.0 / 6.0)
		var wave := 3.0 if i % 2 == 0 else 0.0
		points.append(c + Vector2(x, 9.0 + wave + sin(_phase * 8.0 + i) * 1.2))
	draw_colored_polygon(points, body)
	# Eyes and mouth (angrier when it is fast).
	var eye := Color(0.08, 0.05, 0.15)
	draw_rect(Rect2(c + Vector2(-5, -3), Vector2(3, 4 - heat)), eye)
	draw_rect(Rect2(c + Vector2(2, -3), Vector2(3, 4 - heat)), eye)
	if heat > 0.4:
		draw_line(c + Vector2(-6, -5), c + Vector2(-2, -4), eye, 1.0)
		draw_line(c + Vector2(6, -5), c + Vector2(2, -4), eye, 1.0)
	draw_arc(c + Vector2(0, 4), 2.0, 0.0, PI if heat < 0.5 else TAU, 6, eye, 1.0)
