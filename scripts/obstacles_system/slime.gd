class_name Slime extends Area2D
## Sticky slime that slows the player while they stand in it.

@export_range(0.0, 1.0) var slow_fraction: float = 0.5
@export var size: Vector2 = Vector2(32, 16)

func _ready() -> void:
	var collision := CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	collision.shape.size = size
	add_child(collision)

	monitorable = false
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, true)  # layer 1 = player Hurtbox

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		area.stats.modify_speed(-_slow_amount(area))

func _on_area_exited(area: Area2D) -> void:
	if area is Hurtbox:
		area.stats.modify_speed(_slow_amount(area))

func _slow_amount(area: Hurtbox) -> int:
	return int(area.stats.normal_speed * slow_fraction)
