extends Button

signal character_pressed(slot: Node, character_scene: PackedScene)

@export var preview_texture: TextureRect
@export var name_label: Label

var _character_scene: PackedScene = null

func setup(
	display_name: String = "",
	character_scene: PackedScene = null,
	preview: Texture2D = null
) -> void:
	_character_scene = character_scene

	if character_scene == null:
		if name_label != null:
			name_label.text = ""

		if preview_texture != null:
			preview_texture.texture = null

		modulate = Color(0.6, 0.6, 0.6, 1.0)
		disabled = true
		return

	if name_label != null:
		name_label.text = display_name

	if preview_texture != null:
		preview_texture.texture = preview

	modulate = Color(1.0, 1.0, 1.0, 1.0)
	disabled = false

func set_selected(player: int) -> void:
	if player == 1:
		modulate = Color(0.5, 0.5, 1.0, 1.0) # Bleu pour J1
	elif player == 2:
		modulate = Color(1.0, 0.5, 0.5, 1.0) # Rouge pour J2
	elif player == 3:
		modulate = Color(1.0, 0.5, 1.0, 1.0) # Les deux sélectionnés
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0) # Défaut

func _pressed() -> void:
	if _character_scene == null:
		return

	character_pressed.emit(self, _character_scene)
