class_name Hurtbox extends Area2D
## Handles stat changes to EntityStats upon recieving an AttackStats object.
##
## Hurtbox is an Area2D that contains an EntityStats object. When passed an
## AttackStats object, it handles calling the necessary EntityStats methods to
## inflict specific damage types and stat changes.
##

signal health_changed(old_val, new_val)

var stats: EntityStats
var hurtbox_lifetime: float
var shape: Shape2D
var destroy_on_death: bool
var emit_signal: bool

func _init(_stats:EntityStats, _lifetime: float, _shape: Shape2D, _destroy_on_death: bool = false, _emit_signal: bool = false) -> void:
	stats = _stats
	hurtbox_lifetime = _lifetime
	shape = _shape
	destroy_on_death = _destroy_on_death
	emit_signal = _emit_signal
	

func _ready() -> void:
	if hurtbox_lifetime > 0.0:
		var timer = Timer.new()
		add_child(timer)
		timer.timeout.connect(queue_free)
		timer.call_deferred("start", hurtbox_lifetime)
	
	if shape:
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = shape
		add_child(collision_shape)
	#Disable default collision layers and masks
	set_collision_mask_value(1, false)
	set_collision_layer_value(1, false)
	match stats.faction:
		BaseStats.Faction.PLAYER:
			set_collision_layer_value(1, true)
		BaseStats.Faction.ENEMY:
			set_collision_layer_value(2, true)
		BaseStats.Faction.ENVIRONMENT:
			set_collision_layer_value(3, true)
	
func receive_hit(attack:AttackStats) -> void:
	var old_health = stats.health
	stats.take_damage(attack.damage)
	if emit_signal:
		health_changed.emit(old_health, stats.health)
		
	if stats.health <= 0 and destroy_on_death:
		queue_free()


		
