extends CharacterBody2D
class_name BasePlayer

# STATS 
@export var character_name  : String = "Inconnu"
@export var character_color : Color  = Color.WHITE
@export var move_speed      : float  = 300.0
@export var jump_force      : float  = 700.0
@export var weight          : float  = 1.0
@export var max_jumps       : int    = 2
@export var max_stocks      : int    = 3
@export var player_number   : int    = 1
@export var dash_speed      : float  = 800.0
@export var dash_duration   : float  = 0.2

# VARIABLES INTERNES 
var ATTACK_DATA = {
	"melee": [10.0, 20.0, 20.0]
}
var gravity          = ProjectSettings.get_setting("physics/2d/default_gravity")
var jumps_remaining  : int   = 2
var damage_percent   : float = 0.0
var stocks           : int   = 0
var is_attacking     : bool  = false
var invincible_timer : float = 0.0
var stun_timer       : float = 0.0 
var facing_left      : bool  = true
var taking_damage    : bool  = false
var spawn_point      : Vector2
var hud_control      : Node  = null
var _is_dying        : bool  = false
var special_gauge    : int   = 0
const MAX_SPECIAL_GAUGE : int = 5
const SHIELD_DURATION := 2.0
const SHIELD_COOLDOWN := 20.0
var shield_active := false
var shield_timer := 0.0
var shield_cooldown := 0.0

# Dash
var is_dashing       : bool  = false
var can_air_dash     : bool  = true
var dash_timer       : float = 0.0
var dash_dir         : Vector2 = Vector2.ZERO

# VARIABLES LEDGE GRAB
var is_grabbing_ledge : bool  = false
var ledge_timer       : float = 0.0
var regrab_timer      : float = 0.0
const LEDGE_HOLD_TIME : float = 1.2
const REGRAB_COOLDOWN : float = 0.5

# CONSTANTES
const FAST_FALL_MULT      : float = 2.5
const PROJECTILE_SPEED    : float = 2000.0
const DEPLACEMENT_ATTAQUE : float = 75
const VOICE_LINE_CHANCE   : float = 0.25

# SIGNAUX
signal stock_lost(player_num, stocks_remaining)
signal player_eliminated(player_num)

# REFERENCES
@onready var sprite = $AnimatedSprite2D
@onready var ledge_detector = $LedgeDetector
var voice_player : AudioStreamPlayer2D

# VOICELINES
@export_group("Voicelines")
@export var voice_select  : AudioStream
@export var voice_jump    : AudioStream
@export var voice_hurt    : AudioStream
@export var voice_special : AudioStream
@export var voice_die     : AudioStream

# READY 
func _ready():
	add_to_group("players")
	
	# Gestion du VoicePlayer
	voice_player = AudioStreamPlayer2D.new()
	voice_player.name = "VoicePlayer"
	voice_player.bus = "SFX"
	add_child(voice_player)

	velocity = Vector2.ZERO
	sprite.sprite_frames = sprite.sprite_frames.duplicate()

	max_stocks = GameData.stock_count
	stocks = max_stocks

	if player_number == 1:
		sprite.flip_h = true
		facing_left = false
	else:
		sprite.flip_h = false
		facing_left = true

	if ledge_detector:
		ledge_detector.body_entered.connect(_on_ledge_detected)

	update_hud()

