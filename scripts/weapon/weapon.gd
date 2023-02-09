class_name Weapon
extends Node2D

enum Weapon_Weight {LIGHT, MEDIUM, HEAVY}

var weapon_name: String

var accuracy: int 
var damage: int
var weapon_range: int
var spread: int
var fire_rate: int = 400
var actual_rate: int = 0

#var bullet_type: Bullet

var bullet_stock: int
var max_bullet_stock: int
var current_mag: int = mag_capacity
var mag_capacity: int
var reload_time: int
var bullet_speed: int = 300

var price: int
var weight: Weapon_Weight

var secondary_weapon: Weapon = null

var BulletScene = preload("res://scenes/weapon/bullet.tscn")

@onready var WeaponEnd = $WeaponEnd

func _process(_delta):
	shoot()
	look_at(get_global_mouse_position())
	
func has_secondary_weapon() -> bool:
	return (secondary_weapon != null)


# /!\ Function must act on stock bullet 
func refill(amount: int):
	if bullet_stock + amount <= max_bullet_stock:
		bullet_stock += amount
	else:
		bullet_stock = mag_capacity	


func reload():
	pass
	

func secondary_shoot():
	if has_secondary_weapon():
		secondary_weapon.shoot()
	
	
func shoot():
	if Input.is_action_pressed("shoot"):
		if(actual_rate == fire_rate):
			var _bullet = BulletScene.instantiate()
			_bullet.position = WeaponEnd.get_global_transform().origin
			get_tree().get_root().add_child(_bullet)
			_bullet.shoot(get_global_mouse_position(), bullet_speed)
			actual_rate = 0
		actual_rate += 1
		

