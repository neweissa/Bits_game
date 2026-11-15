extends Astronaut
## RAY - INFRARED VISION (Thermal)
## E: reveals the heat of nearby things for `duration` seconds, even hidden ones.
## Scans the groups "enemies" and "heat_sources". A node can react its own way
## by defining on_infrared(duration); otherwise it is tinted red and shown.
## After a scan you can scan again in `cooldown` seconds (shorter than the
## reveal, so you can keep scanning while you walk).

## Smaller than the first version (180) so the scan is not too easy.
@export var scan_radius: float = 130.0
@export var duration: float = 5.0
## Seconds between scans (it used to be the whole 5 s of the reveal).
@export var cooldown: float = 1.5

var active: bool = false
## Seconds until the next scan.
var cooldown_left: float = 0.0
var _ring_t: float = 0.0
## Node -> seconds left tinted red.
var _revealed: Dictionary = {}


func _use_ability() -> void:
	if cooldown_left <= 0.0:
		_scan()


func _scan() -> void:
	cooldown_left = cooldown
	_ring_t = duration
	active = true
	var targets := get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("heat_sources")
	for target in targets:
		if not (target is Node2D) or global_position.distance_to(target.global_position) > scan_radius:
			continue
		if target.has_method("on_infrared"):
			target.on_infrared(duration)
			continue
		if not _revealed.has(target):
			target.set_meta("original_modulate", target.modulate)
			target.set_meta("original_visible", target.visible)
		_revealed[target] = duration
		target.modulate = Color(1.0, 0.2, 0.1)
		target.visible = true


func _update(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	_ring_t = maxf(0.0, _ring_t - delta)
	active = _ring_t > 0.0
	for target in _revealed.keys():
		_revealed[target] -= delta
		if _revealed[target] > 0.0:
			continue
		_revealed.erase(target)
		if is_instance_valid(target):
			target.modulate = target.get_meta("original_modulate", Color.WHITE)
			target.visible = target.get_meta("original_visible", true)


func _draw_ability() -> void:
	if active:
		var fresh := clampf((_ring_t - (duration - 0.4)) / 0.4, 0.0, 1.0)
		draw_arc(Vector2.ZERO, scan_radius, 0.0, TAU, 64, Color(1.0, 0.2, 0.1, 0.35 + 0.4 * fresh), 1.0 + fresh)
