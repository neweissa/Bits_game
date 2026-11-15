extends Node2D
## One chapter of the linear story: the current astronaut on their planet.
## Each planet has a short objective that needs that astronaut's power; when it
## is done, the planet's three missions (scenes/missions.tscn, data from
## Supabase) come next, and then the story moves on to the next friend.
## Every planet has a danger: Yuki's dogs bite, Zero has sharp junk (red
## outline), Fernix has a time limit, Draugr has clouds of radio noise (red
## outline) and Control C has the ghosts. Yuki also has a short tutorial.

const W := 640.0
const H := 360.0
const ARENA := Rect2(16, 70, 608, 268)
const SURVIVE_TIME := 25.0
## Yuki: robot dogs (each needs 2 hacks).
const DOGS := 5
## Fernix: seconds before the suit gives up (heat and cold).
const FERNIX_TIME := 60.0
## Zero: sharp junk; Draugr: radio noise clouds.
const SHARDS := 5
const NOISE_CLOUDS := 3
## Control C: aliens at the start, the most at once, and seconds between new ones.
const ALIENS_START := 4
const ALIENS_MAX := 10
const ALIEN_EVERY := 4.0

## Alien beacons on Draugr: [Spanish, English].
const BEACONS := [
	["BALIZA EN LINEA EN 437 MHZ", "BEACON ONLINE AT 437 MHZ"],
	["CALIBRA LA ANTENA CON EL SOL", "CALIBRATE THE ANTENNA WITH THE SUN"],
	["ESPERA 45 MIN ANTES DE TRANSMITIR", "WAIT 45 MIN BEFORE YOU TRANSMIT"],
]

var _font: Font
var _player  # Untyped on purpose: each power adds its own fields (hp, zero_gravity...).
var _hud: Node2D
var _touch: TouchControls
var _failed: bool = false
var _completed: bool = false
var _end_time: float = 0.0
var _survived: float = 0.0
var _sail_panels: Array[SailPanel] = []
## Each planet's map (scripts/maps).
var _map: PlanetMap = null
var _alien_timer: float = 0.0
var _time_left: float = FERNIX_TIME
## Why the run was lost (shown in the overlay).
var _fail_reason: String = ""
## Yuki tutorial: 0 move, 1 get close to a dog, 2 press E, 3 hack it again, 4 done.
var _tutorial: int = 0
var _tutorial_t: float = 0.0
var _start_pos: Vector2


func _ready() -> void:
	add_to_group("pausable")
	_font = ThemeDB.fallback_font
	seed(GameData.chapter + 7)
	_build_walls()
	_map = _make_map(GameData.chapter)
	if _map != null:
		_map.arena = ARENA
		_map.keep_clear.append(ARENA.get_center())
		if GameData.chapter == 3:
			for i in BEACONS.size():
				_map.keep_clear.append(_alien_spot(i))
		add_child(_map)
	match GameData.chapter:
		0:
			for i in DOGS:
				# Far from the landing spot, so the player has a moment to start.
				var spot := _random_spot()
				while spot.distance_to(ARENA.get_center()) < 150.0:
					spot = _random_spot()
				_spawn_robot("dog", spot, 45.0)
		1:
			for i in 10:
				var junk := Debris.new()
				junk.arena = _map.walkable() if _map != null else ARENA
				junk.position = _random_spot()
				add_child(junk)
			for i in 3:
				var panel := SailPanel.new()
				panel.position = _random_spot()
				add_child(panel)
				_sail_panels.append(panel)
			for i in SHARDS:
				_spawn_hazard("shard", 15, 38.0)
		2:
			for i in 4:
				var pocket := AirPocket.new()
				pocket.position = _random_spot()
				add_child(pocket)
		3:
			for i in BEACONS.size():
				var alien := Alien.new()
				alien.message = BEACONS[i][1 if GameData.lang == "en" else 0]
				alien.position = _alien_spot(i)
				add_child(alien)
			for i in NOISE_CLOUDS:
				_spawn_hazard("static", 10, 24.0)
		4:
			for i in ALIENS_START:
				_spawn_alien()
	_spawn_player()
	_start_pos = _player.position

	# HUD drawn on top of everything.
	_hud = Node2D.new()
	_hud.z_index = 10
	add_child(_hud)
	_hud.draw.connect(_draw_hud)

	if GameData.use_touch():
		_touch = TouchControls.new()
		_touch.button_label = str(GameData.txt(GameData.current_character(), "power")).get_slice(" ", 0).to_upper()
		_touch.button_color = GameData.current_character().color
		add_child(_touch)


