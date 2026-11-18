class_name Ice extends Area2D
## Slippery ice that speeds the player up while they stand on it.

@export var speed_boost_fraction: float = 0.5  # 0.5 = 50% faster
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
		area.stats.modify_speed(_boost_amount(area))

func _on_area_exited(area: Area2D) -> void:
	if area is Hurtbox:
		area.stats.modify_speed(-_boost_amount(area))

func _boost_amount(area: Hurtbox) -> int:
	return int(area.stats.normal_speed * speed_boost_fraction)
