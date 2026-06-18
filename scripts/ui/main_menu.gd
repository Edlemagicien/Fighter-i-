extends Control

signal play_requested(source_id: StringName, source_node: Node)
signal settings_requested(source_id: StringName, source_node: Node)
signal quit_requested(source_id: StringName, source_node: Node)

@export var play_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var p1_score_label: Label
@export var p2_score_label: Label

var _is_transitioning: bool = false

# Initialisation du menu principal :
# on met à jour l'affichage des scores, on connecte les boutons
# et on prépare la navigation clavier/manette.
func _ready() -> void:
	p1_score_label.text = "- Joueur 1 : " + str(GameData.p1_wins)
	p2_score_label.text = "- Joueur 2 : " + str(GameData.p2_wins)

	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	play_button.grab_focus()

# Le menu principal ne change pas lui-même les scènes :
# il envoie des requêtes au scene manager avec un identifiant stable
# et le noeud source pour faciliter le debug et les évolutions futures.
func _on_play_pressed() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	play_requested.emit(&"main_menu", self)

func _on_settings_pressed() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	settings_requested.emit(&"main_menu", self)

func _on_quit_pressed() -> void:
	quit_requested.emit(&"main_menu", self)

# Raccourci clavier/manette :
# on redirige l'action "ui_cancel" vers la même logique que le bouton quitter.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_quit_pressed()
