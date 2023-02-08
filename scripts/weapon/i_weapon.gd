class_name IWeapon
extends Node2D

var weapon_scene:PackedScene = preload("res://scenes/weapon/weapon.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func create_weapon(name: String) -> Weapon:
	var weapon: Weapon = weapon_scene.instantiate()	
	weapon.name = name
	add_child(weapon)
	return weapon;
