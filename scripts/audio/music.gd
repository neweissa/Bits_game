extends Node
## Background music (autoload "Music"). Plays the tracks in assets/music one
## after another: when one ends, the next one starts (and it loops back to the
## first). On/off and volume come from GameData and are saved with the settings.
## It keeps playing while the game is paused.
## Tracks: DavidKBD - My Little Bots Pack (see CREDITS.md).

const TRACKS := [
	"res://assets/music/01_my_little_bots.ogg",
	"res://assets/music/02_keep_dancing.ogg",
	"res://assets/music/03_bot_city.ogg",
	"res://assets/music/04_shivandroid.ogg",
	"res://assets/music/06_danger_of_explosion.ogg",
]
## Volume step for the - / + buttons.
const STEP := 0.1

var _player: AudioStreamPlayer
var _track: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.finished.connect(_next_track)
	_apply_volume()
	if GameData.music_on:
		_play(_track)


func _play(i: int) -> void:
	_track = posmod(i, TRACKS.size())
	if not ResourceLoader.exists(TRACKS[_track]):
		return
	var stream: AudioStream = load(TRACKS[_track])
	# One track at a time, so "finished" fires and the next one starts.
	if stream is AudioStreamOggVorbis:
		stream.loop = false
	_player.stream = stream
	_player.play()


func _next_track() -> void:
	if GameData.music_on:
		_play(_track + 1)


## Name of the track playing now, e.g. "Bot City".
func track_name() -> String:
	var file: String = TRACKS[_track].get_file().get_basename()
	return file.substr(3).replace("_", " ").capitalize()


func set_enabled(value: bool) -> void:
	GameData.music_on = value
	GameData.save_settings()
	if value and not _player.playing:
		_play(_track)
	elif not value:
		_player.stop()


func toggle() -> void:
	set_enabled(not GameData.music_on)


## Changes the volume by `steps` * STEP (0..1).
func change_volume(steps: int) -> void:
	GameData.music_volume = clampf(snappedf(GameData.music_volume + steps * STEP, 0.01), 0.0, 1.0)
	GameData.save_settings()
	_apply_volume()


func _apply_volume() -> void:
	_player.volume_db = linear_to_db(maxf(GameData.music_volume, 0.0001))
