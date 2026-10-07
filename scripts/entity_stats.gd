class_name EntityStats extends BaseStats
## Manages stats and stat changes for parent object
##
## Entity stats class tracks max health, current health, speed, defense,
## damage type vulnerabilities, damage type immunities, weight, and effects
##

var max_health: int           ## Max health
var health: int               ## Current health
var speed: int                ## Current speed
var normal_speed: int         ## Normal speed
var defense: int              ## Defense against damage
var vulnerability: Array[int] ## Types of damage entity is vulnerable to
var immunity: Array[int]      ## Types of damage entity is immune to
var weight: int               ## Weight of entity, counteracts knockback
var under_effects: Array[int] ## Effects (i.e. poison) currently affecting the entity

func _init(
	_name: String, 
	_faction:int, 
	_health: int, 
	_speed: int, 
	_defense: int = 0, 
	_max_health: int = -1,
	_vulnerability: Array[int] = [],
	_immunity: Array[int] = [],
	_weight:int = 0
) -> void:
	name = _name
	faction = _faction
	health = _health
	speed = _speed
	normal_speed = _speed
	defense = _defense
	vulnerability = _vulnerability
	immunity = _immunity
	weight = _weight
	under_effects = []
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
	
func reduce_speed(amount: int) -> int:
	speed = speed - amount
	if speed < 0:
		speed = 0
	return speed
	
func reset_health() -> int:
	health = max_health
	return health

func reset_speed() -> int:
	speed = normal_speed
	return speed
