extends Area2D

@export var speed = 800.0
@export var rotation_speed = 15.0 # Vitesse de rotation du ballon
var direction = Vector2.RIGHT
var owner_player: Node = null
var owner_player_number: int = -1

func _ready() -> void:
	add_to_group("projectile")

func _process(delta: float) -> void:
	# Le ballon avance (utilise la même logique que ton jeu)
	position += (-1) * direction * speed * delta
	
	# Le ballon tourne sur lui-même dans les airs
	if has_node("Sprite2D"):
		$Sprite2D.rotate(rotation_speed * delta)

func _on_body_entered(body: Node2D) -> void:
	# Ignore le lanceur
	if body == owner_player:
		return
	
	# --- LA LIGNE MAGIQUE ---
	print("Le ballon s'est détruit sur : ", body.name)
	
	# Si ça touche un adversaire
	if body.is_in_group("players"):
		var directionRight = direction.x < 0
		# Inflige les dégâts (50), le recul, etc.
		body.take_hit(50.0, 40.0, 30.0, directionRight, true)
		queue_free() # Le ballon disparaît
		
	# Si ça touche le décor/les plateformes
	elif body.is_in_group("platform"):
		queue_free()
