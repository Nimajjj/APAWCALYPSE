class_name EnemySpawnTable
extends Resource
## Table de spawn des ennemis, editable en ressource (.tres) sans toucher au code.
## Type renvoye : 0 zombie, 1 woman, 2 buffed, 3 miser, 4 reaper (5 = boss, gere a
## part), 6 runner, 7 brute, 8 charger, 9 exploder, 10 ant, 11 beetle,
## 12 explosive_fly, 13 toxic_fly, 14 wasp.

@export var tiers: Array[EnemySpawnTier] = []


func pick_type(wave: int, rate: int) -> int:
	for tier in tiers:
		if tier.max_wave == 0 or wave < tier.max_wave:
			var th := tier.thresholds
			var i := 0
			while i + 1 < th.size():
				if rate < th[i]:
					return th[i + 1]
				i += 2
			return 0
	return 0
