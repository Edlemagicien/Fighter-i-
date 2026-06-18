extends Area2D

func _ready():
	# Connecte automatiquement le signal au lancement du jeu
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# On vérifie si l'objet qui traverse la ligne est bien un joueur (BasePlayer)
	if body is BasePlayer:
		body.die() # On déclenche sa fonction de mort
