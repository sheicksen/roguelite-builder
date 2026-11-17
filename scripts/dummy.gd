extends Node

var hurtbox: Hurtbox
var entity_stats: EntityStats = EntityStats.new(
	"Dummy",
	BaseStats.Faction.ENEMY,
	100,
	10
)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var shape = CircleShape2D.new()
	shape.radius = 33.0
	hurtbox = Hurtbox.new(entity_stats, 0.0, shape)
	add_child(hurtbox)
	
	
