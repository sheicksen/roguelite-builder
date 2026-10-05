extends Area2D

var obstacle_dmg: AttackStats = AttackStats.new(50, 0, [1, 2])
var obstacle_stats: EntityStats = EntityStats.new("Object", 3, 20, 0)

@onready var shape:Shape2D = $CollisionShape2D.shape
var object_hurtbox: Hurtbox
var hitbox: Hitbox

func _ready() -> void:
	hitbox = Hitbox.new(obstacle_dmg, 0.0, shape)
	object_hurtbox = Hurtbox.new(obstacle_stats, 0.0, shape)

	add_child(object_hurtbox)
	add_child(hitbox)
