class_name IPlayer
extends CharacterBody2D


enum PC_State { IDLE, MOVE, INTERACT, DOWN, DEAD }

@export var id: int = -1
@export var health: float = 0
@export var max_health: float = 200
@export var regeneration: float = 0
@export var money: int = 10000000
@export var speed: float = 0
@export var acceleration: float = 0
@export var friction: float = 0
@export var weapon_scene: PackedScene = null
@export var down_time: float = 0
@export var knockback_force: float = 0
@export var knockback_direction: Vector2 = Vector2.ZERO

@export var weapon: IWeapon = null

var aiming_at: Vector2 = Vector2.ZERO
var state: PC_State = PC_State.IDLE
var active_bonus: Array[String] = []
var interactible_in_range: Array[Interactible] = []
var direction = Vector2.ZERO
var reloading: bool = false
var score: int = 0
var down_timer: float = 0
var shaking = false

var money_x2: bool = false
var dead_shot: bool = false

var damage_factor: float = 1
var reload_factor: float = 1

# MULTIPLAYER RELATED
var is_local_authority: bool
@onready var Synchronizer: MultiplayerSynchronizer = $Synchronizer/MultiplayerSynchronizer

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
	position = Global.game.FabricPlayer.global_position
	Synchronizer.set_multiplayer_authority(str(name).to_int())
	is_local_authority = Synchronizer.get_multiplayer_authority() == multiplayer.get_unique_id()
	Camera.enabled = is_local_authority
	
	if is_local_authority:
		Global.in_game_ui.player = self
	
	health = max_health
	_spawn_default_weapon()
	
	Sprite.material = Sprite.material.duplicate()
	FlashTimer.connect("timeout", func():
		Sprite.material.set_shader_parameter("flash_modifier", 0.0)
	)

	StartRegenerationTimer.connect("timeout", func(): RegenerationTicksTimer.start())
	RegenerationTicksTimer.connect("timeout", func(): heal(self.max_health * 0.02))
	
	Hitbox.connect("body_entered", Callable(func(body: Node): _on_Area2D_body_entered(body)))

func _physics_process(delta):
	if !is_local_authority:
		return

	if !shaking:
		_camera_follow_mouse()

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
			
	if Input.is_action_just_pressed("rmb"):
		position = get_global_mouse_position()


func start_shooting() -> void:
	weapon.shoot(damage_factor)


func stop_shooting() -> void:
	weapon.stop_shooting()


func take_bonus(_bonus: IBonus) -> void:
	pass


# ADD WEAPON ###################################################

func add_weapon(wp: String) -> void:
	if is_local_authority:
		rpc_id(1, "_add_weapon_server", wp, name)
		_add_weapon_impl(wp)
	
	
@rpc("any_peer")
func _add_weapon_server(wp: String, client: String) -> void:
	var caller_id = multiplayer.get_remote_sender_id()
	if str(name).to_int() != caller_id:
		print("Illegally calling _add_weapon_client! The culprit is: " + str(caller_id))
		return

	rpc("_add_weapon_client", wp, client)
	_add_weapon_impl(wp)


@rpc
func _add_weapon_client(wp: String, client: String) -> void:
	if is_local_authority: return
	for player in Global.players:
		if player.name == client:
			player.drop_weapon()
			player._add_weapon_impl(wp)
	drop_weapon()
	_add_weapon_impl(wp)
	
	

func _add_weapon_impl(wp: String) -> void:
	drop_weapon()
	weapon = Weapons.List[wp].instantiate()
	add_child(weapon)
	weapon.position = Vector2(1, -6)
	weapon.player = self


func drop_weapon() -> void:
	if weapon != null:
		weapon.queue_free()
		weapon = null
		
		for child in get_children():
			if child is IWeapon:
				if !is_local_authority:
					child.free()
				
		
################################################################


func heal(heal: float) -> void:
	health += heal
	if health > max_health:
		health = max_health

@rpc
func gain_money(money: int) -> void:
	if(money_x2): self.money += money * 2
	else: self.money += money


func gain_score(score: int) -> void:
	Global.game.score += score
	self.score += score # Personal score of the player


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


func _inputs_shoot() -> void:
	if Input.is_action_pressed("shoot"):
		start_shooting()
	if Input.is_action_just_released("shoot"):
		stop_shooting()


func _inputs_reload() -> void:
	if reloading: return

	if Input.is_action_just_pressed("reload"):
		_start_reload()


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
		
		if is_reaper && health < max_health / 2:
			health = 0
		else:
			health -= damage
			

		if health <= 0:
			health = 0
			state = PC_State.DOWN
			DownTimer.start()


func _idle_state() -> void:
	_inputs_directions()
	_inputs_shoot()
	_inputs_reload()
	_inputs_interact()

	AnimPlayer.play("player_animations/IDLE")
	if Input.is_action_just_pressed("shoot"):
		start_shooting()
	if Input.is_action_just_released("shoot"):
		stop_shooting()
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

	if direction.x < 0:
		Sprite.flip_h = false
	elif direction.x > 0:
		Sprite.flip_h = true

	velocity = (lerp(velocity, direction.normalized() * (speed - (weapon.weight*8000)), acceleration)) * delta

	AnimPlayer.play("player_animations/WALK")
	move_and_slide()


func _interact_state() -> void:
	#INTERACT --> IDLE
	if Input.is_action_just_released("interact"):
		state = PC_State.IDLE


func _down_state() -> void:
	#DOWN --> DEAD
	if down_timer >= down_time:
		state = PC_State.DEAD


func _dead_state() -> void:
	pass


func _camera_follow_mouse() -> void:
	var mouse_pos = get_global_mouse_position()
	Camera.offset.x = ((mouse_pos.x - global_position.x) / (1280.0 / 125.0)) * 0.2
	Camera.offset.y = ((mouse_pos.y - global_position.y) / (720.0 / 125.0)) * 0.2


func _spawn_default_weapon() -> void:
	add_weapon(Weapons.WPN_MP5)
	

func _on_Area2D_body_entered(body: Node) -> void:
	if body is IEnemy && state != PC_State.DOWN && state != PC_State.DEAD && !body.dead:
		if body.is_miser:
			var money_lost = floor(money * 0.07)
			money -= money_lost
			body.money += floor(money_lost * 0.75)
		take_damage(body.damage, body.global_position, body.bite_sound, body.is_reaper)
