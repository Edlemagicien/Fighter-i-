extends CanvasLayer

signal resume_requested
signal quit_requested

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Center/Panel/VBox/ResumeButton.pressed.connect(func(): resume_requested.emit())
	$Center/Panel/VBox/QuitButton.pressed.connect(func(): quit_requested.emit())
	$Center/Panel/VBox/ResumeButton.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		resume_requested.emit()