func _process(delta: float) -> void:
	if not _completed and not _failed:
		_update_objective(delta)
	else:
		_end_time += delta
	_hud.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _end_time < 0.8:
		return  # Let the result sink in before a tap moves on.
	var tapped: bool = event is InputEventMouseButton and event.is_pressed()
	if not (event.is_action_pressed("confirm") or tapped):
		return
	if _completed:
		get_tree().change_scene_to_file("res://scenes/missions.tscn")
	elif _failed:
		get_tree().reload_current_scene()


# --- objective ----------------------------------------------------------------

func _update_objective(delta: float) -> void:
	if GameData.chapter == 0:
		_update_tutorial(delta)
	if GameData.chapter == 2:
		_time_left = maxf(0.0, _time_left - delta)
		if _time_left == 0.0:
			_fail(GameData.t("El traje no aguantó el calor y el frío. ¡Busca más rápido!",
				"The suit couldn't take the heat and cold. Search faster!"))
			return
	if GameData.chapter == 1 and is_instance_valid(_player) and _player.zero_gravity:
		for panel in _sail_panels:
			if not panel.collected and panel.position.distance_to(_player.position) < 16.0:
				panel.collected = true
	if GameData.chapter == 4 and is_instance_valid(_player):
		_survived += delta
		# More aliens keep arriving (they also get faster on their own).
		_alien_timer += delta
		if _alien_timer >= ALIEN_EVERY and get_tree().get_nodes_in_group("enemies").size() < ALIENS_MAX:
			_alien_timer = 0.0
			_spawn_alien()
	var progress := _objective_progress()
	if progress.x >= progress.y:
		_complete()


## (done, needed) for the current planet's objective.
func _objective_progress() -> Vector2i:
	match GameData.chapter:
		0:
			return Vector2i(get_tree().get_nodes_in_group("defeated_dogs").size(), DOGS)
		1:
			return Vector2i(_sail_panels.filter(func(p): return p.collected).size(), 3)
		2:
			return Vector2i(get_tree().get_nodes_in_group("heat_sources").filter(func(a): return a.found).size(), 4)
		3:
			return Vector2i(get_tree().get_nodes_in_group("aliens").filter(func(a): return a.decoded).size(), BEACONS.size())
		4:
			return Vector2i(int(_survived), int(SURVIVE_TIME))
	return Vector2i(1, 1)


func _complete() -> void:
	_completed = true
	if is_instance_valid(_player):
		_player.set_physics_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("hazards"):
		enemy.set_physics_process(false)


# --- Yuki tutorial ----------------------------------------------------------------

func _update_tutorial(delta: float) -> void:
	if not is_instance_valid(_player) or _tutorial >= 4:
		return
	_tutorial_t += delta
	match _tutorial:
		0:
			if _player.position.distance_to(_start_pos) > 24.0:
				_next_tutorial()
		1:
			var dog := _nearest_dog()
			if dog != null and dog.global_position.distance_to(_player.global_position) <= _player.hack_radius:
				_next_tutorial()
		2:
			if get_tree().get_nodes_in_group("enemies").any(func(r): return r.hacked_once):
				_next_tutorial()
		3:
			if _tutorial_t > 7.0 or not get_tree().get_nodes_in_group("defeated_dogs").is_empty():
				_next_tutorial()


func _next_tutorial() -> void:
	_tutorial += 1
	_tutorial_t = 0.0


func _nearest_dog() -> Node2D:
	var best: Node2D = null
	for dog in get_tree().get_nodes_in_group("enemies"):
		if dog.is_powered() and (best == null or dog.global_position.distance_to(_player.global_position) < best.global_position.distance_to(_player.global_position)):
			best = dog
	return best


func _tutorial_text() -> String:
	var key := GameData.t("toca el botón", "tap the button") if _touch != null else GameData.t("presiona E", "press E")
	match _tutorial:
		0:
			return GameData.t("Muévete con WASD o las flechas", "Move with WASD or the arrow keys") if _touch == null \
				else GameData.t("Muévete con el joystick de la izquierda", "Move with the joystick on the left")
		1:
			return GameData.t("Acércate a un perro robot hasta que quede dentro del círculo amarillo", "Get close to a robot dog until it is inside the yellow circle")
		2:
			return GameData.t("¡Ahora %s para hackearlo!", "Now %s to hack it!") % key
		3:
			return GameData.t("Cada perro necesita 2 hackeos (luces amarillas). Cuando despierte, ¡hackéalo otra vez!",
				"Each dog needs 2 hacks (yellow lights). When it wakes up, hack it again!")
	return ""


