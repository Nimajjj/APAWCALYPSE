class_name IEnemy
extends CharacterBody2D

var blood_effect_scene: PackedScene = preload("res://scenes/effects/gpu_blood_effect.tscn")
var bonus_scene: PackedScene = preload("res://scenes/bonus/i_bonus.tscn")

var dead: bool = false
var slowed: bool = false
var chase_target: Node2D = null  # cible poursuivie en etat 2 (le joueur)
var direction: String
var state: int = 0
var destination: Vector2
var knockback_force: float = 0
var knockback_direction: Vector2 = Vector2.ZERO
var speed_stock: int
var _sprite_base_scale: Vector2 = Vector2.ONE
var _sprite_base_pos: Vector2 = Vector2.ZERO
var _hit_tween: Tween = null
var _flinch_tween: Tween = null

# Valeurs de base (avant multiplicateurs Balance), capturees une fois pour le
# reglage a chaud.
var _base_speed: int
var _base_max_health: int
var _base_damage: int
var _base_money: int
var _balance_captured: bool = false


@onready var Sprite = $Sprite2D
@onready var HealthBar = $HealthBar
@onready var timer = $Timer
@onready var slow_timer = $SlowTimer
@onready var path_timer = $PathTimer
@onready var agent := $NavigationAgent2D as NavigationAgent2D
@onready var bite_sound: AudioStreamPlayer2D = $BiteSound
@onready var death_sound: AudioStreamPlayer2D = $DeathSound


@export var max_health: int
@export var speed: int
@export var money: int
@export var damage: int
@export var is_boss: bool = false
@export var is_miser: bool = false
@export var is_reaper: bool = false


#var bonus: IBonus = null
var health: int


func _ready():
	HealthBar.visible = false
	HealthBar.max_value = max_health
	HealthBar.value = max_health
	
	Sprite.material = Sprite.material.duplicate()
	_sprite_base_scale = Sprite.scale
	_sprite_base_pos = Sprite.position

	timer.connect("timeout", func():
		Sprite.material.set_shader_parameter("flash_modifier", 0.0)
	)
	slow_timer.connect("timeout", func(): slow_timeout())
	path_timer.connect("timeout", func(): retarget_timeout())
	death_sound.connect("finished", func(): death_sound_finished())
	Balance.changed.connect(_on_balance_changed)

	_setup_navigation()
	_setup_collision()


## Les ennemis ne se collisionnent PAS entre eux : on les place sur un layer dedie
## (4) en gardant leur masque par defaut (layer 1) pour continuer a buter sur les
## murs, portes et le joueur. Les Area2D qui doivent detecter les ennemis (zone de
## degats du joueur, fenetres) masquent aussi le layer 4.
func _setup_collision() -> void:
	set_collision_layer_value(1, false)
	set_collision_layer_value(4, true)


## Configure le NavigationAgent2D : distances de suivi de chemin adaptees a la
## taille des corps (scale 2x -> ~16px de rayon) pour ne pas rester coince dans
## les angles.
func _setup_navigation() -> void:
	# Pas d'evitement RVO : il verrouille les goulets (fenetres) et pousse les
	# ennemis DANS les murs (le RVO ignore la geometrie statique). On compte sur
	# move_and_slide pour la separation.
	#
	# path_desired_distance > rayon du corps (~16px en scale 2x) : c'est LA cle
	# anti-blocage dans les angles. Avec la valeur par defaut (10), un zombie ne
	# peut jamais s'approcher assez d'un point de chemin colle a l'arete d'un mur
	# pour le "valider" -> il n'avance jamais au point suivant et reste coince.
	agent.path_desired_distance = 24.0
	agent.target_desired_distance = 16.0


## Capture (une fois) les valeurs de base puis applique les multiplicateurs
## d'equilibrage. Appele par la fabrique apres le scaling de vague.
func apply_balance() -> void:
	if not _balance_captured:
		_base_speed = speed
		_base_max_health = max_health
		_base_damage = damage
		_base_money = money
		_balance_captured = true
	speed = int(_base_speed * Balance.get_v("enemy_speed"))
	max_health = int(_base_max_health * Balance.get_v("enemy_health"))
	damage = int(_base_damage * Balance.get_v("enemy_damage"))
	money = int(_base_money * Balance.get_v("enemy_money"))


func _on_balance_changed() -> void:
	if dead or not _balance_captured:
		return
	var ratio: float = float(health) / max(1.0, float(max_health))
	apply_balance()
	speed_stock = speed
	if not slowed:
		velocity = Vector2.ZERO
	health = int(max_health * ratio)
	HealthBar.max_value = max_health
	HealthBar.value = health

