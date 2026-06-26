extends Node

# ─── AUDIO ────────────────────────────────────────────────────────────────────

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_MASTER_VOLUME: float = 0.50
const DEFAULT_MUSIC_VOLUME:  float = 0.50
const DEFAULT_SFX_VOLUME:    float = 0.50
const DEFAULT_UI_VOLUME:     float = 0.50
const DEFAULT_FULLSCREEN:    bool  = true

var master_volume: float = DEFAULT_MASTER_VOLUME
var music_volume:  float = DEFAULT_MUSIC_VOLUME
var sfx_volume:    float = DEFAULT_SFX_VOLUME
var ui_volume:     float = DEFAULT_UI_VOLUME
var fullscreen:    bool  = DEFAULT_FULLSCREEN

func _ready() -> void:
	load_settings()
	apply_settings()

func reset_to_defaults() -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	music_volume  = DEFAULT_MUSIC_VOLUME
	sfx_volume    = DEFAULT_SFX_VOLUME
	ui_volume     = DEFAULT_UI_VOLUME
	fullscreen    = DEFAULT_FULLSCREEN

func load_settings() -> void:
	reset_to_defaults()
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)
	music_volume  = config.get_value("audio", "music_volume",  DEFAULT_MUSIC_VOLUME)
	sfx_volume    = config.get_value("audio", "sfx_volume",    DEFAULT_SFX_VOLUME)
	ui_volume     = config.get_value("audio", "ui_volume",     DEFAULT_UI_VOLUME)
	fullscreen    = config.get_value("display", "fullscreen",  DEFAULT_FULLSCREEN)
	profile_p1    = config.get_value("controls", "profile_p1", "clavier")
	profile_p2    = config.get_value("controls", "profile_p2", "arcade1")

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume",  music_volume)
	config.set_value("audio", "sfx_volume",    sfx_volume)
	config.set_value("audio", "ui_volume",     ui_volume)
	config.set_value("display", "fullscreen",  fullscreen)
	config.set_value("controls", "profile_p1", profile_p1)
	config.set_value("controls", "profile_p2", profile_p2)
	config.save(SETTINGS_PATH)

func apply_settings() -> void:
	_apply_bus_volume_by_name("Master", master_volume)
	_apply_bus_volume_by_name("Music",  music_volume)
	_apply_bus_volume_by_name("SFX",    sfx_volume)
	_apply_bus_volume_by_name("UI",     ui_volume)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	_apply_bus_volume_by_name("Master", master_volume)
	save_settings()

func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	_apply_bus_volume_by_name("Music", music_volume)
	save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	_apply_bus_volume_by_name("SFX", sfx_volume)
	save_settings()

func set_ui_volume(value: float) -> void:
	ui_volume = clamp(value, 0.0, 1.0)
	_apply_bus_volume_by_name("UI", ui_volume)
	save_settings()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()

