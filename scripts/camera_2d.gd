extends Camera2D

# ── PARAMÈTRES (modifiables dans l'Inspecteur) ──────────────────
@export var zoom_min: float = 0.5   # Zoom arrière maximum
@export var zoom_max: float = 1.0   # Zoom avant maximum
@export var zoom_speed: float = 2.0 # Vitesse du zoom
@export var follow_speed: float = 4.0 # Vitesse de suivi des joueurs

# Limites de la caméra (pour ne pas sortir de l'arène)
@export var limit_left_val: float = -200.0
@export var limit_right_val: float = 1000.0
@export var limit_top_val: float = -1500.0
@export var limit_bottom_val: float = 700.0

func _ready():
	# Appliquer les limites
	limit_left   = int(limit_left_val)
	limit_right  = int(limit_right_val)
	limit_top    = int(limit_top_val)
	limit_bottom = int(limit_bottom_val)
	
	# Activer le lissage
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed

func _process(delta):
	_apply_shake(delta)
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	
	# ── Calculer le centre entre tous les joueurs ────────────────
	var center = Vector2.ZERO
	for player in players:
		center += player.global_position
	center /= players.size()
	
	# ── Déplacer la caméra vers ce centre ────────────────────────
	global_position = lerp(global_position, center, follow_speed * delta)
	
	# ── Zoom automatique selon la distance entre joueurs ────────
	if players.size() >= 2:
		var distance = players[0].global_position.distance_to(
					   players[1].global_position)
		
		# Plus les joueurs sont éloignés, plus on dézoome
		var target_zoom = clamp(
			300.0 / distance,  # 300 = distance de référence
			zoom_min,
			zoom_max
		)
		# Appliquer le zoom progressivement
		var new_zoom = lerp(zoom.x, target_zoom, zoom_speed * delta)
		zoom = Vector2(new_zoom, new_zoom)
	
	# ── Légère secousse quand un joueur est touché (screen shake) ─
	# (appelée depuis player.gd avec camera.shake())

# ── SCREEN SHAKE ────────────────────────────────────────────────
var shake_intensity: float = 0.0
var shake_duration: float = 0.0

func shake(intensity: float = 8.0, duration: float = 0.2):
	shake_intensity = intensity
	shake_duration  = duration

func _apply_shake(delta):
	if shake_duration > 0:
		shake_duration -= delta
		offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		offset = Vector2.ZERO
		shake_intensity = 0.0