# BOUCLE PHYSIQUE 
func _physics_process(delta):
	# Gestion de l'invincibilité
	if invincible_timer > 0:
		invincible_timer -= delta
	# Bouclier
	if shield_active:
		shield_timer -= delta

		if shield_timer <= 0:
			shield_active = false
			sprite.modulate = Color.WHITE

	if shield_cooldown > 0:
		shield_cooldown -= delta
		update_hud()
	# Gestion du cooldown de ré-accrochage
	if regrab_timer > 0:
		regrab_timer -= delta
		
	# GESTION DE L'ÉTOURDISSEMENT (Hitstun)
	if stun_timer > 0:
		stun_timer -= delta
		# Pendant l'étourdissement, on applique la gravité et une légère friction
		if not is_on_floor():
			velocity.y += gravity * delta
			velocity.x = move_toward(velocity.x, 0, 5.0) # Glisse un peu dans l'air
		else:
			velocity.x = move_toward(velocity.x, 0, 20.0) # Freine au sol
			
		move_and_slide()
		return # On bloque toutes les autres actions (mouvement, saut, attaque)
	
	# 1. LOGIQUE DE LEDGE
	if is_grabbing_ledge:
		handle_ledge_hang(delta)
		move_and_slide()
		return

	# 2. LOGIQUE DE DASH (Prioritaire sur tout)
	if is_dashing:
		dash_timer -= delta
		velocity = dash_dir * dash_speed
		if dash_timer <= 0:
			is_dashing = false
			velocity = velocity * 0.5 # On garde un peu d'élan en sortie
		move_and_slide()
		return

	# 3. PHYSIQUE NORMALE (En dehors du dash)
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jumps_remaining = max_jumps
		can_air_dash = true # Reset au sol

	handle_jump()
	handle_shield()
	handle_movement()
	handle_dash_input() # La nouvelle fonction
	handle_fast_fall()

	if not is_attacking:
		handle_attacks()
		handle_melee_attack()
		handle_special_attack()

	move_and_slide()

# CLIGNOTEMENT 
func _process(_delta):
	if invincible_timer > 0:
		var blink = sin(Time.get_ticks_msec() * 0.025) > 0
		sprite.visible = blink
	else:
		sprite.visible = true

# SAUT 
func handle_jump():
	var action = "p" + str(player_number) + "_jump"
	if Input.is_action_just_pressed(action) and jumps_remaining > 0:
		velocity.y = -jump_force
		jumps_remaining -= 1
		play_voice(voice_jump)
# BOUCLIER

func handle_shield():

	var action = "p" + str(player_number) + "_shield"

	if Input.is_action_just_pressed(action):

		if shield_active:
			return

		if shield_cooldown > 0:
			return

		shield_active = true
		shield_timer = SHIELD_DURATION
		shield_cooldown = SHIELD_COOLDOWN

		sprite.modulate = Color(0.4,0.8,1.0)
		
# MOUVEMENT 
func handle_movement():
	if is_dashing:
		return
		
	var dir = Input.get_axis(
		"p" + str(player_number) + "_left",
		"p" + str(player_number) + "_right"
	)
	
	# Le joueur a le contrôle (le stun_timer est terminé)
	if dir != 0:
		# S'il est en l'air et qu'il va DÉJÀ très vite à cause de l'éjection
		if not is_on_floor() and abs(velocity.x) > move_speed:
			# On lui permet d'influencer doucement sa direction (Air Control / DI)
			velocity.x = move_toward(velocity.x, dir * move_speed, 25.0)
		else:
			# Déplacement standard et réactif
			velocity.x = dir * move_speed
			
		facing_left = dir < 0
		sprite.flip_h = not facing_left
		
		if has_node("MeleeArea"):
			var melee_node = get_node("MeleeArea")
			melee_node.position.x = abs(melee_node.position.x) * (-1 if facing_left else 1)
			
		if has_node("LedgeDetector"):
			var ledge_node = get_node("LedgeDetector")
			ledge_node.position.x = abs(ledge_node.position.x) * (-1 if facing_left else 1)
	else:
		# S'il lâche la manette
		if not is_on_floor():
			# S'il est en vol, on le laisse glisser avec une petite friction
			velocity.x = move_toward(velocity.x, 0, 15.0)
		else:
			# S'il est au sol, il s'arrête de manière réactive
			velocity.x = move_toward(velocity.x, 0, move_speed)

# DASH_input 
func handle_dash_input():
	var dash_action = "p" + str(player_number) + "_smash"
	
	if Input.is_action_just_pressed(dash_action):
		if is_on_floor() or can_air_dash:
			# On récupère la direction (Haut, Bas, Gauche, Droite ou Diagonales)
			var input_dir = Vector2(
				Input.get_axis("p" + str(player_number) + "_left", "p" + str(player_number) + "_right"),
				Input.get_axis("p" + str(player_number) + "_jump", "p" + str(player_number) + "_down")
			)
			
			# Si aucune direction pressée, on dash vers l'avant par défaut
			if input_dir == Vector2.ZERO:
				input_dir.x = 1.0 if !facing_left else -1.0
			
			# Lancement du dash
			start_dash(input_dir.normalized())

