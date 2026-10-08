class_name Hitbox extends Area2D
## Detects target Hurtbox. Inflicts stat changes determined by its AttackStats object on overlap.
##
## Hitbox is a 2D region that triggers stat changes on overlap with **Hurtbox**.
## Useful for enemies, abilities, and obstacles that inflict slowness, damage, etc. to anything
## with a Hurtbox.
## Target layer(s) and stats are determined by the AttackStats passed into _attack_effects
##

var attack_effects: AttackStats ## Determines target Hurtbox layers and stat changes
var hitbox_lifetime: float ## Seconds until hitbox is freed. Hitbox is permanent if = 0.0
var shape: Shape2D ## Shape of the Hitbox
var hit_log: HitLog ## (Optional) Hitlog. Prevents Hitbox from repeat interactions with Hurtbox.

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
		add_child(timer)
		timer.timeout.connect(queue_free)
		timer.call_deferred("start", hitbox_lifetime)
	
	if shape:
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = shape
		add_child(collision_shape)
	
	# Disable default collision layers and masks
	set_collision_mask_value(1, false)
	set_collision_layer_value(1, false)
	
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
	target.receive_hit(attack_effects)
	
	
