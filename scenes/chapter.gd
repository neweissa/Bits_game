extends Node2D
## Chapter card shown before each planet (linear story: Andrew > Bels > Ray > Daenerys > Rayan).
## After the last planet (GameData.chapter past the end) it hands over to the ending.
## ENTER / SPACE / tap to continue.

const W := 640.0
const H := 360.0

var _font: Font
var _t: float = 0.0


func _ready() -> void:
	_font = ThemeDB.fallback_font
	if _is_ending():
		get_tree().change_scene_to_file.call_deferred("res://scenes/ending.tscn")


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _t < 0.6:
		return  # Avoid skipping the card by accident with the tap that opened it.
	var tapped: bool = event is InputEventMouseButton and event.is_pressed()
	if event.is_action_pressed("confirm") or tapped:
		if not _is_ending():
			get_tree().change_scene_to_file("res://scenes/planet.tscn")


func _is_ending() -> bool:
	return GameData.chapter >= GameData.planets.size()


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.02, 0.06))
	var alpha := clampf(_t * 2.0, 0.0, 1.0)
	if _is_ending():
		return
	_draw_chapter(alpha)
	var blink := 0.55 + 0.35 * sin(_t * 4.0)
	draw_rect(Rect2(W / 2.0 - 110.0, 328, 220, 18), Color(0.02, 0.02, 0.06, 0.85))
	draw_string(_font, Vector2(0, 340), GameData.t("Toca o presiona ENTER para seguir", "Tap or press ENTER to continue"), HORIZONTAL_ALIGNMENT_CENTER, W, 10, Color(1, 1, 1, blink))


func _draw_chapter(alpha: float) -> void:
	var character := GameData.current_character()
	var planet := GameData.current_planet()

	# Progress: five squares, one per friend.
	for i in GameData.characters.size():
		var square := Rect2(W / 2.0 - 60.0 + i * 24.0, 24, 16, 16)
		var done := i < GameData.chapter
		var current := i == GameData.chapter
		var color: Color = GameData.characters[i].color
		draw_rect(square, color if done or current else Color(color, 0.2))
		if current:
			draw_rect(square.grow(3.0), Color(1, 1, 1, alpha), false, 1.0)

	draw_string(_font, Vector2(0, 76), GameData.t("CAPÍTULO %d / %d", "CHAPTER %d / %d") % [GameData.chapter + 1, GameData.planets.size()],
		HORIZONTAL_ALIGNMENT_CENTER, W, 12, Color(1, 1, 1, 0.6 * alpha))
	draw_string(_font, Vector2(0, 108), GameData.t("%s  en  %s", "%s  on  %s") % [character.name.to_upper(), planet.name.to_upper()],
		HORIZONTAL_ALIGNMENT_CENTER, W, 24, Color(character.color, alpha))

	# The astronaut standing on a slice of their planet.
	var planet_tex := GameData.planet_texture(GameData.chapter)
	if planet_tex != null:
		draw_texture_rect(planet_tex, GameData.planet_rect(GameData.chapter, Vector2(W / 2.0, 330.0), 150.0), false, Color(1, 1, 1, alpha))
	else:
		draw_circle(Vector2(W / 2.0, 330.0), 150.0, Color(planet.color, alpha * 0.9))
	var feet := Vector2(W / 2.0, 181.0 - absf(sin(_t * 3.0)) * 3.0)
	if not CharacterSprites.draw(self, GameData.chapter, feet, 40.0, CharacterSprites.ROW_DOWN, 0, alpha):
		draw_rect(Rect2(feet - Vector2(10, 40), Vector2(20, 40)), Color(character.color, alpha))
		draw_rect(Rect2(feet + Vector2(-6, -34), Vector2(12, 6)), Color(0.08, 0.08, 0.14, alpha))

	var panel := Rect2(60, 214, W - 120, 104)
	draw_rect(panel, Color(0.04, 0.04, 0.1, 0.92 * alpha))
	draw_rect(panel, Color(1, 1, 1, 0.3 * alpha), false, 1.0)
	draw_multiline_string(_font, Vector2(76, 236), GameData.txt(planet, "story"), HORIZONTAL_ALIGNMENT_CENTER, W - 152, 11, -1, Color(1, 1, 1, alpha))
	draw_string(_font, Vector2(76, 278), GameData.t("PODER:  ", "POWER:  ") + GameData.txt(character, "power"), HORIZONTAL_ALIGNMENT_CENTER, W - 152, 10, Color(character.color, alpha))
	draw_string(_font, Vector2(76, 300), GameData.t("OBJETIVO:  ", "OBJECTIVE:  ") + GameData.txt(planet, "objective"), HORIZONTAL_ALIGNMENT_CENTER, W - 152, 10, Color(1.0, 0.9, 0.5, alpha))
