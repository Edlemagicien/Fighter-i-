extends Control

# Signaux envoyés au scene manager :
signal characters_selected(source_id: StringName, source_node: Node)
signal back_requested(source_id: StringName, source_node: Node)

const CHARACTER_SLOT_SCENE: PackedScene = preload("res://scenes/ui/character_slot.tscn")

@export var character_grid: GridContainer
@export var next_button: Button
@export var back_button: Button
@export var p1_status_label: Label
@export var p2_status_label: Label
@export var total_slots: int = 21

@onready var voice_player : AudioStreamPlayer = $VoicePlayer

var _is_transitioning: bool = false
var _current_selecting_player: int = 1

var _p1_selected_slot: Node = null
var _p2_selected_slot: Node = null

# Navigation joystick
var _focused_slot_index: int = 0
var _all_slots: Array[Node] = []
var _grid_columns: int = 7

var characters: Array[Dictionary] = [
	{
		"display_name": "Benedito",
		"scene": preload("res://scenes/Benedito.tscn"),
		"preview": preload("res://assets/sprites/Personnages/Benedito/Benedito fixe 1.png")
	},
	{
		"display_name": "Dubois",
		"scene": preload("res://scenes/Dubois.tscn"),
		"preview": preload("res://assets/sprites/Personnages/Dubois/dubois marche 1.png")
	},
	{
		"display_name": "El Yaagoubi",
		"scene": preload("res://scenes/ElYaagoubi.tscn"),
		"preview": preload("res://assets/sprites/Personnages/El Yaagoubi/el_yaagoubi_idle1.png")
	},
	{
		"display_name": "Fardoux",
		"scene": preload("res://scenes/Fardoux.tscn"),
		"preview": preload("res://assets/sprites/Personnages/Fardoux/fardoux fixe 1.png")
	},
	{
		"display_name": "Morelle",
		"scene": preload("res://scenes/Morelle.tscn"),
		"preview": preload("res://assets/sprites/Personnages/Morelle/morelle_idle1.webp")
	},
	{
		"display_name": "N Konou",
		"scene": preload("res://scenes/NKounou.tscn"),
		"preview": preload("res://assets/sprites/Personnages/N Kounou/nkounou_idle 2.webp")
	},
	{
		"display_name": "Scottez",
		"scene": preload("res://scenes/Scottez.tscn"),
		"preview": preload("res://assets/sprites/Personnages/Scottez/Scottez fixe 1.png")
	},
	{
		"display_name": "Blandre",
		"scene": preload("res://scenes/Blandre.tscn"),
		"preview": preload("res://assets/sprites/Personnages/Blandre/blandre_idle1.png")
	},
	{
		"display_name": "McGavigan",
		"scene": preload("res://scenes/Mcgavigan.tscn"),
		"preview": preload("res://assets/sprites/Personnages/Mcgavigan/Mcgavigan idle 1.png")
	},
	{
		"display_name": "Mele",
		"scene": preload("res://scenes/Mele.tscn"),
		"preview": preload("res://assets/sprites/Personnages/Mele/Mele_idle1.png")
	},
	{
		"display_name": "Deleplanque",
		"scene": preload("res://scenes/Deleplanque.tscn"),
		"preview": preload("res://assets/sprites/Personnages/Deleplanque/Samuel_iddle1.png")
	},
	{
		"display_name": "Philippe",
		"scene": preload("res://scenes/Justine.tscn"),
		"preview": preload("res://assets/sprites/Personnages/Justine/Justine_idle1.png")
	},
	{
		"display_name": "Veillon",
		"scene": preload("res://scenes/LiseMarie.tscn"),
		"preview": preload("res://assets/sprites/Personnages/Lise-Marie/lmv_idle1.png")
	}
]

func _ready() -> void:
	_build_character_grid()
	
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
		next_button.disabled = true # Disabled until both characters are selected
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		
	_update_ui()

	# Focus le premier slot valide pour la navigation joystick
	_focused_slot_index = 0
	_update_focused_slot()

