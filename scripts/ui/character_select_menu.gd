extends Control

# Signaux envoyés au scene manager :
signal characters_selected(source_id: StringName, source_node: Node)
signal back_requested(source_id: StringName, source_node: Node)

const CHARACTER_SLOT_SCENE: PackedScene = preload("res://scenes/ui/character_slot.tscn")

# Couleurs pour les visuels
const COLOR_P1_SELECTED := Color(0.0, 0.5, 2.0)    # Bleu électrique
const COLOR_P2_SELECTED := Color(2.0, 0.0, 0.0)    # Rouge vif
const COLOR_P1_CURSOR := Color(0.0, 0.09, 0.902, 0.7)
const COLOR_P2_CURSOR :=  Color(0.741, 0.0, 0.169, 0.7)
const COLOR_BOTH_SELECTED := Color(0.506, 0.208, 0.937, 1.0)
const COLOR_BOTH_CURSOR :=Color(0.506, 0.208, 0.937, 0.7)
const COLOR_READY_BUTTON_HOVER := Color.YELLOW
const COLOR_READY_STATE := Color.GREEN

@export var character_grid: GridContainer
@export var ready_button_p1: Button
@export var ready_button_p2: Button
@export var back_button: Button
@export var p1_status_label: Label
@export var p2_status_label: Label
@export var total_slots: int = 13

@onready var voice_player : AudioStreamPlayer = $VoicePlayer

var _is_transitioning: bool = false

# État de sélection de chaque joueur
var _p1_cursor_index: int = 0
var _p2_cursor_index: int = 0
var _p1_selected_slot: Node = null
var _p2_selected_slot: Node = null
var _p1_is_ready: bool = false
var _p2_is_ready: bool = false

# Navigation : si vrai, le joueur est sur son bouton Prêt
var _p1_on_ready_button: bool = false
var _p2_on_ready_button: bool = false

