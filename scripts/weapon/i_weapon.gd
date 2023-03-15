class_name IWeapon
extends Node2D

enum Weapon_Weight {LIGHT, MEDIUM, HEAVY}

@export var weapon_name: String = ""
@export var accuracy: int = 0
@export var damage: int = 0
@export var weapon_range: int = 0
@export var spread: int = 0
@export var fire_rate: int = 0
@export var bullet_stock: int = 0
@export var max_bullet_stock: int = 0
@export var current_mag: int = 0
@export var mag_capacity: int = 0
@export var reload_time: int = 0
@export var price: int = 0
@export var weight: Weapon_Weight

@export var secondary_weapon: IWeapon = null
@export var BulletScene: PackedScene = null

var actual_rate: int = 0

@onready var WeaponEnd = $WeaponEnd


func _process(delta):
#	look_at(get_global_mouse_position())
#	listen_shoot_input()
	var weapon_direction: Vector2 = get_global_mouse_position() - global_position
	weapon_direction = weapon_direction.normalized()
	look_at(get_global_mouse_position())
	listen_shoot_input(weapon_direction)


func has_secondary_weapon() -> bool:
	return (secondary_weapon != null)


func reload() -> void:
	if current_mag < mag_capacity:
		if bullet_stock > 0:
			if bullet_stock >= mag_capacity:
				bullet_stock -= mag_capacity
				current_mag = mag_capacity
			else:
				current_mag = bullet_stock
				bullet_stock = 0


func listen_shoot_input(weapon_direction: Vector2) -> void:
	if Input.is_action_pressed("shoot"):
		if(actual_rate == fire_rate):
			var bullet: IBullet = BulletScene.instantiate()
			bullet.position = WeaponEnd.get_global_transform().origin
			bullet.damage = damage
			bullet.life_time = weapon_range

			get_tree().get_root().add_child(bullet)
			bullet.shoot(get_parent(), get_global_mouse_position(), weapon_direction)
			actual_rate = 0
		actual_rate += 1
