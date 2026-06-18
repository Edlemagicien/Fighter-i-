extends Control

signal stage_selected(stage_scene: PackedScene, source_id: StringName, source_node: Node)
signal back_requested(source_id: StringName, source_node: Node)

const STAGE_SLOT_SCENE: PackedScene = preload("res://scenes/ui/stage_slot.tscn")

@export var stage_grid: GridContainer
@export var back_button: Button
@export var total_slots: int = 6

var _is_transitioning: bool = false

# --- VARIABLES POUR LE JOYSTICK ARCADE ---
var _focused_slot_index: int = 0
var _all_slots: Array[Node] = []
var _grid_columns: int = 3 # Change ce chiffre si ta grille a un nombre différent de colonnes

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
		
	# Initialiser le curseur sur la première map
	_focused_slot_index = 0
	_update_focused_slot()

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
			slot.setup(
				stage_data["display_name"],
				stage_data["scene"],
				stage_data["preview"]
			)

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

# --- MISE EN SURBRILLANCE DE LA MAP ---
func _update_focused_slot() -> void:
	for i in range(_all_slots.size()):
		var slot = _all_slots[i]
		if i == _focused_slot_index:
			# Légèrement jaune pour montrer où est le curseur (comme pour les persos)
			slot.modulate = Color(1.0, 1.0, 0.5, 1.0)
		else:
			if slot._stage_scene == null:
				slot.modulate = Color(0.6, 0.6, 0.6, 1.0) # Gris si vide
			else:
				slot.modulate = Color(1.0, 1.0, 1.0, 1.0) # Normal

func _on_stage_pressed(stage_scene: PackedScene) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	stage_selected.emit(stage_scene, &"stage_select_menu", self)

func _on_back_pressed() -> void:
	if _is_transitioning:
		return
	back_requested.emit(&"stage_select_menu", self)

# --- GESTION DU JOYSTICK ET DES BOUTONS ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
		return

	# Déplacements dans la grille
	var moved := false
	if event.is_action_pressed("ui_right"):
		_focused_slot_index = min(_focused_slot_index + 1, _all_slots.size() - 1)
		moved = true
	elif event.is_action_pressed("ui_left"):
		_focused_slot_index = max(_focused_slot_index - 1, 0)
		moved = true
	elif event.is_action_pressed("ui_down"):
		_focused_slot_index = min(_focused_slot_index + _grid_columns, _all_slots.size() - 1)
		moved = true
	elif event.is_action_pressed("ui_up"):
		_focused_slot_index = max(_focused_slot_index - _grid_columns, 0)
		moved = true

	if moved:
		get_viewport().set_input_as_handled()
		_update_focused_slot()
		return

	# Valider le choix avec le bouton d'action
	if event.is_action_pressed("select_ui"):
		get_viewport().set_input_as_handled()
		if _focused_slot_index < _all_slots.size():
			var slot = _all_slots[_focused_slot_index]
			if not slot.disabled and slot._stage_scene != null:
				_on_stage_pressed(slot._stage_scene)
