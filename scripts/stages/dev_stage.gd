extends Node2D

signal exit_requested(source_id: StringName, source_node: Node)
signal match_finished(winner_player: int, source_id: StringName, source_node: Node)

const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")

@export var p1_spawn: Marker2D
@export var p2_spawn: Marker2D
@export var hud: Control

var match_time_left: int = 180
var is_infinite_time: bool = false
var _timer: Timer
var _p1: Node2D
var _p2: Node2D
var _match_over: bool = false
var _pause_menu: Node = null

func _ready() -> void:
	match_time_left = GameData.match_time
	is_infinite_time = (match_time_left <= 0)

	var p1_scene: PackedScene = load(GameData.p1_scene)
	var p2_scene: PackedScene = load(GameData.p2_scene)

	var p1: Node2D = p1_scene.instantiate()
	var p2: Node2D = p2_scene.instantiate()

	_p1 = p1
	_p2 = p2

	p1.set_hud(hud)
	p2.set_hud(hud)

	p1.player_number = 1
	p2.player_number = 2

	add_child(p1)
	add_child(p2)

	p1.global_position = p1_spawn.global_position
	p2.global_position = p2_spawn.global_position

	p1.spawn_point = p1.global_position
	p2.spawn_point = p2.global_position

	p1.player_eliminated.connect(_on_player_eliminated)
	p2.player_eliminated.connect(_on_player_eliminated)

	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.autostart = true
	_timer.timeout.connect(_on_timer_tick)
	add_child(_timer)

	if hud and hud.has_method("update_time"):
		hud.update_time(match_time_left)

func _on_timer_tick() -> void:
	if is_infinite_time:
		return

	match_time_left -= 1
	if hud and hud.has_method("update_time"):
		hud.update_time(match_time_left)

	if match_time_left <= 0:
		_timer.stop()
		if _match_over:
			return
		_match_over = true

		var winner: int = 0
		if _p1 and _p2:
			if _p1.stocks > _p2.stocks:
				winner = 1
			elif _p2.stocks > _p1.stocks:
				winner = 2
			else:
				if _p1.damage_percent < _p2.damage_percent:
					winner = 1
				elif _p2.damage_percent < _p1.damage_percent:
					winner = 2
				else:
					winner = 0

		GameData.last_winner = winner
		if winner == 1:
			GameData.p1_wins += 1
		elif winner == 2:
			GameData.p2_wins += 1

		match_finished.emit(winner, &"dev_stage", self)

func _on_player_eliminated(player_num: int) -> void:
	if _match_over:
		return
	_match_over = true

	_timer.stop()
	var winner: int = 2 if player_num == 1 else 1

	GameData.last_winner = winner
	if winner == 1:
		GameData.p1_wins += 1
	else:
		GameData.p2_wins += 1

	match_finished.emit(winner, &"dev_stage", self)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_toggle_pause()

func _toggle_pause() -> void:
	if _pause_menu != null:
		_on_resume()
		return
	_pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_child(_pause_menu)
	_pause_menu.resume_requested.connect(_on_resume)
	_pause_menu.quit_requested.connect(_on_pause_quit)
	get_tree().paused = true

func _on_resume() -> void:
	get_tree().paused = false
	if _pause_menu:
		_pause_menu.queue_free()
		_pause_menu = null

func _on_pause_quit() -> void:
	get_tree().paused = false
	_pause_menu = null
	exit_requested.emit(&"dev_stage", self)
