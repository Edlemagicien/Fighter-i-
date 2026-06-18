extends Node2D

@export var speed = 600
var direction = Vector2.RIGHT
var owner_player: Node = null
var owner_player_number: int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("projectile")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += (-1) * direction * speed * delta

func _on_area_2d_body_entered(body: Node2D) -> void:

	if body == owner_player:
		return

	if body.is_in_group("players"):
		var directionRight = direction.x < 0
		body.take_hit(50.0, 40.0, 30.0, directionRight, true)
		queue_free()
	elif body.is_in_group("platform"):
		queue_free()
