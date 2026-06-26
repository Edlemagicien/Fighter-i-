extends Control
class_name SettingsMenu

signal back_requested(source_id: StringName, source_node: Node)

@export var master_volume_slider: HSlider
@export var music_volume_slider: HSlider
@export var sfx_volume_slider: HSlider
@export var ui_volume_slider: HSlider
@export var fullscreen_check_box: CheckBox
@export var back_button: Button

@export var audio_panel: Control
@export var controls_panel: Control
@export var controls_button: Button

@export var profile_option_p1: OptionButton
@export var profile_option_p2: OptionButton
@export var bindings_container_p1: VBoxContainer
@export var bindings_container_p2: VBoxContainer

# ─── LABELS ───────────────────────────────────────────────────────────────────

const ACTION_LABELS := {
	"left":   "← Gauche",
	"right":  "→ Droite",
	"up":     "↑ Haut",
	"down":   "↓ Bas",
	"jump":   "Saut",
	"attack": "Attaque",
	"smash":  "Smash",
	"melee":  "Mêlée",
	"shield": "Bouclier",
	"select": "Valider",
}

var PROFILE_LABELS := {
	"arcade1": "Borne Arcade 1",
	"arcade2": "Borne Arcade 2",
	"manette": "Manette",
	"clavier": "Clavier",
	"custom":  "Personnalisé",
}
var PROFILES: Array[String] = ["arcade1", "arcade2", "manette", "clavier", "custom"]

# ─── NOMS DE BOUTONS PAR PLATEFORME ───────────────────────────────────────────
# Godot JoyButton indices → noms lisibles selon détection manette

# Boutons face (JOY_BUTTON_A=0, B=1, X=2, Y=3)
const BTN_NAMES_PS := {
	0: "×",   1: "○",   2: "□",   3: "△",
	4: "L1",  5: "R1",  6: "L2",  7: "R2",
	8: "Select / Share", 9: "Start / Options",
	10: "L3", 11: "R3",
	12: "↑",  13: "↓",  14: "←",  15: "→",
	16: "Guide",
}
const BTN_NAMES_XBOX := {
	0: "A",   1: "B",   2: "X",   3: "Y",
	4: "LB",  5: "RB",  6: "LT",  7: "RT",
	8: "Back / View",   9: "Start / Menu",
	10: "LS", 11: "RS",
	12: "↑",  13: "↓",  14: "←",  15: "→",
	16: "Guide",
}
const BTN_NAMES_NINTENDO := {
	0: "B",   1: "A",   2: "Y",   3: "X",
	4: "L",   5: "R",   6: "ZL",  7: "ZR",
	8: "−",   9: "+",
	10: "LS", 11: "RS",
	12: "↑",  13: "↓",  14: "←",  15: "→",
	16: "Home",
}

const AXIS_NAMES := {
	0: "Stick G. H",
	1: "Stick G. V",
	2: "Stick D. H",
	3: "Stick D. V",
	4: "L2 / LT",
	5: "R2 / RT",
}

# ─── ÉTAT INTERNE ─────────────────────────────────────────────────────────────

var _remapping_player:  int    = 0
var _remapping_action:  String = ""
var _remapping_button:  Button = null
var _is_remapping:      bool   = false
var _binding_buttons: Dictionary = { 1: {}, 2: {} }

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Audio sliders
	_setup_slider(master_volume_slider)
	_setup_slider(music_volume_slider)
	_setup_slider(sfx_volume_slider)
	_setup_slider(ui_volume_slider)

	if master_volume_slider:
		master_volume_slider.value = SettingsData.master_volume
		master_volume_slider.value_changed.connect(_on_master_volume_changed)
	if music_volume_slider:
		music_volume_slider.value = SettingsData.music_volume
		music_volume_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_volume_slider:
		sfx_volume_slider.value = SettingsData.sfx_volume
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	if ui_volume_slider:
		ui_volume_slider.value = SettingsData.ui_volume
		ui_volume_slider.value_changed.connect(_on_ui_volume_changed)

	if fullscreen_check_box:
		fullscreen_check_box.button_pressed = SettingsData.fullscreen
		fullscreen_check_box.toggled.connect(_on_fullscreen_toggled)

	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if controls_button:
		controls_button.pressed.connect(_show_controls_panel)

	# Contrôles
	_build_profile_options(profile_option_p1, 1)
	_build_profile_options(profile_option_p2, 2)
	_build_bindings_ui(1)
	_build_bindings_ui(2)
	_refresh_all_labels()

	_show_audio_panel()

# ─── NAVIGATION PANNEAUX ──────────────────────────────────────────────────────

