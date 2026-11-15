extends Node
## Developer tool (autoload "DevCapture"). Does nothing in a normal run.
## Run Godot with user args to save screenshots and quit, e.g.:
##   Godot.exe --path . -- --capture=3,12,20         (lobby; add --intro for the cinematic)
##   Godot.exe --path . -- --planet=2 --capture=1,4 --press=1.5
##   Godot.exe --path . -- --chapter=5 --capture=1      (5 = ending card)
##   Godot.exe --path . -- --missions=3,1 --capture=1   (planet 3, mission 2)
##   Godot.exe --path . -- --travel=2 --capture=1       (ship engineering, going to planet 2)
##   Godot.exe --path . -- --ending --capture=3         (ending; --press-confirm=... skips acts)
##   add --touch to show the phone controls on a PC, --lang=en for English
## Screenshots go to user://shots/.

var _times: Array[float] = []
var _press_times: Array[float] = []
var _confirm_times: Array[float] = []
var _elapsed: float = 0.0
var _shot: int = 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			for value in arg.trim_prefix("--capture=").split(","):
				_times.append(float(value))
		elif arg.begins_with("--press="):
			for value in arg.trim_prefix("--press=").split(","):
				_press_times.append(float(value))
		elif arg.begins_with("--planet="):
			GameData.chapter = int(arg.trim_prefix("--planet="))
			get_tree().change_scene_to_file.call_deferred("res://scenes/planet.tscn")
		elif arg.begins_with("--chapter="):
			GameData.chapter = int(arg.trim_prefix("--chapter="))
			get_tree().change_scene_to_file.call_deferred("res://scenes/chapter.tscn")
		elif arg.begins_with("--missions="):
			var parts := arg.trim_prefix("--missions=").split(",")
			GameData.chapter = int(parts[0])
			GameData.mission_index = int(parts[1]) if parts.size() > 1 else 0
			get_tree().change_scene_to_file.call_deferred("res://scenes/missions.tscn")
		elif arg.begins_with("--travel="):
			GameData.chapter = int(arg.trim_prefix("--travel="))
			get_tree().change_scene_to_file.call_deferred("res://scenes/travel.tscn")
		elif arg == "--ending":
			GameData.chapter = 5
			get_tree().change_scene_to_file.call_deferred("res://scenes/ending.tscn")
		elif arg.begins_with("--press-confirm="):
			for value in arg.trim_prefix("--press-confirm=").split(","):
				_confirm_times.append(float(value))
		elif arg.begins_with("--fact="):
			GameData.chapter = int(arg.trim_prefix("--fact=")) + 1
			get_tree().change_scene_to_file.call_deferred("res://scenes/fact.tscn")
		elif arg == "--intro":
			get_tree().change_scene_to_file.call_deferred("res://scenes/intro.tscn")
		elif arg.begins_with("--lang="):
			GameData.lang = arg.trim_prefix("--lang=")  # Not saved.
		elif arg == "--touch":
			GameData.force_touch = true
	set_process(not _times.is_empty() or not _confirm_times.is_empty())
	if not _times.is_empty():
		DirAccess.make_dir_recursive_absolute("user://shots")


func _process(delta: float) -> void:
	_elapsed += delta
	if not _press_times.is_empty() and _elapsed >= _press_times[0]:
		_press_times.pop_front()
		Input.action_press("ability")
		await get_tree().physics_frame
		await get_tree().physics_frame
		Input.action_release("ability")
	if not _confirm_times.is_empty() and _elapsed >= _confirm_times[0]:
		_confirm_times.pop_front()
		var event := InputEventAction.new()
		event.action = "confirm"
		event.pressed = true
		Input.parse_input_event(event)
	if _times.is_empty() or _elapsed < _times[0]:
		return
	_times.pop_front()
	await RenderingServer.frame_post_draw
	var path := "user://shots/shot_%d.png" % _shot
	_shot += 1
	get_viewport().get_texture().get_image().save_png(path)
	print("DevCapture saved ", ProjectSettings.globalize_path(path))
	if _times.is_empty():
		get_tree().quit()