func _draw_tutorial() -> void:
	if GameData.chapter != 0 or _tutorial >= 4 or _completed or _failed or not is_instance_valid(_player):
		return
	# Hack range around the player while learning.
	if _tutorial <= 2:
		_hud.draw_arc(_player.global_position, _player.hack_radius, 0.0, TAU, 48, Color(1.0, 0.9, 0.2, 0.35), 1.0)
	# Arrow over the nearest dog.
	if _tutorial in [1, 2]:
		var dog := _nearest_dog()
		if dog != null:
			var tip := dog.global_position + Vector2(0, -26 - absf(sin(_tutorial_t * 5.0)) * 5.0)
			_hud.draw_colored_polygon(PackedVector2Array([tip + Vector2(-6, -8), tip + Vector2(6, -8), tip]), Color(1.0, 0.9, 0.2))
	var text := _tutorial_text()
	var box := Rect2(80, 300, W - 160, 26)
	_hud.draw_rect(box, Color(0.03, 0.04, 0.1, 0.9))
	_hud.draw_rect(box, Color(1.0, 0.9, 0.2, 0.6 + 0.3 * sin(_tutorial_t * 4.0)), false, 1.0)
	_hud.draw_string(_font, box.position + Vector2(0, 11), GameData.t("TUTORIAL", "TUTORIAL"), HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 7, Color(1.0, 0.9, 0.2))
	_hud.draw_string(_font, box.position + Vector2(0, 22), text, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 9, Color.WHITE)


# --- setup ----------------------------------------------------------------------

func _spawn_player() -> void:
	var character := GameData.current_character()
	var script: Script = load(character.script)
	_player = script.new()
	_player.body_color = character.color
	_player.character_index = GameData.chapter
	_player.position = ARENA.get_center()
	add_child(_player)
	if _player.has_signal("died"):
		_player.died.connect(_on_player_died)


func _on_player_died() -> void:
	match GameData.chapter:
		0:
			_fail(GameData.t("Los perros robot te alcanzaron. Hackéalos antes de que muerdan.", "The robot dogs got you. Hack them before they bite."))
		1:
			_fail(GameData.t("La chatarra filosa rompió tu traje. Esquiva lo que tiene borde rojo.", "Sharp junk broke your suit. Dodge anything with a red outline."))
		3:
			_fail(GameData.t("El ruido de radio te dejó sin señal. Esquiva las nubes rojas.", "Radio noise knocked out your signal. Dodge the red clouds."))
		_:
			_fail(GameData.t("No había un clon de respaldo activo. Inténtalo otra vez.", "No backup clone was active. Try again."))


func _fail(reason: String) -> void:
	_failed = true
	_fail_reason = reason
	if is_instance_valid(_player):
		_player.set_physics_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("hazards"):
		enemy.set_physics_process(false)


func _spawn_hazard(kind: String, hazard_damage: int, hazard_speed: float) -> void:
	var hazard := Hazard.new()
	hazard.kind = kind
	hazard.damage = hazard_damage
	hazard.speed = hazard_speed
	hazard.arena = _map.walkable() if _map != null else ARENA
	hazard.position = _random_spot()
	add_child(hazard)


func _spawn_robot(mode: String, pos: Vector2, robot_speed: float) -> void:
	var robot := Robot.new()
	robot.mode = mode
	robot.speed = robot_speed
	robot.arena = _map.walkable() if _map != null else ARENA
	robot.position = pos
	add_child(robot)


func _make_map(chapter: int) -> PlanetMap:
	match chapter:
		0:
			return BlackoutStreet.new()
		1:
			return ZeroField.new()
		2:
			return FireAndIce.new()
		3:
			return DraugrMeadow.new()
		4:
			return LabMap.new()
	return null


func _alien_spot(i: int) -> Vector2:
	return Vector2(ARENA.position.x + ARENA.size.x * (i + 1) / 4.0, ARENA.position.y + 70.0 + (i % 2) * 120.0)


## Control C ghost: comes in from an edge, far from the player, and chases them.
func _spawn_alien() -> void:
	var player_pos: Vector2 = _player.global_position if is_instance_valid(_player) else ARENA.get_center()
	var area: Rect2 = _map.walkable() if _map != null else ARENA
	var pos := player_pos
	while pos.distance_to(player_pos) < 160.0:
		var along := randf()
		match randi() % 4:
			0:
				pos = Vector2(lerpf(area.position.x, area.end.x, along), area.position.y + 12.0)
			1:
				pos = Vector2(lerpf(area.position.x, area.end.x, along), area.end.y - 12.0)
			2:
				pos = Vector2(area.position.x + 12.0, lerpf(area.position.y, area.end.y, along))
			_:
				pos = Vector2(area.end.x - 12.0, lerpf(area.position.y, area.end.y, along))
	_spawn_robot("alien", pos, randf_range(28.0, 36.0))


