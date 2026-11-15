extends Astronaut
## RAYAN - HOLO CLONE (Risk + Redundancy)
## E: drops a backup hologram where you stand (only one at a time). After that
## the clone needs `clone_recharge` seconds before you can drop another one. If
## an alien touches the clone, it breaks and the recharge starts again.
## If your HP reaches 0 and a clone exists, you respawn on it with full HP and
## the clone is used up. With no clone, you die.
## Real link: NASA recommends two separate burn wires, and "it is cheaper to
## build two satellites at once".
## Enemies damage you with player.take_damage() (HP and the bar are in Astronaut).
## When a new clone appears, the ghosts chase it for `decoy_time` seconds.

@export var clone_recharge: float = 5.0

## Seconds the ghosts follow a new clone instead of you.
@export var decoy_time: float = 3.0

var clone: Node2D = null
## Seconds until a new clone can be dropped.
var clone_cooldown: float = 0.0
## Seconds left in which the ghosts chase the clone.
var decoy_left: float = 0.0


func _update(delta: float) -> void:
	clone_cooldown = maxf(0.0, clone_cooldown - delta)
	decoy_left = maxf(0.0, decoy_left - delta)


## True while the new clone distracts the ghosts.
func is_decoy_active() -> bool:
	return decoy_left > 0.0 and has_clone()


func _use_ability() -> void:
	if clone_cooldown > 0.0:
		return
	clone_cooldown = clone_recharge
	if clone != null and is_instance_valid(clone):
		clone.queue_free()
	if _sprite != null:
		# Hologram of the team sprite: same pose, tinted cyan and see-through.
		var holo := Sprite2D.new()
		holo.texture = _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
		holo.scale = _sprite.scale
		holo.offset = _sprite.position / _sprite.scale
		holo.modulate = Color(0.4, 0.95, 1.0, 0.5)
		clone = holo
	else:
		var poly := Polygon2D.new()
		var half := BODY_SIZE / 2.0
		poly.polygon = PackedVector2Array([-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)])
		poly.color = Color(body_color, 0.4)
		clone = poly
	get_parent().add_child(clone)
	clone.global_position = global_position
	decoy_left = decoy_time


func has_clone() -> bool:
	return clone != null and is_instance_valid(clone)


## Called by an alien that touches the clone: it disappears with a flash and
## the recharge starts again from the beginning.
func destroy_clone() -> void:
	if not has_clone():
		return
	var flash := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 12:
		points.append(Vector2.from_angle(TAU * i / 12.0) * 10.0)
	flash.polygon = points
	flash.color = Color(0.4, 0.95, 1.0, 0.8)
	flash.global_position = clone.global_position
	get_parent().add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector2(2.5, 2.5), 0.3)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)
	clone.queue_free()
	clone = null
	decoy_left = 0.0
	clone_cooldown = clone_recharge


## Out of HP: respawn on the clone if there is one, otherwise the run is lost.
func _out_of_hp() -> void:
	if has_clone():
		global_position = clone.global_position
		clone.queue_free()
		clone = null
		decoy_left = 0.0
		hp = max_hp
	else:
		super()
