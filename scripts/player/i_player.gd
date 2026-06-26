class_name IPlayer
extends CharacterBody2D


enum PC_State { IDLE, MOVE, INTERACT, DOWN, DEAD }

@export var id: int = -1
@export var health: float = 0
@export var max_health: float = 200
@export var regeneration: float = 0
@export var money: int = 500
@export var speed: float = 0
@export var acceleration: float = 0
@export var friction: float = 0
@export var weapon_scene: PackedScene = null
@export var down_time: float = 2.0
@export var knockback_force: float = 0
@export var knockback_direction: Vector2 = Vector2.ZERO

var weapon: IWeapon = null
var aiming_at: Vector2 = Vector2.ZERO
var aim_has_target: bool = false  # vrai si un ennemi est cible (auto-aim)
var _last_facing: Vector2 = Vector2.RIGHT  # direction de visee memorisee
var state: PC_State = PC_State.IDLE
var active_bonus: Array[String] = []
var interactible_in_range: Array[Interactible] = []
var direction = Vector2.ZERO
var reloading: bool = false
var score: int = 0
var shaking = false

var money_x2: bool = false
var dead_shot: bool = false

# --- Capacites (cooldown) ---
@export var dash_distance: float = 230.0
@export var dash_cooldown: float = 15.0
@export var fire_ring_cooldown: float = 15.0
const FireRingScene := preload("res://scripts/ability/fire_ring.gd")
var _dash_ready: bool = true
var _fire_ready: bool = true
var invulnerable: bool = false
# Cooldowns restants / totaux (pour l'UI des capacites).
var dash_cd_left: float = 0.0
var dash_cd_total: float = 0.0
var fire_cd_left: float = 0.0
var fire_cd_total: float = 0.0

var damage_factor: float = 1
var reload_factor: float = 1

# Valeurs de base (avant multiplicateurs d'equilibrage Balance), capturees au
# _ready pour permettre un reglage a chaud sans accumulation.
var _base_speed: float = 0
var _base_max_health: float = 0

@onready var Sprite = $Sprite2D
@onready var AnimPlayer = $AnimationPlayer
@onready var Camera = $Camera2D
@onready var DownTimer = $DownTimer
@onready var Hitbox = $Hitbox
@onready var HitTimer = $HitTimer
@onready var FlashTimer = $FlashTimer
@onready var StartRegenerationTimer = $StartRegenerationTimer
@onready var RegenerationTicksTimer = $RegenerationTicksTimer
@onready var raycast = $RayCast2D


func _ready() -> void:
	# Stats persistantes du perso (overrides dev) avant capture des bases.
	GameConfig.apply_player(self)
	GameConfig.apply_abilities(self)
	_base_speed = speed
	_base_max_health = max_health
	apply_balance()
	health = max_health
	_spawn_default_weapon()
	Balance.changed.connect(apply_balance)

	Sprite.material = Sprite.material.duplicate()
	FlashTimer.connect("timeout", func():
		Sprite.material.set_shader_parameter("flash_modifier", 0.0)
	)

	StartRegenerationTimer.connect("timeout", func(): RegenerationTicksTimer.start())
	RegenerationTicksTimer.connect("timeout", func(): heal(self.max_health * 0.02))
	
	Hitbox.connect("body_entered", Callable(func(body: Node): _on_Area2D_body_entered(body)))

func _physics_process(delta):
	# Auto-aim (style Brotato) : l'arme vise en permanence l'ennemi le plus
	# proche. Plus aucune visee souris ; le jeu se joue au clavier/manette.
	_update_aim()
	_inputs_abilities()
	_tick_cooldowns(delta)

	if !shaking:
		_camera_follow_aim()

	match state:
		PC_State.IDLE:
			_idle_state()
		PC_State.MOVE:
			_move_state(delta)
		PC_State.INTERACT:
			_interact_state()
		PC_State.DOWN:
			_down_state()
		PC_State.DEAD:
			_dead_state()


## Recalcule les stats derivees des multiplicateurs d'equilibrage (Balance).
## Appele au _ready et a chaque changement du dashboard dev.
func apply_balance() -> void:
	speed = _base_speed * Balance.get_v("player_speed")
	var ratio: float = 1.0 if _base_max_health == 0 else health / max(1.0, max_health)
	max_health = _base_max_health * Balance.get_v("player_max_health")
	health = min(max_health, max_health * ratio)


func start_shooting() -> void:
	weapon.shoot(damage_factor * Balance.get_v("player_damage"))


