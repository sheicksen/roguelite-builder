class_name Hitbox extends Area2D

## Blueprint:
# Can be used for obstacles
# Can be used for attacks
# Can be used for enemy/player bodies
# Not a collider, but should match size of collider for obstacles, enemies, etc.
# Should be able to affect any, and numerous stats 

## Stats Array/Objects
# [ Attack, Shield Break, Slowness, Damage Type]
#            |
#            v
# [ Health, Shield, Speed, Vulnerability ]

## Hurtbox should report what damage type has collided with it to parent
## in order to execute special functions, such as explosives

# Stats:
# Player/Monster/Ability/Obstacle: attack
# Damage Type
# 

var attack_effects: AttackStats
var hitbox_lifetime: float
var shape: Shape2D

func _init(_attack_effects: AttackStats, _hitbox_lifetime: float, _shape: Shape2D) -> void:
	attack_effects = _attack_effects
	hitbox_lifetime = _hitbox_lifetime
	shape = _shape
	
func _ready()-> void:
	monitorable = false	
	area_entered.connect(_on_area_entered)
	
	if hitbox_lifetime > 0.0:
		var timer = Timer.new()
		timer.timeout.connect(queue_free)
		timer.call_deferred("start", hitbox_lifetime)
	
	if shape:
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = shape
		add_child(collision_shape)

func _on_area_entered(target: Area2D) -> void:
	if not target.has_method("receive_hit"):
		return
	
	target.receive_hit(AttackStats)
	
	
