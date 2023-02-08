class_name IEnemy
extends Node2D

var enemy_scene:PackedScene = preload("res://scenes/enemy/enemy.tscn")


func create_enemy(hp, speed, money) -> Enemy:
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.health = hp
	enemy.speed = speed
	enemy.money = money
	return enemy