func start_dash(dir):
	is_dashing = true
	dash_timer = dash_duration
	dash_dir = dir
	if not is_on_floor():
		can_air_dash = false # On consomme le dash aérien
		
# CHUTE RAPIDE 
func handle_fast_fall():
	var down_action = "p" + str(player_number) + "_down"
	if Input.is_action_just_pressed(down_action) and not is_on_floor():
		if velocity.y > 0:
			velocity.y *= FAST_FALL_MULT

# ATTAQUES : 
func handle_attacks():
	pass

func handle_special_attack():
	var special_action = "p" + str(player_number) + "_smash"
	if Input.is_action_just_pressed(special_action):
		play_voice(voice_special)
		# Cette fonction sera étendue dans les scripts des personnages

func handle_melee_attack():
	var melee_action = "p" + str(player_number) + "_melee"
	if Input.is_action_just_pressed(melee_action):
		do_melee_attack()

func do_melee_attack():
	if sprite.sprite_frames.has_animation("melee"):
		sprite.play("melee")
	
	if has_node("MeleeArea"):
		do_attack("MeleeArea", 0.1, 0.2, 0.2)
	else:
		# Fallback if no specific melee area defined yet
		is_attacking = true
		await get_tree().create_timer(0.5).timeout
		is_attacking = false

# RECEVOIR UN COUP 
func take_hit(dmg: float, _kb_x: float, _kb_y: float,
			  attacker_right: bool, recoil_effect: bool):
	if shield_active:
		return
	if invincible_timer > 0:
		return
	is_dashing = false
	damage_percent += dmg
	taking_damage = true
	stun_timer = 1.0 # <-- DÉCLENCHEMENT DU COOLDOWN DE 2 SECONDES
	play_voice(voice_hurt)
	
	# Nouvelle formule plus agressive
	var mult = (1.0 + (damage_percent / 40.0)) / weight
	
	if recoil_effect:
		# On utilise les arguments de base _kb_x et _kb_y de ton attaque
		var vx = _kb_x * mult * 10.0 # Multiplié par 10 pour l'échelle de vélocité de Godot
		var vy = -_kb_y * mult * 10.0 # Négatif car l'axe Y monte vers le haut
		
		# On inverse la vélocité X si l'attaquant regarde vers la gauche
		if not attacker_right:
			vx = -vx
			
		# On applique l'éjection !
		velocity = Vector2(vx, vy)
	
	invincible_timer = 0.5
	var cam = get_tree().current_scene.get_node_or_null("Camera2D")
	if cam and cam.has_method("shake"):
		cam.shake()
	update_hud()

# MORT
func die():
	if _is_dying:
		return
	_is_dying = true
	play_voice_forced(voice_die)

	stocks -= 1
	emit_signal("stock_lost", player_number, stocks)

	var hud = get_hud()
	if hud:
		hud.update_stocks(player_number, stocks)

	if stocks <= 0:
		emit_signal("player_eliminated", player_number)
		await get_tree().create_timer(1.0).timeout
		queue_free()
	else:
		await get_tree().create_timer(0.8).timeout
		_is_dying = false
		respawn()

# RESPAWN 
func respawn():
	damage_percent = 0.0
	special_gauge = 0
	velocity = Vector2.ZERO
	invincible_timer = 2.0
	stun_timer = 0.0 # On s'assure d'enlever le stun s'il meurt pendant qu'il vole
	global_position = spawn_point
	sprite.modulate = Color(1, 1, 1, 0)
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.5)
	update_hud()

func get_hud():
	if hud_control != null:
		return hud_control
	return get_tree().current_scene.get_node_or_null("HUD/HUDControl")

func set_hud(hud: Node) -> void:
	hud_control = hud
	
	# Augmenter la jauge spéciale
