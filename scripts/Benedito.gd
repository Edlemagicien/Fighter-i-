extends BasePlayer

@onready var animated_sprite = $AnimatedSprite2D
@export var tir: PackedScene

func _ready():
	super._ready()
	character_name  = "Benedito"
	character_color = Color(1.0, 1.0, 1.0)  
	move_speed = 320.0
	jump_force = 700.0
	weight     = 0.9
	max_jumps  = 2

func _physics_process(delta):
	super._physics_process(delta)
	update_animation()

func handle_attacks():
	var attack_action = "p" + str(player_number) + "_attack"
	if Input.is_action_just_pressed(attack_action):
		
		# On vérifie si la jauge est pleine (10)
		if special_gauge >= MAX_SPECIAL_GAUGE:
			is_attacking = true
			
			# On vide la jauge immédiatement pour qu'il reparte à 0
			special_gauge = 0
			update_hud() 
			
			# --- TOUT CE BLOC EST MAINTENANT BIEN INDENTÉ ---
			await get_tree().create_timer(0.4).timeout
			var projectile = tir.instantiate()
			get_tree().current_scene.add_child(projectile)
			throw_projectile(projectile)
			
			await get_tree().create_timer(0.2).timeout
			is_attacking = false

func update_animation():
	if is_attacking:
		if animated_sprite.animation == &"melee":
			return
		if animated_sprite.animation != &"attack":
			animated_sprite.play("attack")
		return
	
	if is_grabbing_ledge:
		animated_sprite.play("climb")
		return

	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")
	elif is_dashing:
		animated_sprite.play("dash")
	elif abs(velocity.x) > 20:
		animated_sprite.play("run")
	elif taking_damage:
		animated_sprite.play("damage")
		await get_tree().create_timer(0.5).timeout
		taking_damage = false
	else:
		animated_sprite.play("idle")
