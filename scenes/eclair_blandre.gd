extends Area2D

var owner_player: Node = null
var owner_player_number: int = -1

func _ready() -> void:
	# L'éclair s'auto-détruit après 0.4 seconde
	await get_tree().create_timer(0.4).timeout
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	# On ne veut pas que Blandre se blesse lui-même
	if body == owner_player:
		return

	# Si l'éclair touche un joueur
	if body.is_in_group("players"):
		var directionRight = false
		if owner_player and owner_player.animated_sprite.flip_h:
			directionRight = true
			
		# Inflige les dégâts
		body.take_hit(50.0, 40.0, 30.0, directionRight, true)
