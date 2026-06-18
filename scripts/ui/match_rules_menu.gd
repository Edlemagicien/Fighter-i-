extends Control

signal next_requested(source_id: StringName, source_node: Node)
signal back_requested(source_id: StringName, source_node: Node)

@export var stocks_label: Label
@export var time_label: Label
@export var stocks_minus_btn: Button
@export var stocks_plus_btn: Button
@export var time_minus_btn: Button
@export var time_plus_btn: Button
@export var next_button: Button
@export var back_button: Button

var available_times = [60, 180, 300, 0] # 1 min, 3 min, 5 min, Infinite (0)
var current_time_index = 1 # Default to 180 (3 min)

func _ready() -> void:
	_update_ui()
	
	if stocks_minus_btn: stocks_minus_btn.pressed.connect(_on_stocks_minus)
	if stocks_plus_btn: stocks_plus_btn.pressed.connect(_on_stocks_plus)
	if time_minus_btn: time_minus_btn.pressed.connect(_on_time_minus)
	if time_plus_btn: time_plus_btn.pressed.connect(_on_time_plus)
	
	if next_button: next_button.pressed.connect(_on_next_pressed)
	if back_button: back_button.pressed.connect(_on_back_pressed)
	
	if next_button: next_button.grab_focus()

func _update_ui() -> void:
	if stocks_label:
		stocks_label.text = str(GameData.stock_count)
		
	if time_label:
		var t = GameData.match_time
		if t == 0:
			time_label.text = "Infini"
		else:
			time_label.text = str(int(t / 60.0)) + " Min"

func _on_stocks_minus() -> void:
	if GameData.stock_count > 1:
		GameData.stock_count -= 1
		_update_ui()

func _on_stocks_plus() -> void:
	if GameData.stock_count < 99:
		GameData.stock_count += 1
		_update_ui()

func _on_time_minus() -> void:
	current_time_index -= 1
	if current_time_index < 0:
		current_time_index = available_times.size() - 1
	GameData.match_time = available_times[current_time_index]
	_update_ui()

func _on_time_plus() -> void:
	current_time_index += 1
	if current_time_index >= available_times.size():
		current_time_index = 0
	GameData.match_time = available_times[current_time_index]
	_update_ui()

func _on_next_pressed() -> void:
	next_requested.emit(&"match_rules_menu", self)

func _on_back_pressed() -> void:
	back_requested.emit(&"match_rules_menu", self)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
