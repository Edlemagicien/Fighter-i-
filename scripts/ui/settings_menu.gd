extends Control
class_name SettingsMenu

signal back_requested(source_id: StringName, source_node: Node)

@export var master_volume_slider: HSlider
@export var music_volume_slider: HSlider
@export var sfx_volume_slider: HSlider
@export var ui_volume_slider: HSlider
@export var fullscreen_check_box: CheckBox
@export var back_button: Button

func _ready() -> void:
	_setup_slider(master_volume_slider)
	_setup_slider(music_volume_slider)
	_setup_slider(sfx_volume_slider)
	_setup_slider(ui_volume_slider)

	if master_volume_slider:
		master_volume_slider.value = SettingsData.master_volume
	if music_volume_slider:
		music_volume_slider.value = SettingsData.music_volume
	if sfx_volume_slider:
		sfx_volume_slider.value = SettingsData.sfx_volume
	if ui_volume_slider:
		ui_volume_slider.value = SettingsData.ui_volume
	if fullscreen_check_box:
		fullscreen_check_box.button_pressed = SettingsData.fullscreen

	if master_volume_slider:
		master_volume_slider.value_changed.connect(_on_master_volume_changed)
	if music_volume_slider:
		music_volume_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_volume_slider:
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	if ui_volume_slider:
		ui_volume_slider.value_changed.connect(_on_ui_volume_changed)
	if fullscreen_check_box:
		fullscreen_check_box.toggled.connect(_on_fullscreen_toggled)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		back_button.grab_focus()

func _setup_slider(slider: HSlider) -> void:
	if slider == null:
		return
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01

func _on_master_volume_changed(value: float) -> void:
	SettingsData.set_master_volume(value)

func _on_music_volume_changed(value: float) -> void:
	SettingsData.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	SettingsData.set_sfx_volume(value)

func _on_ui_volume_changed(value: float) -> void:
	SettingsData.set_ui_volume(value)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	SettingsData.set_fullscreen(toggled_on)

func _on_back_pressed() -> void:
	back_requested.emit(&"settings_menu", self)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
