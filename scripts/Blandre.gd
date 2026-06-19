extends BasePlayer

@onready var animated_sprite = $AnimatedSprite2D
@export var projectile_blandre: PackedScene

func _ready():
	super._ready()
	character_name  = "Blandre"
	character_color = Color(0.9, 0.5, 0.1)
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
		
		if special_gauge >= MAX_SPECIAL_GAUGE:
			is_attacking = true
			special_gauge = 0
			update_hud() 
			play_voice(voice_special)
			
			if projectile_blandre:
				var eclair = projectile_blandre.instantiate()
				eclair.owner_player = self
				eclair.owner_player_number = player_number
				
				# On attache l'éclair à Blandre pour qu'il le suive
				add_child(eclair) 
				
				# On décale l'éclair pour qu'il sorte des mains
				if animated_sprite.flip_h: # S'il regarde à gauche
					eclair.position = Vector2(-70, -20) 
					eclair.scale.x = -1
				else: # S'il regarde à droite
					eclair.position = Vector2(70, -20) 
					eclair.scale.x = 1
					
			await get_tree().create_timer(0.4).timeout
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