func stop_shooting() -> void:
	weapon.stop_shooting()


func take_bonus(_bonus: IBonus) -> void:
	pass


func add_weapon(wp: IWeapon) -> void:
	drop_weapon()
	# Conserve l'identifiant de scene (perdu par duplicate()) pour que GameConfig
	# sache quelle arme configurer.
	var id: String = wp.config_id
	if id == "" and wp.scene_file_path != "":
		id = wp.scene_file_path.get_file().get_basename()
	weapon = wp.duplicate()
	weapon.config_id = id
	weapon.position = Vector2(1, -6)
	add_child(weapon)


func drop_weapon() -> void:
	if weapon != null:
		weapon.queue_free()
		weapon = null


func heal(amount: float) -> void:
	health += amount
	if health > max_health:
		health = max_health


func gain_money(amount: int) -> void:
	var gained: int = amount * 2 if money_x2 else amount
	if SaveManager.is_modifier_active("double_money"):
		gained *= 2
	self.money += gained
	EventBus.money_gained.emit(gained)


func gain_score(amount: int) -> void:
	EventBus.score_gained.emit(amount)
	self.score += amount # Personal score of the player


func add_interactible(obj: Interactible) -> void :
	interactible_in_range.append(obj)
	Global.in_game_ui.InteractibleLabel.text = obj.message


func remove_interactible(obj: Interactible) -> void :
	for i in interactible_in_range :
		if i == obj :
			interactible_in_range.erase(i)
			Global.in_game_ui.InteractibleLabel.text = ""


func interact() -> void :
	if len(interactible_in_range) > 0 :
		interactible_in_range[0].activate(self)

	
func _start_reload() -> void:
	pass


func _inputs_directions() -> void:
	direction = Vector2.ZERO
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")


## Tir automatique (style Brotato) : on tire seul quand un ennemi est dans la
## portee de l'arme. La touche/clic "shoot" reste un declencheur manuel optionnel
## (utile quand aucun ennemi n'est cible). La cadence et la recharge sont gerees
## par l'arme elle-meme.
func _inputs_shoot() -> void:
	if weapon == null:
		return
	var want_fire: bool = false
	if aim_has_target and global_position.distance_to(aiming_at) <= weapon.fire_range:
		want_fire = true
	elif Input.is_action_pressed("shoot"):
		want_fire = true
	if want_fire:
		start_shooting()
	else:
		stop_shooting()


func _inputs_reload() -> void:
	if reloading: return

	if Input.is_action_just_pressed("reload"):
		_start_reload()


## Declenche les capacites (dash defensif / cercle de feu offensif) sur appui.
func _inputs_abilities() -> void:
	if state == PC_State.DOWN or state == PC_State.DEAD:
		return
	if Input.is_action_just_pressed("ability_dash"):
		_do_dash()
	if Input.is_action_just_pressed("ability_fire"):
		_do_fire_ring()


