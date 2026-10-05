class_name EntityStats extends BaseStats

var max_health: int
var health: int
var speed: int
var defense: int

func _init(_name: String, _faction:int, _health: int, _speed: int, _defense: int = 0, _max_health: int = -1) -> void:
	name = _name
	faction = _faction
	health = _health
	speed = _speed
	defense = _defense
	if _max_health <= 0:
		max_health = _health
	
func take_damage(amount: int) -> int:
	print(name, " is in faction ", faction)
	print("Default faction is: ", Faction.DEFAULT)
	print(name, "'s Current Health: ", health)
	health = health - clamp(amount - defense, 0, max_health)
	if health < 0:
		health = 0
	print(name, " -'Ouch!' -", amount)
	print("Health Remaining: ", health)
	return health
	
func reduce_speed(_amount: int) -> int:
	speed = speed - _amount
	if speed < 0:
		speed = 0
	return speed
