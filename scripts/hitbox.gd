extends Area2D

# Type d'attaque : "ground", "air" ou "smash"
@export var attack_type: String = "ground"

func _ready():
	# Désactiver la hitbox par défaut
	monitoring = false
	# Écouter les collisions
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Vérifier que c'est un joueur et que ce n'est pas le propriétaire
	if body.is_in_group("players") and body != get_parent():
		# Récupérer le parent (le joueur qui attaque)
		var parent = get_parent()
		# Récupérer les données de l'attaque
		var data = parent.ATTACK_DATA[attack_type]
		# Savoir dans quelle direction regarde l'attaquant
		var facing_right = not parent.facing_left
		# Infliger les dégâts
		body.take_hit(data[0], data[1], data[2], facing_right, true)
		# On remplit la jauge de l'attaquant !
		if parent.has_method("add_special_gauge"):
			parent.add_special_gauge(1)
