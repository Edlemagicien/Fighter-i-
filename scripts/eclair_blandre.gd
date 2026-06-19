extends Area2D

var owner_player: Node = null
var owner_player_number: int = -1

func _ready() -> void:
	# L'éclair s'auto-détruit à la fin de l'animation d'attaque (0.4s)
	await get_tree().create_timer(0.4).timeout
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body == owner_player:
		return

	if body.is_in_group("players"):
		# On vérifie de quel côté Blandre regarde pour appliquer le recul du bon côté
		var directionRight = false
		if owner_player and owner_player.animated_sprite.flip_h:
			directionRight = true
			
		# Inflige les dégâts
		body.take_hit(50.0, 40.0, 30.0, directionRight, true)
