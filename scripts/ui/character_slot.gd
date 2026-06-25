extends Button

signal character_pressed(slot: Node, character_scene: PackedScene)

@export var preview_texture: TextureRect
@export var name_label: Label

var _character_scene: PackedScene = null
var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat

func _ready() -> void:
	_style_normal = StyleBoxFlat.new()
	_style_normal.bg_color = Color(0.0, 0.0, 0.0, 0.0)  # Transparent
	_style_normal.border_width_left = 2
	_style_normal.border_width_top = 2
	_style_normal.border_width_right = 2
	_style_normal.border_width_bottom = 2
	_style_normal.border_color = Color(0.0, 0.0, 0.0, 0.0)
	
	_style_hover = StyleBoxFlat.new()
	_style_hover.bg_color = Color(0.6, 0.6, 0.6, 1.0)  # Gris opaque
	_style_hover.border_width_left = 2
	_style_hover.border_width_top = 2
	_style_hover.border_width_right = 2
	_style_hover.border_width_bottom = 2
	_style_hover.border_color = Color(0.8, 0.8, 0.8, 1.0)
	
	add_theme_stylebox_override("normal", _style_normal)
	add_theme_stylebox_override("hover", _style_normal)
	add_theme_stylebox_override("pressed", _style_normal)
	add_theme_stylebox_override("focus", _style_normal)
	add_theme_stylebox_override("disabled", _style_normal)

func set_background_active(active: bool) -> void:
	if active:
		add_theme_stylebox_override("normal", _style_hover)
	else:
		add_theme_stylebox_override("normal", _style_normal)
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
		name_label.add_theme_constant_override("outline_size", 6)
		name_label.add_theme_color_override("font_outline_color", Color.BLACK)

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
