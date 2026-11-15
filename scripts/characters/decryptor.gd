extends Astronaut
## DAENERYS - DECRYPTION (Communications)
## E: translates the beacons of nearby aliens (group "aliens") and shows the
## text above them. Text comes from the alien's decode_message() method if it has
## one, or from its "message" metadata.

signal message_decrypted(text: String)

@export var decrypt_radius: float = 120.0
@export var text_time: float = 4.0

var _pulse: float = 0.0


func _use_ability() -> void:
	_pulse = 0.4
	for alien in get_tree().get_nodes_in_group("aliens"):
		if alien is Node2D and global_position.distance_to(alien.global_position) <= decrypt_radius:
			var text := _translate(alien)
			message_decrypted.emit(text)
			_show_text(alien, text)


func _update(delta: float) -> void:
	if _pulse > 0.0:
		_pulse = maxf(0.0, _pulse - delta)
		queue_redraw()


func _translate(alien: Node2D) -> String:
	if alien.has_method("decode_message"):
		return str(alien.decode_message())
	return str(alien.get_meta("message", "Decrypted alien message"))


func _show_text(alien: Node2D, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(200, 12)
	label.position = Vector2(-100, -44)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.45))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	alien.add_child(label)

	await get_tree().create_timer(text_time).timeout

	if is_instance_valid(label):
		label.queue_free()


func _draw_ability() -> void:
	if _pulse > 0.0:
		draw_arc(Vector2.ZERO, decrypt_radius, 0.0, TAU, 48, Color(0.4, 1.0, 0.45, _pulse / 0.4), 1.0)
