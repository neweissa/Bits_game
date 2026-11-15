extends Node
## Minimal Supabase client (autoload "Supabase"). Reads tables through the REST API
## with the public key from res://config/supabase.cfg (see supabase.example.cfg).
## Usage:  var rows: Array = await Supabase.fetch("preguntas_juego")
##         var rows: Array = await Supabase.fetch("riesgos", "select=*&tema=eq.energia")

const CONFIG_PATH := "res://config/supabase.cfg"

var url: String = ""
var key: String = ""


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		push_warning("Supabase: %s not found, running without online data." % CONFIG_PATH)
		return
	url = str(config.get_value("supabase", "url", "")).trim_suffix("/")
	key = str(config.get_value("supabase", "anon_key", ""))


func is_configured() -> bool:
	return url.begins_with("https://") and not key.is_empty() and not url.contains("YOUR-PROJECT")


## Returns the rows of a table as an Array of Dictionaries ([] on any error).
func fetch(table: String, query: String = "select=*") -> Array:
	if not is_configured():
		return []
	var http := HTTPRequest.new()
	http.timeout = 15.0
	add_child(http)
	var headers := PackedStringArray(["apikey: " + key, "Accept: application/json"])
	if http.request("%s/rest/v1/%s?%s" % [url, table, query], headers) != OK:
		http.queue_free()
		return []
	var response: Array = await http.request_completed  # [result, code, headers, body]
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200:
		push_warning("Supabase: could not read '%s' (HTTP %d)." % [table, response[1]])
		return []
	var data = JSON.parse_string(response[3].get_string_from_utf8())
	return data if data is Array else []
