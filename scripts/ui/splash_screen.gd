extends Control

signal finished(source_id: StringName, source_node: Node)

@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Évite un double signal si plusieurs inputs arrivent en même temps pendant la transition.
var _is_transitioning: bool = false

# Initialisation du splash screen :
# on ignore la souris pour ne pas interférer avec le skip, on connecte le signal d'animation
# et on lance l'animation "splash" qui doit exister dans l'AnimationPlayer.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	animation_player.play("splash")

# Gestion des inputs pour le skip :
# accepte clavier, souris et manette, mais seulement si pas déjà en transition.
# AnimationPlayer ne reçoit pas l'input car mouse_filter=IGNORE.
func _input(event: InputEvent) -> void:
	if _is_transitioning:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		_finish()
	elif event is InputEventMouseButton and event.pressed:
		_finish()
	elif event is InputEventJoypadButton and event.pressed:
		_finish()

# Fin automatique de l'animation :
# quand "splash" se termine, on déclenche la transition vers le menu principal.
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "splash":
		_finish()

func _finish() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	finished.emit(&"splash_screen", self)
