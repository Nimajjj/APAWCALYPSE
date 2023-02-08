extends Node2D

class_name Weapon

enum Weapon_Weight {LIGHT, MEDIUM, HEAVY}

var weapon_name: String

var accuracy: int 
var damage: int
var range: int
var spread: int
var fire_rate: int

#var bullet_type: Bullet

var bullet_stock: int
var max_bullet_stock: int
var current_mag: int = mag_capacity
var mag_capacity: int
var reload_time: int

var price: int
var weight: Weapon_Weight

var secondary_weapon: Weapon = null


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
	pass
