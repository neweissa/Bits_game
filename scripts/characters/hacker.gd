extends Astronaut
## ANDREW - ROBOT HACK (Energy)
## E: cuts the power of nearby robots (group "enemies") for a few seconds.
## Real link: inhibitors cut the energy path, like the separation switches that
## keep a CubeSat off while it is inside its deployer.

@export var hack_radius: float = 80.0
@export var shutdown_time: float = 4.0

var _pulse: float = 0.0


func _use_ability() -> void:
	_pulse = 0.4
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and global_position.distance_to(enemy.global_position) <= hack_radius:
			_cut_power(enemy)


func _update(delta: float) -> void:
	if _pulse > 0.0:
		_pulse = maxf(0.0, _pulse - delta)
		queue_redraw()


func _cut_power(enemy: Node2D) -> void:
	if enemy.has_meta("powered_off"):
		return
	if enemy.has_method("power_off"):
		enemy.power_off(shutdown_time)
		return

	# Default: the robot stops processing and goes dark.
	enemy.set_meta("powered_off", true)
	enemy.set_process(false)
	enemy.set_physics_process(false)
	enemy.modulate = Color(0.3, 0.3, 0.3)

	await get_tree().create_timer(shutdown_time).timeout

	if is_instance_valid(enemy):
		enemy.set_process(true)
		enemy.set_physics_process(true)
		enemy.modulate = Color.WHITE
		enemy.remove_meta("powered_off")


func _draw_ability() -> void:
	if _pulse > 0.0:
		draw_arc(Vector2.ZERO, hack_radius, 0.0, TAU, 48, Color(1.0, 1.0, 0.0, _pulse / 0.4), 2.0)
