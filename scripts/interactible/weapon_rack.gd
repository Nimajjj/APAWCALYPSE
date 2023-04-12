extends Interactible

@export var price: int = 100
@export var weapon_scene: PackedScene = null

var weapon : IWeapon = null

func _ready():
	weapon = weapon_scene.instantiate()
	weapon.get_node("Sprite2D").scale = Vector2(1.25, 1.25)
	weapon.position.x -= (weapon.get_node("Sprite2D").texture.get_size().x * weapon.get_node("Sprite2D").scale.x) / 6
	add_child(weapon)
	
	message = "Press [E] to buy {0} for {1}$".format([weapon.name, price])


func activate(player: IPlayer) -> void:
	if can_activate(player) :
		player.money -= price
		player.add_weapon(weapon.duplicate())


func can_activate(player: IPlayer) -> bool:
	return player.money >= price


func _on_area_2d_body_entered(body) -> void :
	if body is IPlayer:
		body.add_interactible(self)


func _on_area_2d_body_exited(body) -> void :
	if body is IPlayer:
		body.remove_interactible(self)