func add_special_gauge(amount: int = 1):
	if special_gauge < MAX_SPECIAL_GAUGE:
		special_gauge += amount
		if special_gauge > MAX_SPECIAL_GAUGE:
			special_gauge = MAX_SPECIAL_GAUGE
		update_hud()

# HUD 
func update_hud():
	var hud = get_hud()
	
	if hud:
		hud.update_percent(player_number, damage_percent)
		hud.update_stocks(player_number, stocks)
		
		if hud.has_method("update_special"):
			hud.update_special(player_number, special_gauge, MAX_SPECIAL_GAUGE)

# UTILITAIRE ATTAQUE
func do_attack(hitbox_name: String, startup: float,
			   active: float, recovery: float):
	is_attacking = true
	await get_tree().create_timer(startup).timeout
	get_node(hitbox_name).monitoring = true
	await get_tree().create_timer(active).timeout
	get_node(hitbox_name).monitoring = false
	await get_tree().create_timer(recovery).timeout
	is_attacking = false

func throw_projectile(projectile):
	is_attacking = true
	projectile.global_position = global_position

	var shot_direction: Vector2
	shot_direction = Vector2.LEFT if !facing_left else Vector2.RIGHT
	shot_direction = shot_direction.normalized()

	if "direction" in projectile:
		projectile.direction = shot_direction

	if "speed" in projectile:
		projectile.speed = PROJECTILE_SPEED

	if "owner_player" in projectile:
		projectile.owner_player = self

	if "owner_player_number" in projectile:
		projectile.owner_player_number = player_number

	is_attacking = false
	
# LEDGE GRAB 
func _on_ledge_detected(body):
	# Ne pas s'accrocher si on maintient "Bas" ou si le cooldown est actif
	var down_action = "p" + str(player_number) + "_down"
	if Input.is_action_pressed(down_action) or regrab_timer > 0:
		return
		
	# Déclencher seulement si dans les airs et en train de tomber
	if not is_on_floor() and velocity.y >= 0 and not is_grabbing_ledge:
		# Magnétisme : on s'aligne sur le haut de la plateforme détectée
		# On suppose que le détecteur est à Y=-50, on veut que ce point soit sur le bord
		if body is StaticBody2D or body is AnimatableBody2D:
			start_ledge_grab()

func start_ledge_grab():
	is_grabbing_ledge = true
	jumps_remaining = max_jumps # On récupère ses sauts !
	can_air_dash = true        # On récupère son dash !
	ledge_timer = LEDGE_HOLD_TIME
	invincible_timer = 0.5     # Courte invincibilité
	velocity = Vector2.ZERO
	
	# Animation de suspension
	if sprite.sprite_frames.has_animation("ledge_gap"):
		sprite.play("ledge_gap")
	elif sprite.sprite_frames.has_animation("climb"):
		sprite.play("climb")

func handle_ledge_hang(delta):
	velocity = Vector2.ZERO

	ledge_timer -= delta
	if ledge_timer <= 0:
		release_ledge()
		return

	var jump_action = "p" + str(player_number) + "_jump"
	var down_action = "p" + str(player_number) + "_down"

	if Input.is_action_just_pressed(jump_action):
		climb_up()
	elif Input.is_action_just_pressed(down_action):
		release_ledge()

func climb_up():
	is_grabbing_ledge = false
	regrab_timer = REGRAB_COOLDOWN
	velocity.y = -jump_force * 0.8 # Saut de remontée légèrement plus faible
	velocity.x = 200.0 * (-1 if facing_left else 1)

func release_ledge():
	is_grabbing_ledge = false
	regrab_timer = REGRAB_COOLDOWN
	velocity.y = 100.0

func play_voice(stream: AudioStream) -> void:
	play_voice_with_chance(stream, VOICE_LINE_CHANCE)

func play_voice_with_chance(stream: AudioStream, chance: float) -> void:
	if stream == null or voice_player == null:
		return

	if randf() > chance:
		return

	if voice_player.playing:
		return

	voice_player.stream = stream
	voice_player.play()

func play_voice_forced(stream: AudioStream) -> void:
	if stream == null or voice_player == null:
		return

	if voice_player.playing:
		voice_player.stop()

	voice_player.stream = stream
	voice_player.play()
