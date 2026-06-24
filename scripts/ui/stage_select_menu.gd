extends Control
signal stage_selected(stage_scene: PackedScene, source_id: StringName, source_node: Node)
signal back_requested(source_id: StringName, source_node: Node)

# On garde ton StageSlot existant !
const STAGE_SLOT_SCENE: PackedScene = preload("res://scenes/ui/stage_slot.tscn")

# Nouveaux exports pour relier notre nouvelle interface
@export var slot_container: CenterContainer
@export var left_button: Button
@export var right_button: Button
@export var back_button: Button

var _is_transitioning: bool = false
var current_index: int = 0
var _on_back_button: bool = false
var active_slot: Node = null

# Ta liste de cartes d'origine
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
	_build_carousel()
	_remove_button_backgrounds()
	if left_button:
		left_button.pressed.connect(_on_left_pressed)
	if right_button:
		right_button.pressed.connect(_on_right_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		
	current_index = 0
	_on_back_button = false
	_update_visuals()

func _remove_button_backgrounds() -> void:
	var empty = StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		if left_button:
			left_button.add_theme_stylebox_override(state, empty)
		if right_button:
			right_button.add_theme_stylebox_override(state, empty)

func _build_carousel() -> void:
	if slot_container == null:
		return
		
	active_slot = STAGE_SLOT_SCENE.instantiate()
	
	active_slot.custom_minimum_size = Vector2(1344, 756)
	
	slot_container.add_child(active_slot)
	
	if active_slot.has_signal("stage_pressed"):
		active_slot.connect("stage_pressed", _on_stage_pressed)

func _update_visuals() -> void:
	if active_slot and active_slot.has_method("setup"):
		var stage_data = stages[current_index]
		# On met à jour l'image et le texte du slot central
		active_slot.setup(stage_data["display_name"], stage_data["scene"], stage_data["preview"])
	if back_button:
		back_button.modulate = Color.YELLOW if _on_back_button else Color.WHITE

func _on_left_pressed() -> void:
	if _is_transitioning: return
	current_index -= 1
	if current_index < 0:
		current_index = stages.size() - 1 # Boucle vers la fin
	_update_visuals()

func _on_right_pressed() -> void:
	if _is_transitioning: return
	current_index += 1
	if current_index >= stages.size():
		current_index = 0 # Boucle vers le début
	_update_visuals()

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

# --- GESTION MANETTE / CLAVIER ---
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
			_update_visuals()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("p1_select"):
			get_viewport().set_input_as_handled()
			_on_back_pressed()
		return

	# Navigation Carrousel (Gauche/Droite) et Retour (Bas)
	if event.is_action_pressed("ui_left"):
		_on_left_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_on_right_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_on_back_button = true
		_update_visuals()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("p1_select"):
		get_viewport().set_input_as_handled()
		if active_slot and active_slot._stage_scene != null:
			_on_stage_pressed(active_slot._stage_scene)
