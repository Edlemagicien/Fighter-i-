extends Control

signal rematch_requested(source_id: StringName, source_node: Node)
signal character_select_requested(source_id: StringName, source_node: Node)
signal main_menu_requested(source_id: StringName, source_node: Node)

@export var title_label: Label
@export var rematch_button: Button
@export var character_select_button: Button
@export var main_menu_button: Button

func _ready() -> void:
	# Afficher le gagnant
	if GameData.last_winner > 0:
		var char_index = GameData.p1_character_index if GameData.last_winner == 1 else GameData.p2_character_index
		var char_name = GameData.get_character_name(char_index) if char_index < GameData.CHARACTER_NAMES.size() else "Inconnu"
		title_label.text = "JOUEUR " + str(GameData.last_winner) + " GAGNE !\n(" + char_name + ")"
	else:
		title_label.text = "TEMPS ECOULE !\nEGALITE !"

	# Connecter les boutons
	if rematch_button:
		rematch_button.pressed.connect(func(): rematch_requested.emit(&"victory_screen", self))
	if character_select_button:
		character_select_button.pressed.connect(func(): character_select_requested.emit(&"victory_screen", self))
	if main_menu_button:
		main_menu_button.pressed.connect(func(): main_menu_requested.emit(&"victory_screen", self))
	
	if rematch_button:
		rematch_button.grab_focus()
