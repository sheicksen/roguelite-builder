class_name AttackStats extends BaseStats
## Used to define how attacks and abilities affect entities.
##
## Tracks an amount of damage, damage type, target layers, knock back amount,
## knockback direction, imposed slowness, duration damage is dealt over.
## Note: see parent class BaseStats for Damage Type Enumerations
##
var damage: int ## Amount of Damage
var damage_type: int ## Damage Type
var targets: Array[int] ## Target layers/factions
var knockBack: int ## Amount of Knockback
var knockBack_dir: Vector2 ## Knockback direction
var slowness: int ## Amount of reduced speed
var duration: float ## Amount of time over which damage is applied



func _init(
	_damage:int, 
	_type:int, 
	_targets:Array[int], 
	_knockback:int = 0, 
	_knockBack_dir = Vector2(0,0), 
	_slowness:int = 0, 
	_duration:float = 0.0
) -> void:
	damage = _damage
	damage_type = _type
	targets = _targets
	knockBack = _knockback
	slowness = _slowness
	duration = _duration
