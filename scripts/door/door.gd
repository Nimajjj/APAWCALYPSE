extends StaticBody2D

var price: int = 100
var open : bool = false 
var spawner_id : int


func activate(triggerer: Player) -> void : 
	if price < triggerer.money : 
		open = true 
		triggerer.money -= price 
		visible	 = false


func _on_area_2d_body_entered(body) -> void : 
	if body.is_in_group("player") : 
		body.add_interactible(self)
		


func _on_area_2d_body_exited(body) -> void : 
	if body.is_in_group("player") : 
		body.remove_interactible(self)