func _apply_bus_volume_by_name(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	if value <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

# ─── CONTRÔLES ────────────────────────────────────────────────────────────────

const PLAYER_ACTIONS: Array[String] = [
	"left", "right", "up", "down", "jump", "attack", "smash", "melee", "shield", "select"
]

var profile_p1: String = "clavier"
var profile_p2: String = "arcade1"

var custom_bindings_p1: Dictionary = {}
var custom_bindings_p2: Dictionary = {}

const PRESET_PROFILES: Dictionary = {
	"clavier": {
		"left":   {"type": "key", "keycode": KEY_LEFT},
		"right":  {"type": "key", "keycode": KEY_RIGHT},
		"up":     {"type": "key", "keycode": KEY_UP},
		"down":   {"type": "key", "keycode": KEY_DOWN},
		"jump":   {"type": "key", "keycode": KEY_SPACE},
		"attack": {"type": "key", "keycode": KEY_X},
		"smash":  {"type": "key", "keycode": KEY_C},
		"melee":  {"type": "key", "keycode": KEY_V},
		"shield": {"type": "key", "keycode": KEY_Z},
		"select": {"type": "key", "keycode": KEY_ENTER},
	},
	"manette": {
		"left":   {"type": "axis",   "axis": 0, "value": -1.0, "device": 0},
		"right":  {"type": "axis",   "axis": 0, "value":  1.0, "device": 0},
		"up":     {"type": "axis",   "axis": 1, "value": -1.0, "device": 0},
		"down":   {"type": "axis",   "axis": 1, "value":  1.0, "device": 0},
		"jump":   {"type": "button", "button": JOY_BUTTON_A,            "device": 0},
		"attack": {"type": "button", "button": JOY_BUTTON_X,            "device": 0},
		"smash":  {"type": "button", "button": JOY_BUTTON_Y,            "device": 0},
		"melee":  {"type": "button", "button": JOY_BUTTON_B,            "device": 0},
		"shield": {"type": "button", "button": JOY_BUTTON_LEFT_SHOULDER,"device": 0},
		"select": {"type": "button", "button": JOY_BUTTON_START,        "device": 0},
	},
	"arcade1": {
		"left":   {"type": "key", "keycode": KEY_A},
		"right":  {"type": "key", "keycode": KEY_D},
		"up":     {"type": "key", "keycode": KEY_W},
		"down":   {"type": "key", "keycode": KEY_S},
		"jump":   {"type": "key", "keycode": KEY_T},
		"attack": {"type": "key", "keycode": KEY_Y},
		"smash":  {"type": "key", "keycode": KEY_U},
		"melee":  {"type": "key", "keycode": KEY_G},
		"shield": {"type": "key", "keycode": KEY_H},
		"select": {"type": "key", "keycode": KEY_ENTER},
	},
	"arcade2": {
		"left":   {"type": "key", "keycode": KEY_KP_4},
		"right":  {"type": "key", "keycode": KEY_KP_6},
		"up":     {"type": "key", "keycode": KEY_KP_8},
		"down":   {"type": "key", "keycode": KEY_KP_5},
		"jump":   {"type": "key", "keycode": KEY_KP_7},
		"attack": {"type": "key", "keycode": KEY_KP_9},
		"smash":  {"type": "key", "keycode": KEY_KP_1},
		"melee":  {"type": "key", "keycode": KEY_KP_3},
		"shield": {"type": "key", "keycode": KEY_KP_0},
		"select": {"type": "key", "keycode": KEY_KP_ENTER},
	},
}

func get_current_mapping(player: int) -> Dictionary:
	var profile: String = profile_p1 if player == 1 else profile_p2
	var custom: Dictionary = custom_bindings_p1 if player == 1 else custom_bindings_p2
	if profile == "custom":
		return _custom_dict_to_events(custom)
	return _preset_to_events(profile)

func set_profile(player: int, profile: String) -> void:
	if player == 1:
		profile_p1 = profile
	else:
		profile_p2 = profile
	save_settings()

func set_custom_binding(player: int, action_suffix: String, event: InputEvent) -> void:
	var custom: Dictionary = custom_bindings_p1 if player == 1 else custom_bindings_p2
	if custom.is_empty():
		var profile: String = profile_p1 if player == 1 else profile_p2
		if profile != "custom" and PRESET_PROFILES.has(profile):
			custom = _preset_to_events(profile)
	custom[action_suffix] = event
	if player == 1:
		custom_bindings_p1 = custom
	else:
		custom_bindings_p2 = custom
	save_settings()

func _preset_to_events(profile: String) -> Dictionary:
	var result: Dictionary = {}
	if not PRESET_PROFILES.has(profile):
		return result
	var raw: Dictionary = PRESET_PROFILES[profile]
	for action in raw:
		result[action] = _dict_to_event(raw[action])
	return result

func _custom_dict_to_events(custom: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for action in custom:
		var v = custom[action]
		if v is InputEvent:
			result[action] = v
		elif v is Dictionary:
			result[action] = _dict_to_event(v)
	return result

func _dict_to_event(d: Dictionary) -> InputEvent:
	match d.get("type", ""):
		"key":
			var e := InputEventKey.new()
			e.physical_keycode = d["keycode"]
			return e
		"button":
			var e := InputEventJoypadButton.new()
			e.button_index = d["button"]
			e.device = d.get("device", 0)
			return e
		"axis":
			var e := InputEventJoypadMotion.new()
			e.axis = d["axis"]
			e.axis_value = d["value"]
			e.device = d.get("device", 0)
			return e
	return null
