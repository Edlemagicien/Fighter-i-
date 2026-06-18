extends Node

const SETTINGS_PATH := "user://settings.cfg"

const DEFAULT_MASTER_VOLUME: float = 0.50
const DEFAULT_MUSIC_VOLUME: float = 0.50
const DEFAULT_SFX_VOLUME: float = 0.50
const DEFAULT_UI_VOLUME: float = 0.50
const DEFAULT_FULLSCREEN: bool = true

var master_volume: float = DEFAULT_MASTER_VOLUME
var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME
var ui_volume: float = DEFAULT_UI_VOLUME
var fullscreen: bool = DEFAULT_FULLSCREEN

func _ready() -> void:
	load_settings()
	apply_settings()

func reset_to_defaults() -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	ui_volume = DEFAULT_UI_VOLUME
	fullscreen = DEFAULT_FULLSCREEN

func load_settings() -> void:
	reset_to_defaults()

	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	master_volume = config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)
	music_volume = config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)
	sfx_volume = config.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME)
	ui_volume = config.get_value("audio", "ui_volume", DEFAULT_UI_VOLUME)
	fullscreen = config.get_value("display", "fullscreen", DEFAULT_FULLSCREEN)

func save_settings() -> void:
	var config := ConfigFile.new()

	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "ui_volume", ui_volume)
	config.set_value("display", "fullscreen", fullscreen)

	config.save(SETTINGS_PATH)

func apply_settings() -> void:
	_apply_bus_volume_by_name("Master", master_volume)
	_apply_bus_volume_by_name("Music", music_volume)
	_apply_bus_volume_by_name("SFX", sfx_volume)
	_apply_bus_volume_by_name("UI", ui_volume)

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
