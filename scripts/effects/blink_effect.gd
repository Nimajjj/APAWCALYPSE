extends Node2D

@export var on_rate: int = 300
@export var off_rate: int = 100

var state: bool = true
var base_energy: float

@onready var light: PointLight2D = get_parent()


func _ready() -> void:
	base_energy = light.energy


func _process(_delta: float) -> void:
	var r: int = randi() % (on_rate if state else off_rate)
	if r != 0: return
	
	if state: light.energy = 0
	else: light.energy = base_energy
		
	state = !state
