extends Area2D

@export var speed = 800.0
@export var rotation_speed = 10.0
var direction = Vector2.RIGHT
var owner_player: Node = null
var owner_player_number: int = -1

func _ready() -> void:
	add_to_group("projectile")

func _process(delta: float) -> void:
	# Movement logic consistent with other projectiles
	# Note: Project uses position += (-1) * direction * speed * delta
	position += (-1) * direction * speed * delta
	
	# Rotate the backpack while it flies
	if has_node("Sprite2D"):
		$Sprite2D.rotate(rotation_speed * delta)

func _on_body_entered(body: Node2D) -> void:
	if body == owner_player:
		return

	if body.is_in_group("players"):
		var directionRight = direction.x < 0
		body.take_hit(50.0, 40.0, 30.0, directionRight, true)
		queue_free()
	elif body.is_in_group("platform"):
		queue_free()