# Tous les slots de la grille
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
		"preview": preload("res://assets/sprites/Personnages/Fardoux/fardoux_jump11.png")
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
	
	# Configurer les boutons Prêt
	if ready_button_p1:
		ready_button_p1.pressed.connect(_on_ready_button_p1_pressed)
	if ready_button_p2:
		ready_button_p2.pressed.connect(_on_ready_button_p2_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		
	_update_ui()
	_update_visuals()

func _update_ui() -> void:
	# Mise à jour des labels de statut
	if p1_status_label:
		var status = "J1 : "
		if _p1_selected_slot:
			status += _p1_selected_slot.name_label.text
		else:
			status += "Aucun"
		if _p1_is_ready:
			status += " [PRET]"
		p1_status_label.text = status
		
	if p2_status_label:
		var status = "J2 : "
		if _p2_selected_slot:
			status += _p2_selected_slot.name_label.text
		else:
			status += "Aucun"
		if _p2_is_ready:
			status += " [PRET]"
		p2_status_label.text = status
	
	# Mise à jour de l'apparence des boutons Prêt
	_update_ready_buttons_visual()

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

		_all_slots.append(slot)

	var empty_count: int = max(total_slots - characters.size(), 0)
	for i: int in range(empty_count):
		var empty_slot: Node = CHARACTER_SLOT_SCENE.instantiate()
		character_grid.add_child(empty_slot)
		if empty_slot.has_method("setup"):
			empty_slot.setup()
		_all_slots.append(empty_slot)

func _update_visuals() -> void:
	"""Met à jour l'apparence visuelle de tous les slots et boutons."""
	_update_grid_visuals()
	_update_ready_buttons_visual()
func _update_grid_visuals() -> void:
	for i in range(_all_slots.size()):
		var slot = _all_slots[i]
		
		# Fond gris opaque si curseur dessus OU sélectionné
		var bg_active = (not _p1_on_ready_button and i == _p1_cursor_index) or \
						(not _p2_on_ready_button and i == _p2_cursor_index) or \
						slot == _p1_selected_slot or \
						slot == _p2_selected_slot
		if slot.has_method("set_background_active"):
			slot.set_background_active(bg_active)
		
		# Curseurs en priorité basse
		var slot_self_modulate = Color.WHITE
		if not _p1_on_ready_button and i == _p1_cursor_index:
			if not _p2_on_ready_button and i == _p2_cursor_index:
				slot_self_modulate = COLOR_BOTH_CURSOR
			else:
				slot_self_modulate = COLOR_P1_CURSOR
		elif not _p2_on_ready_button and i == _p2_cursor_index:
			slot_self_modulate = COLOR_P2_CURSOR
		
		# Sélection prioritaire sur les curseurs
		if slot == _p1_selected_slot and slot == _p2_selected_slot:
			slot_self_modulate = COLOR_BOTH_SELECTED
		elif slot == _p1_selected_slot:
			slot_self_modulate = COLOR_P1_SELECTED
		elif slot == _p2_selected_slot:
			slot_self_modulate = COLOR_P2_SELECTED
		
		slot.modulate = Color.WHITE
		slot.self_modulate = slot_self_modulate
func _update_ready_buttons_visual() -> void:
	"""Met à jour l'apparence des boutons Prêt."""
	if ready_button_p1:
		ready_button_p1.modulate = Color.WHITE
		ready_button_p1.self_modulate = Color.WHITE
		
		if _p1_is_ready:
			ready_button_p1.modulate = COLOR_READY_STATE
		
		if _p1_on_ready_button:
			ready_button_p1.self_modulate = COLOR_P1_CURSOR
			if _p1_is_ready:
				ready_button_p1.self_modulate = COLOR_READY_BUTTON_HOVER
	
	if ready_button_p2:
		ready_button_p2.modulate = Color.WHITE
		ready_button_p2.self_modulate = Color.WHITE
		
		if _p2_is_ready:
			ready_button_p2.modulate = COLOR_READY_STATE
		
		if _p2_on_ready_button:
			ready_button_p2.self_modulate = COLOR_P2_CURSOR
			if _p2_is_ready:
				ready_button_p2.self_modulate = COLOR_READY_BUTTON_HOVER

func _select_character_for_player(player: int, slot: Node) -> void:
	"""Sélectionne un personnage pour un joueur spécifique."""
	if slot == null or not _all_slots.has(slot):
		return
	
	# Si le joueur est déjà prêt, il ne peut pas changer de personnage
	if player == 1 and _p1_is_ready:
		return
	if player == 2 and _p2_is_ready:
		return
	
	# Jouer la voiceline de sélection
	if slot._character_scene:
		var temp_char = slot._character_scene.instantiate()
		if "voice_select" in temp_char and temp_char.voice_select:
			if voice_player:
				voice_player.stream = temp_char.voice_select
				voice_player.play()
		temp_char.queue_free()
	
	if player == 1:
		_p1_selected_slot = slot
	else:
		_p2_selected_slot = slot
	
	_update_visuals()
	_update_ui()

func _on_ready_button_p1_pressed() -> void:
	if _p1_on_ready_button:
		if _p1_selected_slot == null:
			_flash_error_label(p1_status_label, "J1 : Choisissez un personnage !")
			return
		_p1_is_ready = !_p1_is_ready
		if p1_status_label:
			p1_status_label.remove_theme_color_override("font_color")
		_update_visuals()
		_update_ui()
		_check_auto_transition()

func _on_ready_button_p2_pressed() -> void:
	if _p2_on_ready_button:
		if _p2_selected_slot == null:
			_flash_error_label(p2_status_label, "J2 : Choisissez un personnage !")
			return
		_p2_is_ready = !_p2_is_ready
		if p2_status_label:
			p2_status_label.remove_theme_color_override("font_color")
		_update_visuals()
		_update_ui()
		_check_auto_transition()
func _flash_error_label(label: Label, message: String) -> void:
	if label == null:
		return
	label.text = message
	label.add_theme_color_override("font_color", Color.RED)
	var tween = get_tree().create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 0.2)
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	tween.tween_property(label, "modulate:a", 0.0, 0.2)
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
func _check_auto_transition() -> void:
	"""Vérifie si les deux joueurs sont prêts et déclenche la transition."""
	if _p1_is_ready and _p2_is_ready and not _is_transitioning:
		_is_transitioning = true
		
		var p1_path = _p1_selected_slot._character_scene.resource_path if _p1_selected_slot and _p1_selected_slot._character_scene else ""
		var p2_path = _p2_selected_slot._character_scene.resource_path if _p2_selected_slot and _p2_selected_slot._character_scene else ""
		
		if p1_path:
			var p1_idx = GameData.CHARACTER_SCENES.find(p1_path)
			if p1_idx != -1:
				GameData.p1_character_index = p1_idx
		
		if p2_path:
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
	# Gestion des entrées du joueur 1
	_handle_player_input(1, event)
	# Gestion des entrées du joueur 2
	_handle_player_input(2, event)