func _show_audio_panel() -> void:
	if audio_panel:    audio_panel.visible    = true
	if controls_panel: controls_panel.visible = false
	if controls_button: controls_button.visible = true
	# Focus sur le premier slider disponible, sinon back_button
	if master_volume_slider:
		master_volume_slider.grab_focus()
	elif back_button:
		back_button.grab_focus()

func _show_controls_panel() -> void:
	if audio_panel:     audio_panel.visible    = false
	if controls_panel:  controls_panel.visible = true
	if controls_button: controls_button.visible = false
	# Focus sur le premier OptionButton
	if profile_option_p1:
		profile_option_p1.grab_focus()

# ─── AUDIO ────────────────────────────────────────────────────────────────────

func _setup_slider(slider: HSlider) -> void:
	if slider == null:
		return
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.focus_mode = Control.FOCUS_ALL

func _on_master_volume_changed(value: float) -> void: SettingsData.set_master_volume(value)
func _on_music_volume_changed(value: float)  -> void: SettingsData.set_music_volume(value)
func _on_sfx_volume_changed(value: float)    -> void: SettingsData.set_sfx_volume(value)
func _on_ui_volume_changed(value: float)     -> void: SettingsData.set_ui_volume(value)
func _on_fullscreen_toggled(toggled_on: bool) -> void: SettingsData.set_fullscreen(toggled_on)

# ─── CONTRÔLES UI ─────────────────────────────────────────────────────────────

func _build_profile_options(option: OptionButton, player: int) -> void:
	if option == null:
		return
	option.clear()
	option.focus_mode = Control.FOCUS_ALL
	for i in PROFILES.size():
		option.add_item(PROFILE_LABELS[PROFILES[i]], i)
		option.set_item_metadata(i, PROFILES[i])
	var current: String = SettingsData.profile_p1 if player == 1 else SettingsData.profile_p2
	for i in PROFILES.size():
		if PROFILES[i] == current:
			option.selected = i
			break
	option.item_selected.connect(_on_profile_selected.bind(player))

func _build_bindings_ui(player: int) -> void:
	var container: VBoxContainer = bindings_container_p1 if player == 1 else bindings_container_p2
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()
	_binding_buttons[player] = {}

	for action_suffix in SettingsData.PLAYER_ACTIONS:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var lbl := Label.new()
		lbl.text = ACTION_LABELS.get(action_suffix, action_suffix)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_constant_override("outline_size", 3)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		row.add_child(lbl)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 0)
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_binding_button_pressed.bind(player, action_suffix, btn))
		row.add_child(btn)

		container.add_child(row)
		_binding_buttons[player][action_suffix] = btn

func _refresh_all_labels() -> void:
	_refresh_player_labels(1)
	_refresh_player_labels(2)

func _refresh_player_labels(player: int) -> void:
	var mapping: Dictionary = SettingsData.get_current_mapping(player)
	for action_suffix in SettingsData.PLAYER_ACTIONS:
		var btn: Button = _binding_buttons[player].get(action_suffix)
		if btn == null:
			continue
		var event: InputEvent = mapping.get(action_suffix)
		btn.text = _event_to_string(event)
	var profile: String = SettingsData.profile_p1 if player == 1 else SettingsData.profile_p2
	var editable: bool = (profile == "custom")
	for action_suffix in _binding_buttons[player]:
		_binding_buttons[player][action_suffix].disabled = not editable

# ─── DÉTECTION PLATEFORME MANETTE ─────────────────────────────────────────────

enum JoyPlatform { UNKNOWN, PLAYSTATION, XBOX, NINTENDO }

func _detect_joy_platform(device: int) -> JoyPlatform:
	var name: String = Input.get_joy_name(device).to_lower()
	if "dualshock" in name or "dualsense" in name or "playstation" in name or "ps3" in name \
			or "ps4" in name or "ps5" in name or "sony" in name:
		return JoyPlatform.PLAYSTATION
	if "xbox" in name or "xinput" in name or "microsoft" in name:
		return JoyPlatform.XBOX
	if "nintendo" in name or "switch" in name or "joycon" in name or "pro controller" in name:
		return JoyPlatform.NINTENDO
	return JoyPlatform.UNKNOWN

func _joy_button_name(button_index: int, device: int) -> String:
	var platform := _detect_joy_platform(device)
	var table: Dictionary
	match platform:
		JoyPlatform.PLAYSTATION: table = BTN_NAMES_PS
		JoyPlatform.XBOX:        table = BTN_NAMES_XBOX
		JoyPlatform.NINTENDO:    table = BTN_NAMES_NINTENDO
		_:
			# Inconnu → nom générique
			return "Btn %d" % button_index
	return table.get(button_index, "Btn %d" % button_index)

func _joy_axis_name(axis: int, positive: bool) -> String:
	var base: String = AXIS_NAMES.get(axis, "Axe %d" % axis)
	return "%s %s" % [base, "+" if positive else "−"]

