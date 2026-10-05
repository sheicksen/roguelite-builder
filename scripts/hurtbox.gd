class_name Hurtbox extends Area2D

var stats: EntityStats
var hurtbox_lifetime: float
var shape: Shape2D

func _init(_stats:EntityStats, _lifetime: float, _shape: Shape2D) -> void:
	stats = _stats
	hurtbox_lifetime = _lifetime
	shape = _shape

func _ready() -> void:
	if hurtbox_lifetime > 0.0:
		var timer = Timer.new()
		timer.timeout.connect(queue_free)
		timer.call_deferred("start", hurtbox_lifetime)
	
	if shape:
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = shape
		add_child(collision_shape)
	
func recieve_hit(attack:AttackStats) -> void:
	stats.take_damage(attack.damage)
		
