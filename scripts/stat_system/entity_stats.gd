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
var default_weight: int       ## Weight the entity normally is
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
	default_weight = _weight
	under_effects = []
	
	if _max_health <= 0:
		max_health = _health
	
func take_damage(amount: int) -> int:
	health = health - clamp(amount - defense, 0, max_health)
	if health < 0:
		health = 0
	return health

func heal(amount: int) -> int:
	health = health + amount
	if health > max_health:
		health == max_health
	return health

func modify_max_health(new_max:int)->int:
	max_health = new_max
	if health > max_health:
		health = max_health
	return max_health
	
func modify_speed(amount: int) -> int:
	speed = speed + amount
	if speed < 0:
		speed = 0
	return speed
	
func reset_health() -> int:
	health = max_health
	return health

func reset_speed() -> int:
	speed = normal_speed
	return speed

func add_immunity(new_immunity:int) -> Array[int]:
	if not immunity.has(new_immunity):
		immunity.append(new_immunity)
	return immunity

func remove_immunity(old_immunity:int) -> Array[int]:
	immunity.erase(old_immunity)
	return immunity
	
func add_vulnerability(new_vulnerability:int) -> Array[int]:
	if not vulnerability.has(new_vulnerability):
		vulnerability.append(new_vulnerability)
	return vulnerability

func remove_vulnerability(old_vulnerability:int) -> Array[int]:
	vulnerability.erase(old_vulnerability)
	return vulnerability
	
func update_weight(new_weight: int) -> int:
	weight = new_weight
	return weight

func reset_weight() -> int:
	weight = default_weight
	return weight

func add_effect(new_effect: int) -> Array[int]:
	if not under_effects.has(new_effect):
		under_effects.append(new_effect)
	return under_effects

func remove_effect(old_effect: int) -> Array[int]:
	under_effects.erase(old_effect)
	return under_effects
	
func clear_effects() -> void:
	for i in len(under_effects):
		under_effects.remove_at(i)
		
func update_defense(new_defense: int) -> int:
	defense = new_defense
	return defense
	

func deal_attack_damage(attack:AttackStats) -> int:
	var damage: int = attack.damage
	if immunity.has(attack.damage_type):
		return 0
		
	if vulnerability.has(attack.damage_type):
		damage = damage * 2
	
	return damage
