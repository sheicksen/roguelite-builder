class_name DestroyableBox extends StaticBody2D
## A solid box that blocks movement and breaks after taking enough damage.

@export var max_health: int = 3
@export var box_size: Vector2 = Vector2(16, 16)

var stats: EntityStats
var hurtbox: Hurtbox

func _ready() -> void:
	# Solid collision so the player can't walk through the box
	var body_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = box_size
	body_shape.shape = rect
	add_child(body_shape)

	# ENVIRONMENT faction puts the Hurtbox on collision layer 3
	stats = EntityStats.new("Box", BaseStats.Faction.ENVIRONMENT, max_health, 0)

	# Lifetime 0.0 = permanent, emit_signal = true so we hear about damage
	hurtbox = Hurtbox.new(stats, 0.0, rect, false, true)
	hurtbox.health_changed.connect(_on_health_changed)
	add_child(hurtbox)

func _on_health_changed(_old_val: int, new_val: int) -> void:
	if new_val <= 0:
		destroy()

## Override in child classes for break animations, item drops, etc.
func destroy() -> void:
	queue_free()