# ─── CONVERSION EVENT → TEXTE ─────────────────────────────────────────────────

func _event_to_string(event: InputEvent) -> String:
	if event == null:
		return "—"
	if event is InputEventKey:
		return OS.get_keycode_string(event.physical_keycode)
	if event is InputEventJoypadButton:
		var dev: int = event.device if event.device >= 0 else 0
		return _joy_button_name(event.button_index, dev)
	if event is InputEventJoypadMotion:
		return _joy_axis_name(event.axis, event.axis_value > 0)
	return event.as_text()

# ─── REMAPPING ────────────────────────────────────────────────────────────────

func _on_binding_button_pressed(player: int, action_suffix: String, btn: Button) -> void:
	if _is_remapping:
		return
	_is_remapping     = true
	_remapping_player = player
	_remapping_action = action_suffix
	_remapping_button = btn
	btn.text = "[ Appuyez... ]"

func _input(event: InputEvent) -> void:
	if not _is_remapping:
		return
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		return
	if not event.pressed:
		return

	# Échap / Start / Guide = annuler
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		_cancel_remapping()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START:
		_cancel_remapping()
		get_viewport().set_input_as_handled()
		return

	# Appliquer le nouveau binding
	SettingsData.set_custom_binding(_remapping_player, _remapping_action, event)

	# Mettre à jour l'InputMap Godot en temps réel
	_apply_binding_to_input_map(_remapping_player, _remapping_action, event)

	# Passer automatiquement en profil "custom" si ce n'était pas déjà le cas
	var current_profile: String = SettingsData.profile_p1 if _remapping_player == 1 else SettingsData.profile_p2
	if current_profile != "custom":
		SettingsData.set_profile(_remapping_player, "custom")
		_sync_profile_option(_remapping_player)

	_is_remapping = false
	_refresh_player_labels(_remapping_player)
	if _remapping_button:
		_remapping_button.grab_focus()
	get_viewport().set_input_as_handled()

func _cancel_remapping() -> void:
	if _remapping_button:
		var mapping: Dictionary = SettingsData.get_current_mapping(_remapping_player)
		var event: InputEvent = mapping.get(_remapping_action)
		_remapping_button.text = _event_to_string(event)
		_remapping_button.grab_focus()
	_is_remapping = false

# ─── APPLICATION INPUTMAP ─────────────────────────────────────────────────────

func _apply_binding_to_input_map(player: int, action_suffix: String, new_event: InputEvent) -> void:
	# Convention de nommage : "p1_jump", "p2_attack", etc.
	var action_name: String = "p%d_%s" % [player, action_suffix]
	if not InputMap.has_action(action_name):
		# Créer l'action si elle n'existe pas encore
		InputMap.add_action(action_name)

	# Retirer tous les events existants du même type pour cette action
	# (on garde les autres types, ex: si l'action a aussi un event clavier)
	var to_remove: Array[InputEvent] = []
	for ev in InputMap.action_get_events(action_name):
		if ev.get_class() == new_event.get_class():
			to_remove.append(ev)
	for ev in to_remove:
		InputMap.action_erase_event(action_name, ev)

	InputMap.action_add_event(action_name, new_event)

func _apply_full_mapping_to_input_map(player: int) -> void:
	var mapping: Dictionary = SettingsData.get_current_mapping(player)
	for action_suffix in SettingsData.PLAYER_ACTIONS:
		var event: InputEvent = mapping.get(action_suffix)
		if event != null:
			_apply_binding_to_input_map(player, action_suffix, event)

# ─── PROFIL ───────────────────────────────────────────────────────────────────

func _on_profile_selected(index: int, player: int) -> void:
	var option: OptionButton = profile_option_p1 if player == 1 else profile_option_p2
	var profile: String = option.get_item_metadata(index)
	SettingsData.set_profile(player, profile)
	_refresh_player_labels(player)
	# Appliquer le nouveau profil à l'InputMap
	_apply_full_mapping_to_input_map(player)

func _sync_profile_option(player: int) -> void:
	var option: OptionButton = profile_option_p1 if player == 1 else profile_option_p2
	if option == null:
		return
	var current: String = SettingsData.profile_p1 if player == 1 else SettingsData.profile_p2
	for i in option.item_count:
		if option.get_item_metadata(i) == current:
			option.selected = i
			break

# ─── NAVIGATION BACK ──────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	if _is_remapping:
		_cancel_remapping()
		return
	if controls_panel and controls_panel.visible:
		_show_audio_panel()
		return
	back_requested.emit(&"settings_menu", self)

func _unhandled_input(event: InputEvent) -> void:
	if _is_remapping:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
