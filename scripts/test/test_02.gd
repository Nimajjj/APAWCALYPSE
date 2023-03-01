extends Node2D

var player: IPlayer = null
var dog: IEnemy = null
var zombie: IEnemy = null

# Called when the node enters the scene tree for the first time.
func _ready():
	player = $FabricPlayer.create_player()
	dog = $FabricEnemy.create_enemy("dog", Vector2(0,0))
	zombie = $FabricEnemy.create_enemy("zombie", Vector2(0,0))
	



