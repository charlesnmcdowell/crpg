extends Node

signal settings_changed

const SETTINGS_FILE = "user://settings.save"

var settings = {
	"master_volume": 0.8,
	"music_enabled": true,
	"sfx_enabled": true,
	"ui_scale": "Medium"
}

var ui_scale_values = {
	"Small": 0.8,
	"Medium": 1.0,
	"Large": 1.2
}

func _ready():
	load_settings()
	apply_settings()

func load_settings():
	if FileAccess.file_exists(SETTINGS_FILE):
		var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var saved_settings = json.data
				for key in saved_settings:
					if key in settings:
						settings[key] = saved_settings[key]

func save_settings():
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings))
		file.close()

func set_master_volume(value: float):
	settings["master_volume"] = clamp(value, 0.0, 1.0)
	apply_audio_settings()
	save_settings()
	settings_changed.emit()

func set_music_enabled(enabled: bool):
	settings["music_enabled"] = enabled
	apply_audio_settings()
	save_settings()
	settings_changed.emit()

func set_sfx_enabled(enabled: bool):
	settings["sfx_enabled"] = enabled
	apply_audio_settings()
	save_settings()
	settings_changed.emit()

func set_ui_scale(scale: String):
	if scale in ui_scale_values:
		settings["ui_scale"] = scale
		apply_ui_scale()
		save_settings()
		settings_changed.emit()

func apply_settings():
	apply_audio_settings()
	apply_ui_scale()

func apply_audio_settings():
	# Set master volume
	AudioServer.set_bus_volume_db(0, linear_to_db(settings["master_volume"]))
	
	# Music bus (assuming we have one)
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_mute(music_bus, not settings["music_enabled"])
	
	# SFX bus (assuming we have one)
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		AudioServer.set_bus_mute(sfx_bus, not settings["sfx_enabled"])

func apply_ui_scale():
	var scale_value: float = ui_scale_values[settings["ui_scale"]]
	# Godot 4.2+: use SceneTree content scale APIs (no DisplayServer constants)
	var tree := get_tree()
	tree.content_scale_mode = SceneTree.STRETCH_MODE_CANVAS_ITEMS
	tree.content_scale_aspect = SceneTree.STRETCH_ASPECT_KEEP
	tree.content_scale_factor = scale_value

func get_setting(key: String):
	return settings.get(key, null)

func get_ui_scale_value():
	return ui_scale_values[settings["ui_scale"]]