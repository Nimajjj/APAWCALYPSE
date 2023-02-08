class_name Enemy
extends Node2D


var max_health: int
var health: int
var velocity: Vector2
var speed: int
var money: int
var damage: int

func _move():
	pass
	
func take_damage(dmg):
	if health - dmg < 0:
		health = 0;
	else:
		health -= dmg;



