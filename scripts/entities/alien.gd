class_name Alien
extends Node2D
## Alien on Draugr (group "aliens"). It talks through a radio beacon encrypted
## with a simple Caesar cipher (each letter shifted N places). Daenerys's decryption
## reveals the plain message.

@export var message: String = "HELLO"
@export var shift: int = 3

var decoded: bool = false


func _ready() -> void:
	add_to_group("aliens")


func decode_message() -> String:
	decoded = true
	queue_redraw()
	return message


func encrypted() -> String:
	var out := ""
	for c in message:
		var code := c.unicode_at(0)
		if code >= 65 and code <= 90:
			out += String.chr(65 + (code - 65 + shift) % 26)
		else:
			out += c
	return out


func _draw() -> void:
	draw_rect(Rect2(-7, -9, 14, 18), Color(0.35, 0.8, 0.7))
	draw_rect(Rect2(-4, -5, 2, 3), Color.BLACK)
	draw_rect(Rect2(2, -5, 2, 3), Color.BLACK)
	draw_line(Vector2(0, -9), Vector2(0, -15), Color(0.35, 0.8, 0.7), 1.0)
	draw_rect(Rect2(-1, -17, 3, 3), Color(1.0, 0.9, 0.3))
	var font := ThemeDB.fallback_font
	var text := GameData.t("[descifrado]", "[decoded]") if decoded else encrypted()
	var color := Color(0.4, 1.0, 0.45, 0.6) if decoded else Color(0.7, 0.7, 0.75)
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 8.0
	draw_rect(Rect2(-width / 2.0, -31, width, 12), Color(0.02, 0.05, 0.04, 0.75))
	draw_string(font, Vector2(-100, -22), text, HORIZONTAL_ALIGNMENT_CENTER, 200, 8, color.lightened(0.3))
