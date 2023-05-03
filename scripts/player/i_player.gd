class_name IPlayer
extends CharacterBody2D


enum PC_State { IDLE, MOVE, INTERACT, DOWN, DEAD }

@export var id: int = -1
@export var health: float = 0
@export var max_health: float = 200
@export var regeneration: float = 0
@export var money: int = 1000
@export var speed: float = 0
@export var acceleration: float = 0
@export var friction: float = 0
@export var weapon_scene: PackedScene = null
@export var down_time: float = 0
@export var knockback_force: float = 0
@export var knockback_direction: Vector2 = Vector2.ZERO

var weapon: IWeapon = null
var aiming_at: Vector2 = Vector2.ZERO
var state: PC_State = PC_State.IDLE
var active_bonus: Array[String] = []
var interactible_in_range: Array[Interactible] = []
var direction = Vector2.ZERO
var reloading: bool = false
var score: int = 0
var down_timer: float = 0
var shaking = false

@onready var Sprite = $Sprite2D
@onready var AnimPlayer = $AnimationPlayer
@onready var Camera = $Camera2D
@onready var DownTimer = $DownTimer
@onready var Hitbox = $Hitbox
@onready var HitTimer = $HitTimer
@onready var FlashTimer = $FlashTimer
@onready var raycast = $RayCast2D


func _ready() -> void:
	health = max_health
	_spawn_default_weapon()
	
	Sprite.material = Sprite.material.duplicate()
	FlashTimer.connect("timeout", func():
		Sprite.material.set_shader_parameter("flash_modifier", 0.0)
	)
	
	Hitbox.connect("body_entered", Callable(func(body: Node): _on_Area2D_body_entered(body)))

func _physics_process(delta):
	weapon.look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("rmb"):
		position = get_global_mouse_position()

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


func start_shooting() -> void:
	weapon.shoot()


func stop_shooting() -> void:
	weapon.stop_shooting()


func take_bonus(bonus: IBonus) -> void:
	pass


func add_weapon(wp: IWeapon) -> void:
	drop_weapon()
	weapon = wp.duplicate()
	weapon.position = Vector2(1, -6)
	add_child(weapon)


func drop_weapon() -> void:
	if weapon != null:
		weapon.queue_free()
		weapon = null


func heal(heal: float) -> void:
	health += heal
	if health > max_health:
		health = max_health


func gain_money(money: int) -> void:
	self.money += money
	
	
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


func take_damage(damage: float, damager_pos: Vector2) -> void:
	if HitTimer.time_left <= 0:
		Sprite.material.set_shader_parameter("flash_modifier", 1.0)
		FlashTimer.start()
		
		health -= damage
		AnimPlayer.play("player_animations/DAMAGE")
		HitTimer.start()
		receive_knockback(damager_pos)
		shake_camera(3, 4, 4, 2)

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
	add_weapon(weapon_scene.instantiate())
	weapon.position = Vector2(1, -6)
	

func _on_Area2D_body_entered(body: Node) -> void:
	if body is IEnemy && state != PC_State.DOWN && state != PC_State.DEAD:
		take_damage(body.damage, body.global_position)
