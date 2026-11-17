class_name EntityStats extends BaseStats
## Manages stats and stat changes for parent object
##
## Entity stats class tracks max health, current health, speed, defense,
## damage type vulnerabilities, damage type immunities, weight, and effects
##

signal speed_changed(old_val, new_val)

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
	if(amount < 0):
		push_error("Cannot do negative damage.")
		return health
	health = health - clamp(amount - defense, 0, max_health)
	if health < 0:
		health = 0
	return health

func heal(amount: int) -> int:
	if amount < 0:
		push_error("Cannot heal a negative amount of health.")
		return health
	health = health + amount
	if health > max_health:
		health = max_health
	return health

func modify_max_health(new_max:int)->int:
	if new_max <= 0:
		push_error("Maximum health cannot be at or below zero.")
		return max_health
	max_health = new_max
	if health > max_health:
		health = max_health
	return max_health
	
func modify_speed(amount: int) -> int:
	## Add or subtract from the entity's speed by some amount.
	## speed will not be reduced below zero
	var new_speed = speed + amount
	if new_speed < 0:
		new_speed = 0
	emit_signal("speed_changed", speed, new_speed)
	speed = new_speed
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
	under_effects.clear()

func update_defense(new_defense: int) -> int:
	defense = new_defense
	if defense < 0:
		defense = 0
	return defense

func deal_attack_damage(attack:AttackStats) -> int:
	var damage: int = attack.damage
	if immunity.has(attack.damage_type):
		return 0
		
	if vulnerability.has(attack.damage_type):
		damage = damage * 2
	take_damage(damage)
	return damage
