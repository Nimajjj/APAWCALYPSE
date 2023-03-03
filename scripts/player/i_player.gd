class_name IPlayer
extends CharacterBody2D

enum PC_State { IDLE, MOVE, INTERACT, DOWN, DEAD }

@export var id: int = -1
@export var health: float = 0
@export var max_health: float = 0
@export var regeneration: float = 0
@export var money: int = 0
@export var speed: float = 0
@export var acceleration: float = 0
@export var friction: float = 0
@export var weapon: PackedScene = null
@export var down_time: float = 0

var aiming_at: Vector2 = Vector2.ZERO
var state: PC_State = PC_State.IDLE
var active_bonus: Array[IBonus] = []
var interactible_in_range: Array[Interactible] = []
var direction = Vector2.ZERO
var reloading: bool = false
var down_timer: float = 0

@onready var Sprite = $Sprite2D
@onready var AnimPlayer = $AnimationPlayer
@onready var Camera = $Camera2D
@onready var DownTimer = $DownTimer


func _physics_process(delta):
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
	pass


func stop_shooting() -> void:
	pass


func take_bonus(bonus: IBonus) -> void:
	pass


func add_weapon(weapon: IWeapon) -> void:
	pass


func drop_weapon() -> void:
	weapon = null


func heal(heal: float) -> void:
	health += heal
	if health > max_health:
		health = max_health


func gain_money(money: int) -> void:
	self.money += money


func add_interactible(obj: Interactible) -> void :
	interactible_in_range.append(obj)


func remove_interactible(obj: Interactible) -> void :
	for i in interactible_in_range :
		if i == obj :
			interactible_in_range.erase(i)


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
	if Input.is_action_just_pressed("shoot"):
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


func take_damage(damage: float) -> void:
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

	AnimPlayer.play("IDLE")
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
	AnimPlayer.play("IDLE")


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

	velocity = lerp(velocity, direction.normalized() * speed, acceleration)
	AnimPlayer.play("WALK")
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
	Camera.offset.x = (mouse_pos.x - global_position.x) / (1280.0 / 125.0)
	Camera.offset.y = (mouse_pos.y - global_position.y) / (720.0 / 125.0)
