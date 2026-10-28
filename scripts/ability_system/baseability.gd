class_name BaseAbility extends Node

# Every ability has:
#    AttackStats
#    Hitbox
#    Name
#    Icon
#    Type: melee, range, environment
#    Ability to update stats (?) (upgrade abilities)
#    

var stats: AttackStats
var hitbox: Hitbox
var icon: String

func _init(
	_name:String, 
	_icon:String, 
	_stats:AttackStats,
	_shape:Shape2D, 
	_lifespan: float = 0.0,
	_emit_signal = false
	) -> void:
	name = _name
	stats = _stats
	hitbox = Hitbox.new(_stats, _lifespan, _shape, HitLog.new(), _emit_signal)
	
