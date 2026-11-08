class_name Inventory extends Resource
@export var coins: int = 0
@export var corruption: int = 0
@export var pickups: Array = []
@export var ability_1: String = ""
@export var ability_2: String = ""
@export var ability_3: String = ""

var owner:Node2D

func _init(_owner:Node2D) -> void:
	if "stats" in _owner:
		owner = _owner
	else:
		push_error("Node must have EntityStats to use inventory.")
