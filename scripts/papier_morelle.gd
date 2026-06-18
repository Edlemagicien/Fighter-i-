extends Node2D

@export var speed = 600
var direction = Vector2.RIGHT
var owner_player: Node = null

func _ready() -> void:
	add_to_group("projectile")

func _process(delta: float) -> void:
	position += (-1) * direction * speed * delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == owner_player:
		return

	if body.is_in_group("players"):
		var directionRight = direction.x < 0
		body.take_hit(50, 40, 30, directionRight, true)
		queue_free()
	elif body.is_in_group("platform"):
		queue_free()