func _physics_process(delta):
	if dead:
		return
	if state == 0:
		# Approche du batiment : trajet direct vers la fenetre. Pas d'evitement RVO
		# ici : les ennemis spawnent en grappe derriere la fenetre et le RVO se
		# verrouillerait (immobilite). Les collisions de move_and_slide suffisent.
		var _direction = (destination - global_position).normalized()
		_face(_direction)
		velocity = _direction * speed * delta
		move_and_slide()
	elif state == 1:
		# Passage de la fenetre : translation forcee (sans collision) pour
		# franchir l'ouverture meme si d'autres ennemis s'y pressent.
		var _velocity: Vector2
		if direction == "down":
			_velocity = (Vector2.DOWN * speed * delta) / 125
		elif direction == "up":
			_velocity = (Vector2.UP * speed * delta) / 125
		elif direction == "left":
			_velocity = (Vector2.LEFT * speed * delta) / 125
		else:
			_velocity = (Vector2.RIGHT * speed * delta) / 125
		position += _velocity
	elif state == 2:
		# Poursuite du joueur via NavigationAgent2D (contournement des murs).
		var _direction = (agent.get_next_path_position() - global_position).normalized()
		_face(_direction)
		velocity = _direction * speed * delta
		move_and_slide()

func take_damage(dmg: int, shooter: IPlayer, hit_dir: Vector2 = Vector2.ZERO) -> void:
	HealthBar.visible = true
	Sprite.material.set_shader_parameter("flash_modifier", 1.0)
	timer.start()
	Juice.spawn_floating_text(global_position, str(dmg), Color(1, 0.9, 0.4))
	_hit_punch()
	if hit_dir != Vector2.ZERO:
		_hit_flinch(hit_dir)

	if(shooter.dead_shot) and !is_boss:
		dies(shooter)
		return

	slow()

	health -= dmg
	if health <= 0:
		dies(shooter)

	HealthBar.value = health

## Punch d'echelle bref quand l'ennemi est touche (impact "juicy").
func _hit_punch() -> void:
	if not is_instance_valid(Sprite):
		return
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	Sprite.scale = _sprite_base_scale * 1.28
	_hit_tween = create_tween()
	_hit_tween.tween_property(Sprite, "scale", _sprite_base_scale, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Recul visuel : la sprite est repoussee dans le sens de la balle puis revient a
## sa place. Purement cosmetique (n'affecte ni la collision ni le pathfinding), ce
## qui rend l'impact "physique" sans risque de pousser l'ennemi dans un mur.
func _hit_flinch(dir: Vector2) -> void:
	if not is_instance_valid(Sprite):
		return
	if _flinch_tween != null and _flinch_tween.is_valid():
		_flinch_tween.kill()
	Sprite.position = _sprite_base_pos + dir.normalized() * 5.0
	_flinch_tween = create_tween()
	_flinch_tween.tween_property(Sprite, "position", _sprite_base_pos, 0.14) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Oriente la sprite selon la direction de deplacement.
func _face(_direction: Vector2) -> void:
	if _direction.x < 0:
		Sprite.flip_h = false
	elif _direction.x > 0:
		Sprite.flip_h = true

func retarget() -> void:
	# En etat 2, on poursuit le joueur (chase_target) via le NavigationAgent2D.
	if chase_target != null:
		agent.target_position = chase_target.global_position

func retarget_timeout() -> void:
	retarget()

func slow() -> void:
	slow_timer.start()
	if not slowed:
		speed -= 20
		if speed <= 0:
			speed = 5
		slowed = true

func slow_timeout() -> void:
	speed = speed_stock
	slowed = false

func death_sound_finished() -> void:
	queue_free()

func dies(shooter: IPlayer) -> void:
	if not dead:
		dead = true
		
		$AnimationPlayer.stop()
		# Pop de mort : la sprite gonfle et se dissout (juice). Hit-stop sur boss.
		var pop := create_tween()
		pop.tween_property(Sprite, "scale", _sprite_base_scale * 1.4, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.parallel().tween_property(Sprite, "modulate:a", 0.0, 0.25)
		if is_boss:
			Juice.hit_stop(0.10, 0.05)
		# dies() est souvent appelee depuis un callback de collision (bullet/joueur),
		# donc pendant le flush des requetes physiques : on differe la desactivation
		# des colliders. Le flag dead=true ci-dessus empeche tout double-traitement
		# pendant la frame de report.
		$Hitbox.set_deferred("disabled", true)
		$HurtBox.get_child(0).set_deferred("disabled", true)
		
		var blood_effect: GPUParticles2D = blood_effect_scene.instantiate()
		blood_effect.global_position = global_position
		blood_effect.rotation = global_position.angle_to_point(shooter.global_position) + PI
		Global.blood_container.add_child(blood_effect)
		death_sound.play()

		Juice.spawn_floating_text(global_position, "+$%d" % money, Color(0.4, 1.0, 0.5), 26)
		shooter.gain_money(money)
		shooter.gain_score(randi_range(1, 10))
		Global.units_alive -= 1
		Global.units.erase(self)
		EventBus.enemy_killed.emit(is_boss)
		Global.notify_enemy_died()

		Sprite.material.set_shader_parameter("flash_modifier", 0.0)

		if randi_range(0, 25) == 0: # 4% chance
			Global.fabric_bonus.spawn_bonus(global_position)