## Dash defensif : projection rapide dans la direction courante, bref i-frames et
## trainee de fantomes. Cooldown defini dans GameConfig (categorie "abilities").
func _do_dash() -> void:
	if not _dash_ready:
		return
	_dash_ready = false
	var dir: Vector2 = direction.normalized() if direction.length() > 0.0 else _last_facing
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT

	# Limite la distance par un raycast (pas de traversee de mur).
	var dist: float = dash_distance
	raycast.target_position = dir * dash_distance
	raycast.force_raycast_update()
	if raycast.is_colliding():
		dist = global_position.distance_to(raycast.get_collision_point()) * 0.9

	dash_cd_total = dash_cooldown
	dash_cd_left = dash_cd_total

	invulnerable = true
	velocity = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(self, "position", position + dir * dist, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Fantomes successifs pendant le dash.
	for i in 4:
		_spawn_dash_ghost()
		await get_tree().create_timer(0.03).timeout
	invulnerable = false


## Etat des capacites pour l'UI (nom, touche, couleur, cooldown restant/total).
func get_abilities_status() -> Array:
	return [
		{"name": "Dash", "icon": ">>", "key": _ability_key("ability_dash"),
			"color": Color(0.45, 0.78, 1.0), "left": dash_cd_left, "total": dash_cd_total},
		{"name": "Feu", "icon": "()", "key": _ability_key("ability_fire"),
			"color": Color(1.0, 0.55, 0.15), "left": fire_cd_left, "total": fire_cd_total},
	]


func _ability_key(action: String) -> String:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			return OS.get_keycode_string(e.physical_keycode)
	return "-"


## Spectre semi-transparent qui s'estompe (trainee de dash).
func _spawn_dash_ghost() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = Sprite.texture
	ghost.region_enabled = Sprite.region_enabled
	if Sprite.region_enabled:
		ghost.region_rect = Sprite.region_rect
	ghost.flip_h = Sprite.flip_h
	ghost.global_position = Sprite.global_position
	ghost.scale = Sprite.global_scale
	ghost.modulate = Color(0.5, 0.8, 1.0, 0.6)
	ghost.z_index = 0
	Global.blood_container.add_child(ghost)
	var t := ghost.create_tween()
	t.tween_property(ghost, "modulate:a", 0.0, 0.25)
	t.tween_callback(ghost.queue_free)


## Cercle de feu offensif autour du joueur. Cooldown eleve.
func _do_fire_ring() -> void:
	if not _fire_ready:
		return
	_fire_ready = false
	fire_cd_total = fire_ring_cooldown
	fire_cd_left = fire_cd_total
	var ring: FireRing = FireRingScene.new()
	add_child(ring)
	shake_camera(3, 3, 3, 1)


## Decremente les cooldowns des capacites et les remet pretes a zero.
func _tick_cooldowns(delta: float) -> void:
	if dash_cd_left > 0.0:
		dash_cd_left -= delta
		if dash_cd_left <= 0.0:
			dash_cd_left = 0.0
			_dash_ready = true
	if fire_cd_left > 0.0:
		fire_cd_left -= delta
		if fire_cd_left <= 0.0:
			fire_cd_left = 0.0
			_fire_ready = true


func _inputs_interact() -> void:
	if Input.is_action_just_pressed("interact"):
		state = PC_State.INTERACT
		interact()


func receive_knockback(damage_source_pos: Vector2) -> void:
	knockback_direction = (position - damage_source_pos).normalized()
	knockback_force = 1000
	raycast.target_position = (knockback_direction * (knockback_force * 0.01)) * 1.1
	raycast.force_raycast_update()
	if(!raycast.is_colliding()):
		position += knockback_direction * knockback_force * 0.01



func shake_camera(duration: int, offset_x: float, offset_y: float, angle: float) -> void:
	if shaking:
		return
	shaking = true
	var start_pos = Camera.position
	var start_rot = Camera.rotation_degrees
	var fixed_start_pos = Camera.position
	var fixed_start_rot = Camera.rotation_degrees
	var loop = 0
	var r = 1
	var i = 0.0
	while loop < duration:
		var rand_offset = Vector2(randf_range(1.0, offset_x), randf_range(1.0, offset_y)) * r
		var rand_angle = randf_range(1.0, angle) * r
		r *= -1
		var target_pos = start_pos + rand_offset
		var target_rot = start_rot + rand_angle
		Camera.position = start_pos.lerp(target_pos, i)
		Camera.rotation_degrees = start_rot + rand_angle * i
		i += 0.25 # adjust speed here
		await(get_tree().create_timer(0.05).timeout)
		loop += 1
		start_pos = target_pos
		start_rot = target_rot
	Camera.position = fixed_start_pos
	Camera.rotation_degrees = fixed_start_rot
	shaking = false


func take_damage(damage: float, damager_pos: Vector2, sound: AudioStreamPlayer2D, is_reaper: bool) -> void:
	if invulnerable:
		return
	if HitTimer.time_left <= 0:
		Sprite.material.set_shader_parameter("flash_modifier", 1.0)
		FlashTimer.start()
		StartRegenerationTimer.start()
		RegenerationTicksTimer.stop()
		AnimPlayer.play("player_animations/DAMAGE")
		HitTimer.start()
		sound.play()		
		receive_knockback(damager_pos)
		shake_camera(3, 4, 4, 2)
		Juice.hit_stop()
		EventBus.player_damaged.emit(damage)
		
		if is_reaper && health < max_health / 2:
			health = 0
		else:
			health -= damage
			

		if health <= 0:
			health = 0
			state = PC_State.DOWN
			DownTimer.wait_time = down_time
			DownTimer.start()
			Notifier.show_banner("A TERRE !")


func _idle_state() -> void:
	_inputs_directions()
	_inputs_shoot()
	_inputs_reload()
	_inputs_interact()

	AnimPlayer.play("player_animations/IDLE")
	if Input.is_action_just_pressed("reload"):
		_start_reload()
	if Input.is_action_just_pressed("interact"):
		#IDLE --> INTERACT
		state = PC_State.INTERACT
	if direction.length() > 0:
		#IDLE --> MOVE
		state = PC_State.MOVE

	velocity = lerp(velocity, Vector2.ZERO, friction)
	AnimPlayer.play("player_animations/IDLE")


func _move_state(delta: float) -> void:
	_inputs_directions()
	_inputs_shoot()
	_inputs_reload()
	_inputs_interact()

	#MOVE --> IDLE
	if direction.length() <= 0:
		state = PC_State.IDLE

	# L'orientation du sprite est geree par l'auto-aim (_update_aim).
	velocity = (lerp(velocity, direction.normalized() * (speed - (weapon.weight*8000)), acceleration)) * delta

	AnimPlayer.play("player_animations/WALK")
	move_and_slide()


func _interact_state() -> void:
	#INTERACT --> IDLE
	if Input.is_action_just_released("interact"):
		state = PC_State.IDLE


func _down_state() -> void:
	# Le joueur est a terre, incapacite. DownTimer declenche la mort (-> DEAD)
	# apres down_time secondes ("dernier souffle"). Aucune action ici.
	pass


func _on_down_timer_timeout() -> void:
	# Connecte dans les scenes joueur (methode auparavant manquante).
	if state == PC_State.DOWN:
		state = PC_State.DEAD


func _dead_state() -> void:
	# Fin de partie via EventBus -> Game.trigger_game_over() (idempotent).
	EventBus.player_died.emit()


## Cible l'ennemi vivant le plus proche et oriente l'arme vers lui. En l'absence
## de cible, l'arme garde sa derniere direction (ou suit le deplacement).
func _update_aim() -> void:
	if weapon == null:
		return
	var nearest: IEnemy = _nearest_enemy()
	# On ne vise (et ne tire) que si l'ennemi le plus proche est dans la portee
	# de l'arme : l'arme ne pointe plus un zombie hors d'atteinte.
	if nearest != null and global_position.distance_to(nearest.global_position) <= weapon.fire_range:
		aim_has_target = true
		aiming_at = nearest.global_position
		_last_facing = (aiming_at - global_position).normalized()
	else:
		aim_has_target = false
		if direction.length() > 0.0:
			_last_facing = direction.normalized()
		aiming_at = global_position + _last_facing * 100.0
	weapon.look_at(aiming_at)
	# Le personnage regarde sa cible.
	if _last_facing.x < -0.05:
		Sprite.flip_h = false
	elif _last_facing.x > 0.05:
		Sprite.flip_h = true


const WALL_MASK := 2  # bit du layer des murs (StaticBody "Collisions")

func _nearest_enemy() -> IEnemy:
	var best: IEnemy = null
	var best_d: float = INF
	var range_sq: float = weapon.fire_range * weapon.fire_range
	var space := get_world_2d().direct_space_state
	for e in Global.units:
		if e == null or not is_instance_valid(e) or e.dead:
			continue
		var d: float = global_position.distance_squared_to(e.global_position)
		# Seuls les ennemis a portee et plus proches que le meilleur sont evalues
		# (limite les raycasts de ligne de vue).
		if d >= best_d or d > range_sq:
			continue
		if _wall_between(space, e.global_position):
			continue
		best_d = d
		best = e
	return best


## Vrai si un mur bloque la trajectoire entre le joueur et un point (pas de tir a
## travers les murs).
func _wall_between(space: PhysicsDirectSpaceState2D, target: Vector2) -> bool:
	var params := PhysicsRayQueryParameters2D.create(global_position, target, WALL_MASK)
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.exclude = [self]
	return not space.intersect_ray(params).is_empty()


## Camera centree sur le joueur (aucun decalage vers la visee : plus confortable).
func _camera_follow_aim() -> void:
	Camera.offset = Camera.offset.lerp(Vector2.ZERO, 0.2)


func _spawn_default_weapon() -> void:
	add_weapon(weapon_scene.instantiate())
	weapon.position = Vector2(1, -6)
	

func _on_Area2D_body_entered(body: Node) -> void:
	if body is IEnemy && state != PC_State.DOWN && state != PC_State.DEAD && !body.dead:
		if body.is_miser:
			var money_lost = floor(money * 0.07)
			money -= money_lost
			body.money += floor(money_lost * 0.75)
		take_damage(body.damage, body.global_position, body.bite_sound, body.is_reaper)
