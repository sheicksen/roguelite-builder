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
var hit_log: HitLog

func _init(_attack_effects: AttackStats, _hitbox_lifetime: float, _shape: Shape2D, _hit_log:HitLog = null) -> void:
	attack_effects = _attack_effects
	hitbox_lifetime = _hitbox_lifetime
	shape = _shape
	hit_log = _hit_log
	
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
	
	## Set numerous affected collision layers
	for i in attack_effects.targets:
			set_collision_mask_value(i, true)

func _on_area_entered(target: Area2D) -> void:
	if not target.has_method("receive_hit"):
		return
	
	var hurtbox_owner = target.owner
	if hit_log:
		if hit_log.has_hit(hurtbox_owner):
			return
	target.receive_hit(AttackStats)
	
	
