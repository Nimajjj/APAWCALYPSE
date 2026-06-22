extends Node
## Pool de balles : recycle les Area2D de balles au lieu de les instancier /
## liberer en rafale (machine gun, shotgun 12 balles...). Reduit les
## allocations et le churn GC. Valide via le harnais de combat.

var _pools: Dictionary = {}  # PackedScene -> Array[IBullet] (balles en sommeil)
var _instantiated: int = 0   # diagnostic : nb total de balles reellement creees


func acquire(scene: PackedScene) -> IBullet:
	var arr = _pools.get(scene, null)
	if arr == null:
		arr = []
		_pools[scene] = arr
	var b: IBullet = null
	while not arr.is_empty():
		var cand: IBullet = arr.pop_back()
		if is_instance_valid(cand):
			b = cand
			break
	if b == null:
		b = scene.instantiate()
		b.set_meta("pool_scene", scene)
		get_tree().get_root().add_child(b)
		_instantiated += 1
	return b


func release(b: IBullet) -> void:
	if not is_instance_valid(b):
		return
	b.sleep()
	var scene: Variant = b.get_meta("pool_scene", null)
	if scene == null:
		b.queue_free()
		return
	var arr = _pools.get(scene, null)
	if arr == null:
		arr = []
		_pools[scene] = arr
	if not arr.has(b):
		arr.append(b)
