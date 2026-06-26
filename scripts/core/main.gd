extends Node

const SPLASH_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/splash_screen.tscn")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const SETTINGS_MENU_SCENE: PackedScene = preload("res://scenes/ui/settings_menu.tscn")
const STAGE_SELECT_MENU_SCENE: PackedScene = preload("res://scenes/ui/stage_select_menu.tscn")
const CHARACTER_SELECT_MENU_SCENE: PackedScene = preload("res://scenes/ui/character_select_menu.tscn")
const MATCH_RULES_MENU_SCENE: PackedScene = preload("res://scenes/ui/match_rules_menu.tscn")
const VICTORY_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/victory_screen.tscn")

@onready var stage: Node = $Stage
@onready var screens: CanvasLayer = $Screens
@onready var music_player: AudioStreamPlayer = $BGMPlayer
@export var transition_rect: ColorRect

@export var music_splash: AudioStream
@export var music_menu: AudioStream

var current_screen: Node = null
var current_stage: Node = null
var selected_stage_scene: PackedScene = null

func _play_music(stream: AudioStream) -> void:
	if stream == null or music_player.stream == stream:
		return
	var tween = get_tree().create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, 0.5)
	await tween.finished
	music_player.stream = stream
	music_player.volume_db = 0.0
	music_player.play()

func _transition_to(callable: Callable) -> void:
	if transition_rect == null:
		callable.call()
		return
		
	transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween_out = get_tree().create_tween()
	tween_out.tween_property(transition_rect, "color:a", 1.0, 0.3)
	await tween_out.finished
	
	callable.call()
	
	var tween_in = get_tree().create_tween()
	tween_in.tween_property(transition_rect, "color:a", 0.0, 0.3)
	await tween_in.finished
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_show_splash_screen()

func _replace_child(container: Node, current_child: Node, scene_resource: PackedScene) -> Node:
	if current_child != null:
		current_child.queue_free()

	var new_child: Node = scene_resource.instantiate()
	container.add_child(new_child)
	return new_child

func _connect_if_exists(node: Node, signal_name: StringName, callback: Callable) -> void:
	if node.has_signal(signal_name):
		node.connect(signal_name, callback)

func _show_screen(scene_resource: PackedScene) -> Node:
	current_screen = _replace_child(screens, current_screen, scene_resource)
	return current_screen

func _show_stage(scene_resource: PackedScene) -> Node:
	current_stage = _replace_child(stage, current_stage, scene_resource)
	_connect_if_exists(current_stage, &"exit_requested", _on_stage_exit_requested)
	_connect_if_exists(current_stage, &"match_finished", _on_match_finished)
	return current_stage

func _show_splash_screen() -> void:
	_play_music(music_splash)
	var splash_screen: Node = _show_screen(SPLASH_SCREEN_SCENE)
	_connect_if_exists(splash_screen, &"finished", _on_splash_finished)

func _show_main_menu() -> void:
	_play_music(music_menu)
	var main_menu: Node = _show_screen(MAIN_MENU_SCENE)
	_connect_if_exists(main_menu, &"play_requested", _on_play_requested)
	_connect_if_exists(main_menu, &"settings_requested", _on_settings_requested)
	_connect_if_exists(main_menu, &"quit_requested", _on_quit_requested)

func _show_settings_menu() -> void:
	var settings_menu: Node = _show_screen(SETTINGS_MENU_SCENE)
	_connect_if_exists(settings_menu, &"back_requested", _on_settings_back_requested)

func _show_stage_select_menu() -> void:
	var stage_select_menu: Node = _show_screen(STAGE_SELECT_MENU_SCENE)
	_connect_if_exists(stage_select_menu, &"stage_selected", _on_stage_selected)
	_connect_if_exists(stage_select_menu, &"back_requested", _on_stage_select_back_requested)

func _show_match_rules_menu() -> void:
	var match_rules_menu: Node = _show_screen(MATCH_RULES_MENU_SCENE)
	_connect_if_exists(match_rules_menu, &"next_requested", _on_match_rules_next_requested)
	_connect_if_exists(match_rules_menu, &"back_requested", _on_match_rules_back_requested)

func _show_character_select_menu() -> void:
	var character_select_menu: Node = _show_screen(CHARACTER_SELECT_MENU_SCENE)
	_connect_if_exists(character_select_menu, &"characters_selected", _on_characters_selected)
	_connect_if_exists(character_select_menu, &"back_requested", _on_character_select_back_requested)

func _show_victory_screen() -> void:
	var victory_screen: Node = _show_screen(VICTORY_SCREEN_SCENE)
	_connect_if_exists(victory_screen, &"rematch_requested", _on_victory_rematch_requested)
	_connect_if_exists(victory_screen, &"character_select_requested", _on_victory_character_select_requested)
	_connect_if_exists(victory_screen, &"main_menu_requested", _on_victory_main_menu_requested)

func _start_game() -> void:
	if selected_stage_scene == null:
		return

	if current_screen != null:
		current_screen.queue_free()
		current_screen = null

	_show_stage(selected_stage_scene)

func _return_to_main_menu_from_game() -> void:
	if current_stage != null:
		current_stage.queue_free()
		current_stage = null

	_show_main_menu()

func _on_splash_finished(_source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): _show_main_menu())

func _on_play_requested(_source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): _show_match_rules_menu())

func _on_match_rules_next_requested(_source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): _show_character_select_menu())

func _on_match_rules_back_requested(_source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): _show_main_menu())

func _on_characters_selected(_source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): _show_stage_select_menu())

func _on_character_select_back_requested(_source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): _show_match_rules_menu())

func _on_match_finished(_winner_player: int, _source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): 
		if current_stage != null:
			current_stage.queue_free()
			current_stage = null
		_show_victory_screen()
	)

func _on_victory_rematch_requested(_source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): _start_game())

func _on_victory_character_select_requested(_source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): _show_character_select_menu())

func _on_victory_main_menu_requested(_source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): _show_main_menu())

func _on_settings_requested(_source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): _show_settings_menu())

func _on_settings_back_requested(_source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): _show_main_menu())

func _on_stage_select_back_requested(_source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): _show_character_select_menu())

func _on_stage_selected(stage_scene: PackedScene, _source_id: StringName = &"", _source_node: Node = null) -> void:
	selected_stage_scene = stage_scene
	_transition_to(func(): _start_game())

func _on_stage_exit_requested(_source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): _return_to_main_menu_from_game())

func _on_quit_requested(_source_id: StringName = &"", _source_node: Node = null) -> void:
	_transition_to(func(): get_tree().quit())
