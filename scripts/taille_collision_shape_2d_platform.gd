extends CollisionShape2D

@export var tailleCollision: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scale = Vector2(tailleCollision, scale.y)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
