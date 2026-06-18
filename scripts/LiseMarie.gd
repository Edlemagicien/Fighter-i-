extends BasePlayer

@onready var animated_sprite = $AnimatedSprite2D
@export var cap_projectile: PackedScene

func _ready():
	super._ready()
	character_name  = "Lise-Marie"
	character_color = Color(0.8, 0.4, 0.6)  
	move_speed = 310.0
	jump_force = 680.0
	weight     = 0.85
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
			
			# TOUT CE BLOC DOIT ÊTRE INDENTÉ ICI :
			await get_tree().create_timer(0.4).timeout
			if cap_projectile:
				var projectile = cap_projectile.instantiate()
				get_tree().current_scene.add_child(projectile)
				throw_projectile(projectile)
			
			# Reset attacking state after a delay or animation
			await get_tree().create_timer(0.1).timeout
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
	elif taking_damage:
		if animated_sprite.animation != &"damage":
			animated_sprite.play("damage")
		if invincible_timer <= 0.0:
			taking_damage = false
	elif abs(velocity.x) > 20:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

func _on_animated_sprite_2d_animation_finished():
	if animated_sprite.animation == &"attack":
		is_attacking = false
	if animated_sprite.animation == &"damage":
		taking_damage = false
