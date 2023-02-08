class_name Test
extends Node
# documentation shits goes here


signal my_signal

enum Test_MyEnum {A, B, C}	# ClassName_EnumName
enum MyEnum2 {
	A,
	B,
	C,		# Trailing coma if declaration on multiple line
}
const MY_CONST: int = 69420

@export var my_exported_var: String = "Hello World!"

var public_var_1: int = 123
var public_var_2: int

var _private_var_1: int = 321
var _private_var_2: int

# var containing Node ref or packed scene must use PascalCase
@onready var MyTimerChilNode: Timer = $Timer
@onready var public_onready_var: int


func _init(): # 2 <cr> after variables and after end of function
	# only built-in function don't need to precise return type (they are always void)
	pass


func _ready():
	# limit raw code in built-in function
	# always prefer calling a function
	pass
	
	
func _process(_delta):	# if you don't use delta var put a '_' before arg name
	pass
	

func _physics_process(_delta):
	pass
	

func my_public_function() -> void:
	var _x: float = 2.0	# private var declaration so var name start with '_'
	_private_var_2 += _x


func my_second_public_function() -> int:
	return 24


func _my_private_function() -> void:
	pass


func _my_second_private_function() -> bool:
	return (_private_var_1 > 10)	# ternary are ok while they easy to read and to understand


func _on_signal_trigger() -> void:	# signal methods name starts with '_on_'
	# signal methods goes at the bottom
	pass