func _handle_player_input(player: int, event: InputEvent) -> void:
	"""Gère les entrées d'un joueur spécifique."""
	var prefix = "p%d_" % player
	var moved := false
	var action_performed := false
	
	if not _is_transitioning:
		# Navigation dans la grille ou sur les boutons
		if event.is_action_pressed(prefix + "left"):
			_move_player_cursor(player, -1, 0)
			action_performed = true
		elif event.is_action_pressed(prefix + "right"):
			_move_player_cursor(player, 1, 0)
			action_performed = true
		elif event.is_action_pressed(prefix + "up"):
			_move_player_cursor(player, 0, -1)
			action_performed = true
		elif event.is_action_pressed(prefix + "down"):
			_move_player_cursor(player, 0, 1)
			action_performed = true
		
		# Sélection / Validation
		if event.is_action_pressed(prefix + "select"):
			_handle_player_select(player)
			action_performed = true
	
	# Gestion du bouton Retour (uniquement J1)
	if player == 1 and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
		return
	
	if action_performed:
		get_viewport().set_input_as_handled()

func _move_player_cursor(player: int, dx: int, dy: int) -> void:
	"""Déplace le curseur d'un joueur."""
	var cursor_index = _p1_cursor_index if player == 1 else _p2_cursor_index
	var on_ready_button = _p1_on_ready_button if player == 1 else _p2_on_ready_button
	
	# Si on est sur le bouton Prêt
	if on_ready_button:
		# Mouvement vers le haut : retourner à la grille
		if dy < 0:
			var on_ready = _p1_is_ready if player == 1 else _p2_is_ready
			if player == 1:
				_p1_on_ready_button = false
				_p1_cursor_index = min(_grid_columns * 2, _all_slots.size() - 1)
			else:
				_p2_on_ready_button = false
				_p2_cursor_index = min(_grid_columns * 2, _all_slots.size() - 1)
			_update_visuals()
			return
		# Les autres mouvements sont ignorés en étant sur le bouton
		return
	
	# On est dans la grille
	var new_index = cursor_index
	
	if dx != 0:
		# Mouvement gauche/droite
		new_index = cursor_index + dx
	elif dy != 0:
		# Mouvement haut/bas
		if dy < 0:
			# Vers le haut
			new_index = max(cursor_index - _grid_columns, 0)
		else:
			# Vers le bas
			# Vérifie si on sort de la grille (passage au bouton Prêt)
			if cursor_index + _grid_columns >= _all_slots.size():
				# Passer au bouton Prêt
				if player == 1:
					_p1_on_ready_button = true
				else:
					_p2_on_ready_button = true
				_update_visuals()
				return
			else:
				new_index = cursor_index + _grid_columns
	
	# Clamper l'index dans les limites de la grille
	new_index = clamp(new_index, 0, _all_slots.size() - 1)
	
	# Limiter les mouvements horizontaux pour rester dans les lignes
	var current_row = cursor_index / _grid_columns
	var new_row = new_index / _grid_columns
	
	if dx != 0 and current_row != new_row:
		new_index = cursor_index  # Revenir à la position actuelle
	
	if player == 1:
		_p1_cursor_index = new_index
	else:
		_p2_cursor_index = new_index
	
	_update_visuals()

func _handle_player_select(player: int) -> void:
	"""Gère l'appui sur le bouton de sélection d'un joueur."""
	if player == 1:
		if _p1_on_ready_button:
			_on_ready_button_p1_pressed()
		else:
			var slot = _all_slots[_p1_cursor_index]
			_select_character_for_player(1, slot)
	else:
		if _p2_on_ready_button:
			_on_ready_button_p2_pressed()
		else:
			var slot = _all_slots[_p2_cursor_index]
			_select_character_for_player(2, slot)
