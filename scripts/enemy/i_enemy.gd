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
var _hit_tween: Tween = null


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

	timer.connect("timeout", func():
		Sprite.material.set_shader_parameter("flash_modifier", 0.0)
	)
	slow_timer.connect("timeout", func(): slow_timeout())
	path_timer.connect("timeout", func(): retarget_timeout())
	death_sound.connect("finished", func(): death_sound_finished())

func _physics_process(delta):
	if dead:
		return
	if state == 0:
		var _direction = (destination - global_position).normalized()
		_move(delta, _direction)
	elif state == 1:
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
		var _direction = to_local(agent.get_next_path_position()).normalized()
		_move(delta, _direction)

func take_damage(dmg: int, shooter: IPlayer) -> void:
	HealthBar.visible = true
	Sprite.material.set_shader_parameter("flash_modifier", 1.0)
	timer.start()
	Juice.spawn_floating_text(global_position, str(dmg), Color(1, 0.9, 0.4))
	_hit_punch()

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

func _move(delta, _direction) -> void:
	if _direction.x < 0:
		Sprite.flip_h = false
	elif _direction.x > 0:
		Sprite.flip_h = true
	var _velocity = _direction * speed * delta
	velocity = _velocity
	move_and_slide()

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
