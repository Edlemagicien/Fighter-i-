extends Control
signal stage_selected(stage_scene: PackedScene, source_id: StringName, source_node: Node)
signal back_requested(source_id: StringName, source_node: Node)

const STAGE_SLOT_SCENE: PackedScene = preload("res://scenes/ui/stage_slot.tscn")

@export var stage_grid: GridContainer
@export var back_button: Button
@export var total_slots: int = 6

var _is_transitioning: bool = false
var _focused_slot_index: int = 0
var _on_back_button: bool = false
var _all_slots: Array[Node] = []
var _grid_columns: int = 3

var stages: Array[Dictionary] = [
	{
		"display_name": "Map lunaire",
		"scene": preload("res://scenes/stages/map_lunaire.tscn"),
		"preview": preload("res://assets/sprites/map lunaire.png")
	},
	{
		"display_name": "Map foret",
		"scene": preload("res://scenes/stages/map_foret.tscn"),
		"preview": preload("res://assets/sprites/map foret.png")
	},
	{
		"display_name": "Map Junia",
		"scene": preload("res://scenes/stages/map_junia.tscn"),
		"preview": preload("res://assets/sprites/map_junia.png")
	}
]

func _ready() -> void:
	_build_stage_grid()
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	_focused_slot_index = 0
	_update_visuals()

func _build_stage_grid() -> void:
	if stage_grid == null:
		return
	for child: Node in stage_grid.get_children():
		child.queue_free()
	_all_slots.clear()
	for stage_data: Dictionary in stages:
		var slot: Node = STAGE_SLOT_SCENE.instantiate()
		stage_grid.add_child(slot)
		if slot.has_method("setup"):
			slot.setup(stage_data["display_name"], stage_data["scene"], stage_data["preview"])
		if slot.has_signal("stage_pressed"):
			slot.connect("stage_pressed", _on_stage_pressed)
		_all_slots.append(slot)
	var empty_count: int = max(total_slots - stages.size(), 0)
	for i: int in range(empty_count):
		var empty_slot: Node = STAGE_SLOT_SCENE.instantiate()
		stage_grid.add_child(empty_slot)
		if empty_slot.has_method("setup"):
			empty_slot.setup()
		_all_slots.append(empty_slot)

func _update_visuals() -> void:
	for i in range(_all_slots.size()):
		var slot = _all_slots[i]
		if not _on_back_button and i == _focused_slot_index:
			slot.modulate = Color(1.0, 1.0, 0.5, 1.0)
		else:
			if slot._stage_scene == null:
				slot.modulate = Color(0.6, 0.6, 0.6, 1.0)
			else:
				slot.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if back_button:
		back_button.modulate = Color.YELLOW if _on_back_button else Color.WHITE

func _on_stage_pressed(stage_scene: PackedScene) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	stage_selected.emit(stage_scene, &"stage_select_menu", self)

func _on_back_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	back_requested.emit(&"stage_select_menu", self)

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
		return

	# Si le curseur est sur le bouton Retour
	if _on_back_button:
		if event.is_action_pressed("ui_up"):
			_on_back_button = false
			_focused_slot_index = _all_slots.size() - 1
			_update_visuals()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("p1_select"):
			get_viewport().set_input_as_handled()
			_on_back_pressed()
		return

	# Navigation dans la grille
	var moved := false
	if event.is_action_pressed("ui_right"):
		var current_row = _focused_slot_index / _grid_columns
		var new_index = _focused_slot_index + 1
		if new_index / _grid_columns == current_row:
			_focused_slot_index = new_index
			moved = true
	elif event.is_action_pressed("ui_left"):
		var current_row = _focused_slot_index / _grid_columns
		var new_index = _focused_slot_index - 1
		if new_index >= 0 and new_index / _grid_columns == current_row:
			_focused_slot_index = new_index
			moved = true
	elif event.is_action_pressed("ui_down"):
		if _focused_slot_index + _grid_columns >= _all_slots.size():
			_on_back_button = true
			_update_visuals()
			get_viewport().set_input_as_handled()
			return
		else:
			_focused_slot_index = _focused_slot_index + _grid_columns
			moved = true
	elif event.is_action_pressed("ui_up"):
		var new_index = _focused_slot_index - _grid_columns
		if new_index >= 0:
			_focused_slot_index = new_index
			moved = true

	if moved:
		_update_visuals()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("p1_select"):
		get_viewport().set_input_as_handled()
		if _focused_slot_index < _all_slots.size():
			var slot = _all_slots[_focused_slot_index]
			if slot._stage_scene != null:
				_on_stage_pressed(slot._stage_scene)
