class_name IWeapon
extends Node2D

enum Weapon_Weight {LIGHT, MEDIUM, HEAVY}

@export var weapon_name: String = ""
@export var accuracy: int = 0
@export var damage: int = 0
@export var weapon_range: float = 0
@export var spread: float = 0.0
@export var fire_rate: float = 0
@export var bullet_stock: int = 0
@export var stock_factor: int = 0
@export var max_bullet_stock: int = 0
@export var current_mag: int = 0
@export var mag_capacity: int = 0
@export var reload_time: float = 0
@export var price: int = 0
@export var weight: Weapon_Weight
@export var shake_power: float = 0
## Portee de declenchement de l'auto-fire (px monde). L'arme tire seule quand
## l'ennemi le plus proche est a cette distance ou moins. La camera ayant un zoom
## ~5 (largeur visible ~384 px monde), ~180 couvre l'ecran sans tirer hors-champ.
@export var fire_range: float = 160.0
## Multiplicateur de taille des projectiles propre a l'arme.
@export var bullet_scale: float = 1.0

@export var BulletScene: PackedScene = null
@export var ShootEffectScene: PackedScene

var config_id: String = ""  # identifiant de scene (ex. "ak47") pour GameConfig
var base_bullet_scale: float = 1.0  # taille de balle de base (avant modif. roguelike)
var actual_rate: int = 0
var weapon_direction: Vector2
var reloading: bool = false
var shoot_effect: GPUParticles2D = null
var can_shoot: bool = true
var _recoil_tween: Tween
var _facing_left: bool = false  # vrai quand l'arme vise vers la gauche (miroir)

@onready var WeaponEnd = $WeaponEnd
@onready var Sprite = $Sprite2D
@onready var timer = $Timer
@onready var fire_rate_timer = $FireRateTimer
@onready var _base_scale: Vector2 = scale


func _ready():
	# Applique les stats persistantes (overrides du panel dev) avant tout calcul
	# derive (chargeur, timers...).
	GameConfig.apply_weapon(self)

	if ShootEffectScene != null:
		shoot_effect = ShootEffectScene.instantiate()
		WeaponEnd.add_child(shoot_effect)

	base_bullet_scale = bullet_scale  # capture avant tout modificateur roguelike

	current_mag = mag_capacity
	bullet_stock = mag_capacity * 2
	max_bullet_stock = bullet_stock * stock_factor

	fire_rate_timer.wait_time = fire_rate * Balance.get_v("weapon_fire_rate")
	if(get_parent() is IPlayer):
		timer.wait_time = _reload_wait_time()
	timer.connect("timeout", func(): reload())
	fire_rate_timer.connect("timeout", func(): reset_fire_rate())
	Balance.changed.connect(func():
		fire_rate_timer.wait_time = fire_rate * Balance.get_v("weapon_fire_rate"))


## Temps de recharge effectif (modificateurs joueur + equilibrage global).
func _reload_wait_time() -> float:
	var f: float = get_parent().reload_factor if get_parent() is IPlayer else 1.0
	return reload_time * f * Balance.get_v("player_reload")


func _process(_delta):
	# Direction de tir issue de l'auto-aim du joueur (plus de visee souris).
	var parent := get_parent()
	if parent is IPlayer:
		weapon_direction = (parent.aiming_at - global_position).normalized()
	else:
		weapon_direction = (get_global_mouse_position() - global_position).normalized()
	if(current_mag == 0 && !reloading):
		trigger_reload()

	if Input.is_action_just_pressed("reload"):
		trigger_reload()


func trigger_reload() -> void:
	if current_mag == mag_capacity: return
	if reloading: return
	# Reserve de munitions infinie : on ne bloque plus le rechargement quand le
	# stock est vide. Seuls le temps de recharge et la cadence de tir limitent.
	if(get_parent() is IPlayer):
		timer.wait_time = _reload_wait_time() # update reload time
	timer.start()
	Global.in_game_ui.reloading()
	reloading = true


func reload() -> void:
	# Reserve infinie : le chargeur est toujours rempli a fond, sans puiser dans
	# un stock limite. La cadence et le temps de recharge restent les seules
	# contraintes.
	if current_mag < mag_capacity:
		current_mag = mag_capacity
		timer.stop()
		reloading = false
		Global.in_game_ui.stop_reloading()


func shoot(player_damage_factor: float) -> void:
	if reloading: return
	if(fire_rate_timer.time_left > 0): return
	if(can_shoot):
		if(current_mag > 0):
			fire_rate_timer.start()
			can_shoot = false
			_punch()
			if shoot_effect != null:
				shoot_effect.emitting = true
			_fire_bullet(player_damage_factor, false, weapon_direction.rotated(randf_range(-spread, spread)))
			current_mag -= 1
			actual_rate = 0
			get_parent().shake_camera(3, shake_power, shake_power, shake_power / 2)
			$AudioStreamPlayer.play()
		actual_rate += 1

## Tire une balle depuis le pool (recyclage, voir BulletPool).
func _fire_bullet(player_damage_factor: float, pierce: bool, dir: Vector2) -> void:
	var b := BulletPool.acquire(BulletScene)
	b.launch(WeaponEnd.get_global_transform().origin, get_parent() as IPlayer, int(damage * player_damage_factor), weapon_range, pierce, dir, bullet_scale)
	EventBus.shot_fired.emit()


## Oriente l'arme vers `dir`. L'arme pointe vers +X par defaut (rotation 0).
##
## Vers la DROITE : rotation libre vers la cible.
## Vers la GAUCHE : on ne tourne PAS l'arme de ~180deg (ce qui la mettrait a
## l'envers ET retournerait son decalage vertical vers le bas — l'arme "passait en
## bas"). On applique a la place une SYMETRIE selon l'axe vertical (scale.x < 0),
## qui garde l'arme a la meme hauteur et a l'endroit. La rotation est alors decalee
## de PI pour compenser le miroir et faire pointer le canon vers la cible.
func aim(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	_facing_left = dir.x < 0.0
	rotation = (dir.angle() + PI) if _facing_left else dir.angle()
	scale = _facing_scale(_base_scale)


## Echelle signee selon le sens de visee : x negatif = miroir vertical (vise gauche).
func _facing_scale(s: Vector2) -> Vector2:
	return Vector2(-s.x if _facing_left else s.x, s.y)


## Change la taille affichee de l'arme (utilise par le dashboard dev). Met a jour
## l'echelle de base pour ne pas casser le "punch" de recul.
func set_display_scale(s: float) -> void:
	_base_scale = Vector2(s, s)
	scale = _facing_scale(_base_scale)


func stop_shooting() -> void:
	if shoot_effect != null:
		shoot_effect.emitting = false

func reset_fire_rate() -> void:
	can_shoot = true

func _on_timer_timeout() -> void:
	reload()


## Petit "punch" d'echelle a chaque tir (recul visuel). S'auto-corrige vers
## l'echelle de base meme en tir rapide.
func _punch() -> void:
	if _recoil_tween != null and _recoil_tween.is_running():
		_recoil_tween.kill()
	# Le "punch" preserve le signe du miroir (scale.x < 0 si l'arme vise a gauche).
	var base: Vector2 = _facing_scale(_base_scale)
	scale = base
	_recoil_tween = create_tween()
	_recoil_tween.tween_property(self, "scale", base * 1.12, 0.04)
	_recoil_tween.tween_property(self, "scale", base, 0.08)
