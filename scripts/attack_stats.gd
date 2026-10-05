class_name AttackStats extends BaseStats

var damage: int
var damage_type: int
var targets: Array[int]

func _init(_damage:int, _type:int, _targets:Array[int]) -> void:
	damage = _damage
	damage_type = _type
	targets = _targets
