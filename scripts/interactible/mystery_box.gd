extends Interactible

var price: int = 100

var weapons: Array = []

var x: int = 2
var rand: int 
var randomposition : int
var i: int 
@onready var timer: Timer = $Timer
@onready var secondtimer: Timer = $SecondTimer
var t: int = 0 
@onready var sprite: Sprite2D = $Sprite2D
@onready var shuffle_weapon: Sprite2D = $ShuffleWeapon
var isopened : bool = false

var weapons_scenes: Array[PackedScene] = []

var weapon : IWeapon = null

func _ready():
	change_position()
	message = "Press [E] to open the box"
	weapons_scenes.append(preload("res://scenes/weapon/ak47.tscn"))
	weapons_scenes.append(preload("res://scenes/weapon/mp5.tscn"))
	weapons_scenes.append(preload("res://scenes/weapon/shotgun.tscn"))
	weapons_scenes.append(preload("res://scenes/weapon/pistol.tscn"))
	
	

func activate(player: IPlayer) -> void:
	if isopened :
		player.add_weapon(weapon.duplicate())
		weapon.queue_free()
		secondtimer.stop()
		sprite.region_rect.position.x = 0
		isopened = false 
		message = "Press [E] to open the box"
		rand = randi() % 2 + 1
		print(rand)
		if x == rand : 
			change_position()
		return
	if can_activate(player) && !isopened:
		player.money -= price
		_update_sprite()
		timer.start()
		

func can_activate(player: IPlayer) -> bool:
	return player.money >= price

func _update_sprite() -> void:
	sprite.region_rect.position.x = 32
	

func _on_area_2d_body_entered(body) -> void :
	if body is IPlayer:
		body.add_interactible(self)


func _on_area_2d_body_exited(body) -> void :
	if body is IPlayer:
		body.remove_interactible(self)


func _on_timer_timeout():
	t += 1
	shuffle_weapon.visible = true 
	shuffle_weapon.region_rect.position.y += 32
	if 	shuffle_weapon.region_rect.position.y > 96 :
		shuffle_weapon.region_rect.position.y = 0
	if t == 10 : 
		timer.stop()
		shuffle_weapon.visible = false
		i = randi() % weapons_scenes.size() 
		weapon = weapons_scenes[i].instantiate()
		weapon.position = shuffle_weapon.position
		add_child(weapon)
		message = "Press [E] to take {0}".format([weapon.name])
		t = 0 
		secondtimer.start()
		isopened = true
		
		
		
	
func change_position():
	var possible_pos: Array[Vector2] = [
		Vector2(1382, 7),
		Vector2(85, 222),
		Vector2(1231, 390),
		Vector2(1130, 577),
		Vector2(184, 316),
		Vector2(-277, 456),
	]
	var new_pos: Vector2 = possible_pos[randi() % possible_pos.size()]
	if new_pos == position:
		change_position()
		return
	position = new_pos
	return
		

func _on_second_timer_timeout():
	weapon.queue_free()
	sprite.region_rect.position.x = 0
	isopened = false
	message = "Press [E] to open the box"
	rand = randi() % 2 + 1
	print(rand)
	if x == rand : 
		change_position() 
	return
