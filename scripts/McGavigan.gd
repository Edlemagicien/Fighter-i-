extends BasePlayer

@onready var animated_sprite = $AnimatedSprite2D

# Cette variable va nous permettre de charger le ballon depuis l'éditeur
@export var mcgavigan_projectile: PackedScene 

func _ready():
	super._ready()
	character_name  = "McGavigan"
	character_color = Color(0.2, 0.8, 0.2) # Sa couleur (tu peux changer)
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
		
		# On vérifie si la jauge spéciale est pleine (10)
		if special_gauge >= MAX_SPECIAL_GAUGE:
			is_attacking = true
			
			# On vide la jauge et met à jour l'écran
			special_gauge = 0
			update_hud() 
			
			# On joue la voix spéciale (le fameux "2 points !")
			play_voice(voice_special)
			
			# Temps de préparation du tir
			await get_tree().create_timer(0.4).timeout
			
			# Création et lancer du ballon
			if mcgavigan_projectile:
				var projectile = mcgavigan_projectile.instantiate()
				projectile.owner_player = self
				projectile.owner_player_number = player_number
				
				# --- LA CORRECTION EST ICI ---
				# On ajuste la position de départ (hauteur et côté) et la direction du ballon
				if animated_sprite.flip_h: # Si McGavigan regarde à GAUCHE
					projectile.direction = Vector2.LEFT
					# -40 vers la gauche, -50 vers le haut
					projectile.global_position = self.global_position + Vector2(-40, -200) 
				else: # Si McGavigan regarde à DROITE
					projectile.direction = Vector2.RIGHT
					# 40 vers la droite, -50 vers le haut
					projectile.global_position = self.global_position + Vector2(40, -200)
				
				# On ajoute enfin le ballon au jeu
				get_tree().current_scene.add_child(projectile)
				throw_projectile(projectile)
				
			# Temps de récupération après le tir
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
	elif is_attacking:
		animated_sprite.play("attack")
	elif abs(velocity.x) > 20:
		animated_sprite.play("run")
	elif taking_damage:
		animated_sprite.play("damage")
		await get_tree().create_timer(0.5).timeout
		taking_damage = false
	else:
		animated_sprite.play("idle")
