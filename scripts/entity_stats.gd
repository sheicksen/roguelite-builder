class_name EntityStats extends BaseStats

var max_health: int
var health: int
var speed: int
var defense: int

func _init(_faction:int, _health: int, _speed: int, _max_health: int = -1) -> void:
	faction = _faction
	health = _health
	speed = _speed
	if _max_health < 0:
		max_health = _health
	
func take_damage(_amount: int) -> int:
	health = health - clamp(_amount - defense, 0, max_health)
	if health < 0:
		health = 0
	return health
	
func reduce_speed(_amount: int) -> int:
	speed = speed - _amount
	if speed < 0:
		speed = 0
	return speed
