extends Control

# --- REFERENCES AUX NOEUDS ---
@onready var p1_percent = $P1Panel/VBoxContainer/P1Percent
@onready var p2_percent = $P2Panel/VBoxContainer/P2Percent

@onready var p1_stocks = $P1Panel/VBoxContainer/P1Stocks
@onready var p2_stocks = $P2Panel/VBoxContainer/P2Stocks

@onready var time_label = $TimePanel/TimeLabel

# --- COULEURS DE DEGATS ---
const COLOR_SAFE   = Color(1.0, 1.0, 1.0) # Blanc (0-49%)
const COLOR_WARN   = Color(1.0, 0.9, 0.2) # Jaune (50-99%)
const COLOR_DANGER = Color(1.0, 0.5, 0.1) # Orange (100-149%)
const COLOR_CRIT   = Color(1.0, 0.15, 0.15) # Rouge (150%+)

func _ready():
	# On initialise l'affichage des vies au départ selon la configuration globale
	update_stocks(1, GameData.stock_count)
	update_stocks(2, GameData.stock_count)
	
	# Affichage de base au lancement
	update_percent(1, 0.0)
	update_percent(2, 0.0)

# --- MISE A JOUR DU POURCENTAGE ---
func update_percent(player_num: int, percent: float):
	var label = p1_percent if player_num == 1 else p2_percent
	
	# 1. Mettre à jour le texte
	label.text = str(int(percent)) + "%"
	
	# 2. Changer la couleur selon le danger
	if percent < 50:
		label.add_theme_color_override("font_color", COLOR_SAFE)
	elif percent < 100:
		label.add_theme_color_override("font_color", COLOR_WARN)
	elif percent < 150:
		label.add_theme_color_override("font_color", COLOR_DANGER)
	else:
		label.add_theme_color_override("font_color", COLOR_CRIT)
		
	# 3. Petit effet de "Pop" quand on prend un coup
	var tween = get_tree().create_tween()
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)
	
# --- MISE A JOUR DU TEMPS ---
func update_time(time_left: int):
	if not time_label:
		return
		
	if time_left <= 0:
		time_label.text = "Infini"
		time_label.remove_theme_color_override("font_color")
		return
		
	@warning_ignore("integer_division")
	var minutes = time_left / 60
	var seconds = time_left % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]
	
	if time_left <= 10:
		time_label.add_theme_color_override("font_color", COLOR_CRIT)
	else:
		time_label.remove_theme_color_override("font_color")
	
# --- MISE A JOUR DES VIES ---
func update_stocks(player_num: int, stocks_remaining: int):
	var stock_container = p1_stocks if player_num == 1 else p2_stocks
	
	# On vide les anciennes icônes
	for child in stock_container.get_children():
		child.queue_free()
		
	# On ajoute autant d'icônes qu'il reste de vies
	for i in range(stocks_remaining):
		var icon = TextureRect.new()
		# Remplace par le chemin de ton icône de vie (ex: tête du prof)
		icon.texture = load("res://assets/art/ui/icons/pixel-heart.png")
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stock_container.add_child(icon)
		
		# --- MISE A JOUR DE LA JAUGE SPECIALE ---
func update_special(player_num: int, current_gauge: int, max_gauge: int):
	# On cherche dynamiquement la ProgressBar dans ta scène
	var bar_path = "P1Panel/VBoxContainer/P1Special" if player_num == 1 else "P2Panel/VBoxContainer/P2Special"
	var bar = get_node_or_null(bar_path)
	
	if bar:
		bar.max_value = max_gauge
		bar.value = current_gauge
		
		# Petit effet visuel : la barre devient verte/jaune quand l'attaque est prête !
		if current_gauge >= max_gauge:
			bar.modulate = Color(1.0, 0.8, 0.0) # Doré
		else:
			bar.modulate = Color(1.0, 1.0, 1.0) # Normal
