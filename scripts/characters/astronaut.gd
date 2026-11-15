class_name Astronaut
extends CharacterBody2D
## Base for the five astronauts: top-down movement (WASD / arrows), the team's
## LPC sprite (or a placeholder rectangle if the PNG is missing), and the
## "ability" action (E), and health: every astronaut has HP and a small health
## bar over the head. Enemies call take_damage(); at 0 HP "died" is emitted.
## Each power extends this and overrides _use_ability(), _update() and
## _draw_ability() (and _out_of_hp() to survive, like Rayan's clone).

signal died

const BODY_SIZE := Vector2(12, 24)

@export var speed: float = 120.0
@export var max_hp: int = 100

var hp: int = 100
## Seconds the health bar stays bright after a hit.
var _hurt_t: float = 0.0

var body_color: Color = Color.WHITE
## Index in GameData.characters, used to pick the sprite sheet.
var character_index: int = -1

var _sprite: AnimatedSprite2D = null


func _ready() -> void:
	hp = max_hp
	var shape := RectangleShape2D.new()
	shape.size = BODY_SIZE
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	add_to_group("player")
	if character_index >= 0 and CharacterSprites.has_sprite(character_index):
		_sprite = AnimatedSprite2D.new()
		_sprite.sprite_frames = CharacterSprites.frames(character_index)
		# 64px frame, ~48px body -> scale so the body matches BODY_SIZE.y.
		var k := BODY_SIZE.y / 48.0
		_sprite.scale = Vector2(k, k)
		# Put the feet at the bottom of the collision box.
		_sprite.position.y = BODY_SIZE.y / 2.0 - (CharacterSprites.FEET_Y - 32.0) * k
		_sprite.play(&"idle")
		add_child(_sprite)


func _physics_process(delta: float) -> void:
	_move(delta)
	if Input.is_action_just_pressed("ability"):
		_use_ability()
	_update(delta)
	_animate()
	if _hurt_t > 0.0:
		_hurt_t = maxf(0.0, _hurt_t - delta)
	queue_redraw()


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = maxi(0, hp - amount)
	_hurt_t = 1.0
	modulate = Color(1.0, 0.4, 0.4)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.3)
	if hp <= 0:
		_out_of_hp()


## Default: the astronaut is lost. Rayan overrides it to respawn on his clone.
func _out_of_hp() -> void:
	died.emit()
	queue_free()


func _animate() -> void:
	if _sprite == null:
		return
	var v := velocity.rotated(-rotation)
	if v.length() < 5.0:
		_sprite.play(&"idle")
	elif absf(v.y) > absf(v.x):
		_sprite.play(&"walk_up" if v.y < 0.0 else &"walk_down")
	else:
		_sprite.play(&"walk_left" if v.x < 0.0 else &"walk_right")


func _move(_delta: float) -> void:
	velocity = _input_direction() * speed
	move_and_slide()


func _input_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _use_ability() -> void:
	pass


func _update(_delta: float) -> void:
	pass


func _draw() -> void:
	if _sprite == null:
		draw_rect(Rect2(-BODY_SIZE / 2.0, BODY_SIZE), body_color)
		# Visor, so you can tell which way is up.
		draw_rect(Rect2(Vector2(-4, -9), Vector2(8, 4)), Color(0.08, 0.08, 0.14))
	_draw_ability()
	_draw_health_bar()


## Small bar over the head, always level even when Bels spins in zero gravity.
func _draw_health_bar() -> void:
	draw_set_transform(Vector2.ZERO, -rotation)
	var k := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var bar := Rect2(-11, -BODY_SIZE.y / 2.0 - 9.0, 22, 3)
	draw_rect(bar.grow(1.0), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)),
		Color(0.9, 0.2, 0.2).lerp(Color(0.3, 0.95, 0.4), k).lightened(0.3 * _hurt_t))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_ability() -> void:
	pass