func _random_spot() -> Vector2:
	# Somewhere in the arena, but not right on top of the landing spot (or a prop).
	var spot := ARENA.get_center()
	while spot.distance_to(ARENA.get_center()) < 70.0 or (_map != null and not _map.is_free(spot)):
		spot = Vector2(
			randf_range(ARENA.position.x + 24.0, ARENA.end.x - 24.0),
			randf_range(ARENA.position.y + 24.0, ARENA.end.y - 24.0))
	return spot


func _build_walls() -> void:
	var walls := StaticBody2D.new()
	add_child(walls)
	var thickness := 20.0
	var rects := [
		Rect2(ARENA.position.x - thickness, ARENA.position.y - thickness, ARENA.size.x + thickness * 2.0, thickness),
		Rect2(ARENA.position.x - thickness, ARENA.end.y, ARENA.size.x + thickness * 2.0, thickness),
		Rect2(ARENA.position.x - thickness, ARENA.position.y, thickness, ARENA.size.y),
		Rect2(ARENA.end.x, ARENA.position.y, thickness, ARENA.size.y),
	]
	for rect in rects:
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = rect.get_center()
		walls.add_child(collision)


# --- drawing --------------------------------------------------------------------

func _draw() -> void:
	var planet := GameData.current_planet()
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.02, 0.06))
	if _map != null:
		draw_rect(ARENA, planet.color, false, 2.0)
		return  # The map draws the ground.
	draw_rect(ARENA, planet.ground)
	var tile_color: Color = planet.ground.lightened(0.08)
	for x in range(int(ARENA.position.x), int(ARENA.end.x), 32):
		draw_line(Vector2(x, ARENA.position.y), Vector2(x, ARENA.end.y), tile_color, 1.0)
	for y in range(int(ARENA.position.y), int(ARENA.end.y), 32):
		draw_line(Vector2(ARENA.position.x, y), Vector2(ARENA.end.x, y), tile_color, 1.0)
	draw_rect(ARENA, planet.color, false, 2.0)


func _draw_hud() -> void:
	var planet := GameData.current_planet()
	var character := GameData.current_character()
	var progress := _objective_progress()
	_hud.draw_string(_font, Vector2(16, 20), GameData.t("%d/5  PLANETA %s", "%d/5  PLANET %s") % [GameData.chapter + 1, planet.name.to_upper()],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, planet.color)
	_hud.draw_string(_font, Vector2(16, 36), character.name + "  -  " + str(GameData.txt(character, "hint")), HORIZONTAL_ALIGNMENT_LEFT, 380, 9, character.color)
	_hud.draw_string(_font, Vector2(16, 52), GameData.t("OBJETIVO: %s  (%d/%d)", "OBJECTIVE: %s  (%d/%d)") % [GameData.txt(planet, "objective"), mini(progress.x, progress.y), progress.y],
		HORIZONTAL_ALIGNMENT_LEFT, 390, 9, Color(1.0, 0.9, 0.5))
	_draw_hp_bar()
	if GameData.chapter == 2 and not _completed:
		var low := _time_left < 15.0
		var color := Color(1.0, 0.3, 0.25) if low else Color(1, 1, 1, 0.85)
		if low and sin(_time_left * 10.0) > 0.0:
			color = Color(1, 1, 1)
		var box := Rect2(W / 2.0 - 56.0, ARENA.position.y + 4.0, 112.0, 18.0)
		_hud.draw_rect(box, Color(0.02, 0.02, 0.06, 0.8))
		_hud.draw_rect(box, Color(color, 0.6), false, 1.0)
		_hud.draw_string(_font, box.position + Vector2(0, 14), GameData.t("TRAJE: %d s", "SUIT: %d s") % ceili(_time_left), HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 12, color)
	_hud.draw_string(_font, Vector2(100, 65), _extra_status(), HORIZONTAL_ALIGNMENT_LEFT, 300, 8, Color(1, 1, 1, 0.65))

	_hud.draw_string(_font, Vector2(410, 18), GameData.t("MISIONES (después del objetivo)", "MISSIONS (after the objective)"), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.7))
	var missions := MissionData.titles(GameData.chapter)
	for i in missions.size():
		_hud.draw_string(_font, Vector2(410, 32 + i * 12), "%d. %s" % [i + 1, missions[i]],
			HORIZONTAL_ALIGNMENT_LEFT, 220, 8, Color(1, 1, 1, 0.55))
	if _touch == null:
		_hud.draw_string(_font, Vector2(0, 352), GameData.t("WASD moverse     E poder     ESC pausa", "WASD move     E power     ESC pause"), HORIZONTAL_ALIGNMENT_RIGHT, W - 18, 8, Color(1, 1, 1, 0.45))

	_draw_tutorial()
	if _completed:
		_overlay(GameData.t("OBJETIVO CUMPLIDO", "OBJECTIVE COMPLETE"), Color(0.5, 1.0, 0.6),
			GameData.t("Ahora: las 3 misiones de %s", "Now: the 3 missions of %s") % planet.name)
	elif _failed:
		_overlay(GameData.t("SEÑAL PERDIDA", "SIGNAL LOST"), Color(1, 0.3, 0.3), _fail_reason)


