class_name IEnemy
extends CharacterBody2D


@onready var Sprite = $Sprite2D

@export var max_health: int
@export var speed: int
@export var money: int
@export var damage: int

#var bonus: IBonus = null
var health: int


func _physics_process(delta):
	_move(delta)


func take_damage(dmg: int, shooter: IPlayer) -> void:
	health -= dmg
	if health <= 0:
		dies(shooter)


func _move(delta) -> void:
    var target = Global.players[0]
	var _direction = (target.global_position - global_position).normalized()
	if _direction.x < 0:
		Sprite.flip_h = false
	elif _direction.x > 0:
		Sprite.flip_h = true
	var _velocity = _direction * speed * delta
	position += _velocity


func dies(shooter: IPlayer) -> void:
	print("shooter money before kill: ", shooter.money)
	shooter.gain_money(money)
	print("shooter money after kill: ", shooter.money)
	queue_free()
