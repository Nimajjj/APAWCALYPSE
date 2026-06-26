extends IEnemy
## Exploder (inspire Brotato) : a sa mort, explose et inflige des degats de zone
## au joueur s'il est trop proche, avec un FX lumineux qui gonfle.

const LIGHT_TEX := preload("res://assets/debug/light.png")

@export var explosion_radius: float = 70.0
@export var explosion_damage: float = 35.0


func dies(shooter: IPlayer) -> void:
	if dead:
		return
	super.dies(shooter)
	_explode()


func _explode() -> void:
	# Degats de zone aux joueurs proches.
	for p in Global.players:
		if p != null and is_instance_valid(p):
			if global_position.distance_to(p.global_position) <= explosion_radius:
				p.take_damage(explosion_damage, global_position, bite_sound, false)

	# FX : halo lumineux orange qui gonfle puis disparait.
	var fx := Sprite2D.new()
	fx.texture = LIGHT_TEX
	fx.modulate = Color(1.0, 0.5, 0.12, 0.95)
	fx.z_index = 5
	fx.global_position = global_position
	fx.scale = Vector2(0.4, 0.4)
	Global.blood_container.add_child(fx)
	var tw := fx.create_tween()
	tw.tween_property(fx, "scale", Vector2(3.0, 3.0), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(fx, "modulate:a", 0.0, 0.32)
	tw.tween_callback(fx.queue_free)