func _update_ui() -> void:
	if p1_status_label:
		if _p1_selected_slot:
			p1_status_label.text = "J1 : " + _p1_selected_slot.name_label.text
		else:
			p1_status_label.text = "J1 : En attente..."
		
	if p2_status_label:
		if _p2_selected_slot:
			p2_status_label.text = "J2 : " + _p2_selected_slot.name_label.text
		else:
			p2_status_label.text = "J2 : En attente..."
		
	if next_button:
		next_button.disabled = _p1_selected_slot == null or _p2_selected_slot == null

func _build_character_grid() -> void:
	if character_grid == null:
		return
		
	for child: Node in character_grid.get_children():
		child.queue_free()

	_all_slots.clear()

	for i in range(characters.size()):
		var char_data: Dictionary = characters[i]
		var slot: Node = CHARACTER_SLOT_SCENE.instantiate()
		character_grid.add_child(slot)

		if slot.has_method("setup"):
			slot.setup(
				char_data["display_name"],
				char_data["scene"],
				char_data["preview"]
			)

		if slot.has_signal("character_pressed"):
			slot.connect("character_pressed", _on_character_pressed)

		_all_slots.append(slot)

	var empty_count: int = max(total_slots - characters.size(), 0)
	for i: int in range(empty_count):
		var empty_slot: Node = CHARACTER_SLOT_SCENE.instantiate()
		character_grid.add_child(empty_slot)
		if empty_slot.has_method("setup"):
			empty_slot.setup()

func _update_focused_slot() -> void:
	# Retire le highlight de focus de tous les slots
	for i in range(_all_slots.size()):
		var slot = _all_slots[i]
		if slot == _p1_selected_slot and slot == _p2_selected_slot:
			slot.set_selected(3)
		elif slot == _p1_selected_slot:
			slot.set_selected(1)
		elif slot == _p2_selected_slot:
			slot.set_selected(2)
		elif i == _focused_slot_index:
			# Outline/teinte de focus : légèrement jaune
			slot.modulate = Color(1.0, 1.0, 0.5, 1.0)
		else:
			slot.set_selected(0)

func _update_slots_visuals() -> void:
	_update_focused_slot()

func _on_character_pressed(slot: Node, _character_scene: PackedScene) -> void:
	# Jouer la voiceline de sélection
	if _character_scene:
		var temp_char = _character_scene.instantiate()
		if "voice_select" in temp_char and temp_char.voice_select:
			if voice_player:
				voice_player.stream = temp_char.voice_select
				voice_player.play()
		temp_char.queue_free()

	if _current_selecting_player == 1:
		_p1_selected_slot = slot
		_current_selecting_player = 2
	elif _current_selecting_player == 2:
		_p2_selected_slot = slot
		_current_selecting_player = 1
		
	_update_slots_visuals()
	_update_ui()

func _on_next_pressed() -> void:
	if _is_transitioning or _p1_selected_slot == null or _p2_selected_slot == null:
		return
	_is_transitioning = true
	
	var p1_path = _p1_selected_slot._character_scene.resource_path
	var p2_path = _p2_selected_slot._character_scene.resource_path
	
	var p1_idx = GameData.CHARACTER_SCENES.find(p1_path)
	if p1_idx != -1:
		GameData.p1_character_index = p1_idx
		
	var p2_idx = GameData.CHARACTER_SCENES.find(p2_path)
	if p2_idx != -1:
		GameData.p2_character_index = p2_idx
	
	characters_selected.emit(&"character_select_menu", self)

func _on_back_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	back_requested.emit(&"character_select_menu", self)

# ─── Navigation joystick / clavier ───────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
		return

	# Mouvement dans la grille
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

	# Bouton de confirmation (ui_accept = Enter / bouton A / Croix)
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _focused_slot_index < _all_slots.size():
			var slot = _all_slots[_focused_slot_index]
			if not slot.disabled:
				_on_character_pressed(slot, slot._character_scene)
		return
