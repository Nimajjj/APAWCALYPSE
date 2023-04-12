extends Interactible

@export var price: int = 100
@export var is_broken: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
		if (is_broken == true) :
			message = "Press E to repair the window $100"
						
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func activate(player: IPlayer) -> void:
		pass 
		
		


func can_activate(player: IPlayer) -> bool:
	return player.money >= price 


func _on_area_2d_body_entered(body) -> void :
	if body is IPlayer:
		body.add_interactible(self)


func _on_area_2d_body_exited(body) -> void :
	if body is IPlayer:
		body.remove_interactible(self)
