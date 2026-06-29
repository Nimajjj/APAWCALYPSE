extends Interactible

var hit_possible: bool = true

@onready var health: int = 3
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox = $HitBox
@onready var hit_timer = $HitTimer
@onready var interaction_area = $InteractionArea2D

func _ready():
	message = "Press [E] to repair"
	_update_sprite()
	hit_timer.connect("timeout", Callable(func(): _hit_timer_timeout()))

func _physics_process(_delta):
	# Micro-perf : pas d'ennemi en vie -> rien a detecter, on saute les
	# couteux get_overlapping_bodies() (ex. entre les vagues).
	if Global.units_alive <= 0:
		return
	for body in interaction_area.get_overlapping_bodies():
		if body is IEnemy && body.state != 2:
			body.state = 2
			body.chase_target = Global.players[0]
			body.retarget()
			body.path_timer.start()
	for body in hitbox.get_overlapping_bodies():
		if not (body is IEnemy):
			continue
		if health > 0:
			# Fenetre intacte : seuls les ennemis en approche (etat 0) la cognent.
			if body.state == 0 and hit_possible:
				take_damage()
				hit_timer.start()
		elif body.state != 1:
			# Fenetre ouverte : la HitBox est cote exterieur, donc TOUT ennemi qui
			# s'y trouve est pousse a travers (etat 1, translation forcee sans
			# collision). Rattrape notamment les ennemis deja en poursuite (etat 2)
			# mais bloques dehors contre le mur, qui resteraient coinces.
			body.state = 1


func activate(player: IPlayer) -> void:
	health += 1
	if health > 3:
		health = 3
	player.money += 10
	_update_sprite()

func take_damage() -> void:
	health -= 1
	if health <= 0:
		health = 0
	hit_possible = false
	_update_sprite()

func can_activate(_player: IPlayer) -> bool:
	return health != 3

func _update_sprite() -> void:
	sprite.texture.region.position.y = (3 * 32) - health * 32

func _on_area_2d_body_entered(body) -> void :
	if body is IPlayer:
		body.add_interactible(self)

func _on_area_2d_body_exited(body) -> void :
	if body is IPlayer:
		body.remove_interactible(self)

func _hit_timer_timeout() -> void:
	hit_possible = true
