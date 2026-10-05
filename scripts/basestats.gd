class_name BaseStats extends Node

var health: int
var speed: int

func _init(_health: int, _speed: int) -> void:
	health = _health
	speed = _speed
	
func _take_damage(_amount: int) -> int:
	health = health - _amount
	return health
	
func _reduce_speed(_amount: int) -> int:
	speed = speed - _amount
	return speed
