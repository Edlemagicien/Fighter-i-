extends Area2D

@export var speed = 1000.0
var direction = Vector2.RIGHT
var owner_player: Node = null
var owner_player_number: int = -1

func _ready() -> void:
	add_to_group("projectile")
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("default")

func _process(delta: float) -> void:
	# Note: In other projectile scripts, they use position += (-1) * direction * speed * delta
	# This seems to be because direction might be flipped or something.
	# Let's stay consistent with the project's existing projectile logic.
	position += (-1) * direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body == owner_player:
		return

	if body.is_in_group("players"):
		var directionRight = direction.x < 0
		body.take_hit(50.0, 40.0, 30.0, directionRight, true)
		queue_free()
	elif body.is_in_group("platform"):
		queue_free()
