class_name EnemySpawnTier
extends Resource
## Un palier de la table de spawn. S'applique si wave < max_wave (max_wave = 0
## = palier final attrape-tout). thresholds = paires [rate, type] : on parcourt
## les paires et on renvoie le premier type dont spawn_rate < rate.

@export var max_wave: int = 0
@export var thresholds: PackedInt32Array = PackedInt32Array()
