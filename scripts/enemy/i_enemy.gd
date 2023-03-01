class_name IEnemy
extends CharacterBody2D


@export var max_health: int
@export var speed: int
@export var money: int
@export var damage: int

#var bonus: IBonus = null
var health: int


func _physics_process(delta):
	_move()


func take_damage(dmg: int, shooter: IPlayer) -> void:
	health -= dmg
	if health <= 0:
		dies()


func _move() -> void:
	pass


func dies() -> void:
#	give money to killer
	queue_free()