func _overlay(title: String, color: Color, subtitle: String) -> void:
	_hud.draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.65))
	_hud.draw_string(_font, Vector2(0, 160), title, HORIZONTAL_ALIGNMENT_CENTER, W, 24, color)
	_hud.draw_string(_font, Vector2(0, 186), subtitle, HORIZONTAL_ALIGNMENT_CENTER, W, 11, Color.WHITE)
	if _end_time >= 0.8:
		_hud.draw_string(_font, Vector2(0, 220), GameData.t("Toca o presiona ENTER para seguir", "Tap or press ENTER to continue"), HORIZONTAL_ALIGNMENT_CENTER, W, 10, Color(1, 1, 1, 0.6))


## Health of the current astronaut (all five have it).
func _draw_hp_bar() -> void:
	var hp: int = _player.hp if is_instance_valid(_player) else 0
	var max_hp: int = _player.max_hp if is_instance_valid(_player) else 100
	var k := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var bar := Rect2(36, 59, 56, 7)
	_hud.draw_string(_font, Vector2(16, 66), GameData.t("VIDA", "HP"), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	_hud.draw_rect(bar.grow(1.0), Color(0, 0, 0, 0.7))
	_hud.draw_rect(Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)), Color(0.9, 0.2, 0.2).lerp(Color(0.3, 0.95, 0.4), k))
	_hud.draw_string(_font, bar.position + Vector2(0, 6), str(hp), HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 7, Color.WHITE)


func _extra_status() -> String:
	match GameData.chapter:
		0:
			var powered := get_tree().get_nodes_in_group("enemies").filter(func(r): return r.is_powered()).size()
			return GameData.t("Perros encendidos ahora: %d   (2 hackeos para apagarlos del todo)", "Dogs powered on now: %d   (2 hacks to shut them down)") % powered
		1:
			var zero_g: bool = is_instance_valid(_player) and _player.zero_gravity
			return GameData.t("¡Evita lo rojo!  Modo: ", "Avoid the red!  Mode: ") + (GameData.t("GRAVEDAD CERO (atrapa paneles)", "ZERO GRAVITY (grab panels)") if zero_g
				else GameData.t("NORMAL (paneles fuera de alcance)", "NORMAL (panels out of reach)"))
		3:
			return GameData.t("Esquiva las nubes de ruido de borde rojo", "Dodge the red-outlined noise clouds")
		2:
			if not is_instance_valid(_player):
				return ""
			return GameData.t("Escáner: ", "Scan: ") + (GameData.t("LISTO (E)", "READY (E)") if _player.cooldown_left <= 0.0
				else GameData.t("recargando %.1f s", "recharging %.1f s") % _player.cooldown_left)
		4:
			if not is_instance_valid(_player):
				return ""
			var clone_text := ""
			if _player.is_decoy_active():
				clone_text = GameData.t("¡DISTRAYENDO %.1f s!", "DISTRACTING %.1f s!") % _player.decoy_left
			elif _player.has_clone():
				clone_text = GameData.t("ACTIVO", "ACTIVE")
			elif _player.clone_cooldown <= 0.0:
				clone_text = GameData.t("LISTO (E)", "READY (E)")
			else:
				clone_text = GameData.t("recargando %.1f s", "recharging %.1f s") % _player.clone_cooldown
			return GameData.t("Clon: %s     Fantasmas: %d", "Clone: %s     Ghosts: %d") % [clone_text, get_tree().get_nodes_in_group("enemies").size()]
	return ""
