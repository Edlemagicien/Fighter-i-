extends Button

# Signal envoyé au menu de sélection quand ce slot représente une map valide et qu'il est pressé.
signal stage_pressed(stage_scene: PackedScene)

# Références vers les éléments visuels du slot.
@export var preview_texture: TextureRect
@export var name_label: Label

# Stocke la scène associée au slot actuel.
# Si elle est nulle, le slot est considéré comme vide.
var _stage_scene: PackedScene = null

# Configure le slot avec ses données visuelles et sa scène.
# Si aucune scène n'est fournie, le slot devient une case vide désactivée.
func setup(
	display_name: String = "",
	stage_scene: PackedScene = null,
	preview: Texture2D = null
) -> void:
	_stage_scene = stage_scene
	if stage_scene == null:
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
		# Force toutes les images à la même taille
		preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	disabled = false
# Quand le bouton est pressé on envoie la scène de la map seulement si ce slot correspond à une map valide.
func _pressed() -> void:
	if _stage_scene == null:
		return

	stage_pressed.emit(_stage_scene)
